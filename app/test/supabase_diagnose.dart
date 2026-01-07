import 'dart:io';
import 'package:supabase/supabase.dart';

// Manual .env parser
Map<String, String> loadEnv() {
  final file = File('.env');
  if (!file.existsSync()) return {};
  final lines = file.readAsLinesSync();
  final map = <String, String>{};
  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final parts = line.split('=');
    if (parts.length >= 2) {
      final key = parts[0].trim();
      final value = parts.sublist(1).join('=').trim();
      map[key] = value;
    }
  }
  return map;
}

Future<void> main() async {
  print('--- Supabase Diagnostic Tool (Full Read/Write) ---');

  // 1. Load Env
  final env = loadEnv();
  final url = env['SUPABASE_URL'];
  final key = env['SUPABASE_ANON_KEY'];
  
  if (url == null || key == null) {
    print('❌ FAILED: Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env');
    exit(1);
  }
  
  final client = SupabaseClient(url, key);

  try {
    // 2. Auth (Anonymous)
    print('\n[1] Attempting Auth...');
    final authRes = await client.auth.signInAnonymously();
    final user = authRes.user;
    
    if (user == null) {
       print('❌ Auth FAILED.');
       exit(1);
    }
    print('✅ Auth Successful: ${user.id}');

    // 3. Profile Insert
    print('\n[2] Testing Profile Insert...');
    try {
      await client.from('profiles').upsert({
        'id': user.id,
        'nickname': 'DiagnoseBot',
        'age': 99,
        'gender': 'M',
        'role': 'user',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id'); // Ensure update if exists
      print('✅ Profile Insert/Update Successful');
    } catch (e) {
      print('❌ Profile Insert FAILED: $e');
      // If profile fails, game session will definitely fail
    }

    // 4. Game Session Insert
    print('\n[3] Testing Game Session Insert...');
    try {
      final session = await client.from('game_sessions').insert({
          'mp_id': user.id,
          'status': 'waiting',
          'invite_code': 'DIAG${DateTime.now().millisecondsSinceEpoch % 1000}', // Unique code
      }).select().single();
      print('✅ Game Session Create Successful: ${session['id']}');
      
      // Cleanup
      await client.from('game_sessions').delete().eq('id', session['id']);
      print('✅ Cleanup Successful (Session Deleted)');
      
    } catch (e) {
      print('❌ Game Session Create FAILED: $e');
    }
    
    print('\n--- Diagnostic Complete ---');

  } catch (e) {
    print('❌ EXCEPTION: $e');
  }
}
