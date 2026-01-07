import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

class MockLocalStorage extends LocalStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => _storage.containsKey('supabase.auth.token');

  @override
  Future<String?> accessToken() async => _storage['supabase.auth.token'];

  @override
  Future<void> persistSession(String persistSessionString) async {
    _storage['supabase.auth.token'] = persistSessionString;
  }

  @override
  Future<void> removePersistedSession() async {
    _storage.remove('supabase.auth.token');
  }
}

Future<void> main() async {
  // Load .env
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('Error: .env file not found');
    return;
  }
  await dotenv.load(fileName: ".env");

  // Initialize Supabase Client directly (Pure Dart)
  final client = SupabaseClient(
    dotenv.env['SUPABASE_URL']!,
    dotenv.env['SUPABASE_ANON_KEY']!,
  );

  print('Checking Question Data in Supabase...');

  try {
    // Verify specific TRUTH question to check Type and Structure
    final initialCandidates = ['당신에게 하루의 피로를 싹 날려버리는 킥이 있다면']; 
    
    print('Searching for KNOWN TRUTH question: ${initialCandidates[0]}');
    
    final response = await client
        .from('questions')
        .select()
        .like('content', '%${initialCandidates[0]}%')
        .limit(5);

    if (response.isEmpty) {
      print('❌ Truth Question NOT found!');
    } else {
      print('✅ Truth Question Found!');
      for(var q in response) {
         print('Content: ${q['content']}');
         print('RAW Type: ${q['type']}'); 
         print('RAW Details: ${q['details']}');
         // Check if 'q_id' exists in details or top level?
         // Usually it's in details based on CSV mapping or just not there
      }
    }

    if (response.isEmpty) {
      print('❌ Universal Fallback Failed (No questions found)');
    } else {
      print('✅ Universal Fallback SUCCESS!');
      print('Found ${response.length} questions.');
      for(var q in response) {
         print('- [${q['content']}] Codes: ${q['code_names']}');
      }
    }

  } catch (e) {
    print('Error querying Supabase: $e');
  }
}
