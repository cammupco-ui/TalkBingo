import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Simple CSV Parser handling quotes
List<List<String>> parseCsv(String content) {
  final List<List<String>> rows = [];
  final regex = RegExp(r'(?:^|,)(?:"([^"]*)"|([^",]*))');
  
  // Split by line, handling CRLF
  final lines = const LineSplitter().convert(content);
  
  for (var line in lines) {
    if (line.trim().isEmpty) continue;
    
    final List<String> row = [];
    final matches = regex.allMatches(line);
    
    for (var match in matches) {
      if (match.group(1) != null) {
        // Quoted value
        row.add(match.group(1)!.replaceAll('""', '"'));
      } else {
        // Unquoted value
        row.add(match.group(2)!.trim());
      }
    }
    // Remove the first empty match if regex matches start of string with nothing
    // Actually standard regex complexity. Let's use a simpler character walker for safety.
    rows.add(parseCsvLine(line));
  }
  return rows;
}

List<String> parseCsvLine(String line) {
  List<String> row = [];
  StringBuffer current = StringBuffer();
  bool inQuote = false;
  
  for (int i = 0; i < line.length; i++) {
    String char = line[i];
    
    if (inQuote) {
      if (char == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++; // Skip next quote
        } else {
          inQuote = false;
        }
      } else {
        current.write(char);
      }
    } else {
      if (char == '"') {
        inQuote = true;
      } else if (char == ',') {
        row.add(current.toString().trim());
        current.clear();
      } else {
        current.write(char);
      }
    }
  }
  row.add(current.toString().trim());
  return row;
}

void main() {
  test('Seed Questions to Supabase', () async {
    // 1. Load Env
    final envFile = File('/Users/anmijung/Desktop/TalkBingo/app/.env');
    if (!envFile.existsSync()) {
      print('❌ .env file not found at ${envFile.path}');
      return;
    }
    
    // Manual parsing of .env to avoid flutter_dotenv needing flutter binding or asset loading issues in test
    final envLines = envFile.readAsLinesSync();
    final env = <String, String>{};
    for (var line in envLines) {
      final parts = line.split('=');
      if (parts.length >= 2) {
        env[parts[0].trim()] = parts.sublist(1).join('=').trim();
      }
    }

    final url = env['SUPABASE_URL'] ?? '';
    final key = env['SUPABASE_ANON_KEY'] ?? '';
    
    if (url.isEmpty || key.isEmpty) {
      print('❌ Supabase credentials missing');
      return;
    }

    // 2. Initialize Client
    final supabase = SupabaseClient(url, key);
    print('✅ Connected to Supabase: $url');

    // 3. Process Balance Data
    await processFile(supabase, '/Users/anmijung/Desktop/TalkBingo/doc/Restored_BalanceQuizData.csv', 'balance');
    
    // 4. Process Truth Data
    await processFile(supabase, '/Users/anmijung/Desktop/TalkBingo/doc/Restored_TruthQuizData.csv', 'truth');

  });
}

Future<void> processFile(SupabaseClient supabase, String path, String defaultType) async {
  print('📂 Processing $path ...');
  final file = File(path);
  if (!file.existsSync()) {
    print('❌ File not found: $path');
    return;
  }

  final content = file.readAsStringSync();
  final rows = parseCsv(content);
  
  if (rows.isEmpty) {
     print('⚠️ Empty CSV');
     return;
  }

  print('   Found ${rows.length} rows (including header)');
  
  // Header: CodeName,Order,q_id,content,choice_a,choice_b (Balance)
  // Header: CodeName,Order,q_id,content,answers (Truth)
  // Header might vary, let's map by index or verify header.
  
  // Assuming standard order based on visual inspection:
  // Col 0: CodeName
  // Col 2: q_id
  // Col 3: content
  // Col 4: choice_a / answers
  // Col 5: choice_b (only Balance)

  final Map<String, Map<String, dynamic>> upsertBuffer = {};

  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];
    if (row.length < 4) continue;

    // Handle multiple codes split by comma
    final codeNameRaw = row[0]; // e.g. "F-F-B-Ar-L1,F-F-B-Ar-L2"
    final List<String> codes = codeNameRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final qId = row[2]; // e.g. B25-00001
    final contentText = row[3];
    
    // Parse QID to verify type
    String type = defaultType;
    if (qId.startsWith('T')) type = 'truth';
    else if (qId.startsWith('B')) type = 'balance';

    if (!upsertBuffer.containsKey(qId)) {
      // Create new entry
      Map<String, dynamic> details = {
        'game_code': codes.isNotEmpty ? codes.first : '', // Primary code
      };
      
      if (type == 'balance') {
        if (row.length >= 6) {
           details['choice_a'] = row[4];
           details['choice_b'] = row[5];
        } else {
           // Maybe row length is short?
           details['choice_a'] = row.length > 4 ? row[4] : '';
           details['choice_b'] = '';
        }
      } else {
        // Truth
        details['answers'] = row.length > 4 ? row[4] : '';
      }

      upsertBuffer[qId] = {
        'q_id': qId,
        'content': contentText,
        'type': type,
        'code_names': codes.toSet(), // Initialize with all codes
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      };
    } else {
      // Append CodeNames
      (upsertBuffer[qId]!['code_names'] as Set<String>).addAll(codes);
    }
  }

  print('   Consolidated into ${upsertBuffer.length} unique questions.');

  // Convert to List for Upsert
  final records = upsertBuffer.values.map((e) {
    return {
      'q_id': e['q_id'],
      'content': e['content'],
      'type': e['type'],
      'code_names': (e['code_names'] as Set<String>).toList(),
      'details': e['details'], // Supabase handles Map -> Json
      // 'created_at' is optional if default, but we set it
    };
  }).toList();

  // Batch Upsert (Supabase limits? 1000?)
  const batchSize = 100;
  for (var i = 0; i < records.length; i += batchSize) {
    final batch = records.skip(i).take(batchSize).toList();
    try {
      await supabase.from('questions').upsert(batch, onConflict: 'q_id');
      print('   Upserted batch ${(i ~/ batchSize) + 1} / ${(records.length / batchSize).ceil()}');
    } catch (e) {
      print('❌ Error upserting batch: $e');
    }
  }
}
