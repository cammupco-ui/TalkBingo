import 'package:supabase/supabase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Still using this for loader? No, use manual parsing or just hardcode for test.
import 'dart:io';

// Simple .env parser since flutter_dotenv depends on flutter
Map<String, String> parseEnv(File file) {
  final lines = file.readAsLinesSync();
  final map = <String, String>{};
  for (var line in lines) {
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final parts = line.split('=');
    if (parts.length >= 2) {
      map[parts[0].trim()] = parts.sublist(1).join('=').trim();
    }
  }
  return map;
}

Future<void> main() async {
  // Load .env manually
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('Error: .env file not found');
    return;
  }
  
  final env = parseEnv(envFile);
  final url = env['SUPABASE_URL'];
  final key = env['SUPABASE_ANON_KEY'];

  if (url == null || key == null) {
    print('Error: SUPABASE_URL or SUPABASE_ANON_KEY missing in .env');
    return;
  }

  // Use pure Supabase client
  final client = SupabaseClient(url, key);
  final code = 'KQVD48';

  print('Checking Game Session for code: $code ...');

  try {
    final response = await client
        .from('game_sessions')
        .select()
        .eq('invite_code', code)
        .maybeSingle();

    if (response == null) {
      print('❌ Game Session NOT FOUND for code: $code');
    } else {
      print('✅ Game Session FOUND!');
      print('   ID: ${response['session_id']}');
      print('   Host ID: ${response['host_id']}');
      print('   Status: ${response['status']}');
      print('   Created At: ${response['created_at']}');
    }
  } catch (e) {
    print('Error querying Supabase: $e');
  }
}
