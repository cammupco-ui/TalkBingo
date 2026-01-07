import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

Future<void> main() async {
  // Load .env
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('Error: .env file not found');
    return;
  }
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final client = Supabase.instance.client;
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
      print('Possible reasons:');
      print('1. RLS Policy blocking read?');
      print('2. Creation failed silently?');
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
