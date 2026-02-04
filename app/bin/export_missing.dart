import 'dart:io';
import 'dart:convert';
import 'package:supabase/supabase.dart';

void main() async {
  print('Starting export of questions with missing English data...');

  // 1. Read .env manually
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('Error: .env file not found in ${Directory.current.path}');
    exit(1);
  }

  String? url;
  String? key;
  
  final lines = await envFile.readAsLines();
  for (var line in lines) {
    // Basic parser, handles simple KEY=VALUE
    if (line.trim().isEmpty || line.trim().startsWith('#')) continue;
    
    final parts = line.split('=');
    if (parts.length < 2) continue;
    
    final k = parts[0].trim();
    final v = parts.sublist(1).join('=').trim();
    
    if (k == 'SUPABASE_URL') url = v;
    if (k == 'SUPABASE_ANON_KEY') key = v;
  }

  if (url == null || key == null) {
    print('Error: Could not find SUPABASE_URL or SUPABASE_ANON_KEY in .env');
    exit(1);
  }

  print('Connecting to Supabase at $url...');

  // 2. Init Client
  final client = SupabaseClient(url, key);

  try {
    // 3. Fetch All Data
    // Note: If dataset > 1000, paging might be needed. 
    // Supabase default limit is 1000. We'll try to fetch up to 10000 just in case.
    
    // In Supabase Dart v2, .select() returns a List<Map<String, dynamic>> directly.
    final List<dynamic> data = await client
        .from('questions')
        .select()
        .range(0, 9999); // Fetch large batch

    print('Fetched ${data.length} total questions.');

    // 4. Filter for Missing English
    final missingEnList = data.where((q) {
      final contentEn = q['content_en'] as String?;
      final detailsEn = q['details_en'];
      
      bool missingContent = contentEn == null || contentEn.trim().isEmpty;
      bool missingDetails = detailsEn == null; 
      
      // Details_en might be an empty map? If it's {}, we might consider it present if not null.
      // But user said "missing data".
      // Let's assume explicit NULL or empty text is what matters.
      
      return missingContent || missingDetails; 
    }).toList();

    print('Identified ${missingEnList.length} questions missing English info.');

    if (missingEnList.isEmpty) {
      print('No missing data found. Exiting.');
      return;
    }

    // 5. Generate CSV
    final buffer = StringBuffer();
    // Header
    buffer.writeln('id,content,details');
    
    for (var q in missingEnList) {
        final id = q['id'];
        final content = _escapeCsv(q['content'] ?? '');
        final details = _escapeCsv(jsonEncode(q['details']));
        
        buffer.writeln('$id,$content,$details');
    }
    
    // 6. Write File
    final outFile = File('missing_english_questions.csv');
    await outFile.writeAsString(buffer.toString());
    print('✅ Export successful: ${outFile.absolute.path}');

  } catch (e) {
    print('Error during export: $e');
    exit(1);
  } finally {
     // Close client if needed? SupabaseClient cleanup is usually automatic/stateless REST.
     client.dispose();
  }
}

String _escapeCsv(String field) {
  // If field contains comma, quote, or newline, wrap in quotes and escape internal quotes
  if (field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r')) {
    return '"${field.replaceAll('"', '""')}"';
  }
  return field;
}
