import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:talkbingo_app/models/game_session.dart';

class MigrationManager {
  static final MigrationManager _instance = MigrationManager._internal();
  factory MigrationManager() => _instance;
  MigrationManager._internal();

  static const String _keyOldId = 'migration_old_id';
  static const String _keyGuestNickname = 'migration_guest_nickname';

  /// Call this BEFORE the user taps "Sign Up" or "Log In" (when they are currently Anonymous).
  /// It saves their current Anonymous ID to track it after the auth state change.
  Future<void> prepareForMigration() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.isAnonymous) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyOldId, user.id);
      
      // Also save their current guest nickname if available
      // (This assumes GameSession has the latest guest data loaded)
      final session = GameSession();
      if (session.guestNickname != null && session.guestNickname!.isNotEmpty) {
        await prefs.setString(_keyGuestNickname, session.guestNickname!);
      }
      
      debugPrint('MigrationManager: Prepared for migration. Old ID: ${user.id}, Nickname: ${session.guestNickname}');
    }
  }

  /// Call this AFTER the user successfully logs in (e.g. on Splash Screen or Home Init).
  /// It checks if there is a pending migration and executes it.
  Future<void> attemptMigration() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) return; // Not signed in as a real user yet

    final prefs = await SharedPreferences.getInstance();
    final oldId = prefs.getString(_keyOldId);

    if (oldId != null && oldId.isNotEmpty && oldId != user.id) {
      debugPrint('MigrationManager: Detected pending migration. Old: $oldId -> New: ${user.id}');
      
      try {
        // 1. DB Migration (RPC)
        await Supabase.instance.client.rpc('migrate_user_history', params: {
          'old_id': oldId,
          'new_id': user.id,
        });
        debugPrint('MigrationManager: DB History Migrated successfully.');

        // 2. Profile Migration (Nickname)
        // If the new account has no nickname, use the old guest nickname
        final savedGuestNickname = prefs.getString(_keyGuestNickname);
        final session = GameSession();
        
        // Ensure session data is loaded
        await session.loadHostInfoFromPrefs(); // Or fetch from DB? DB is better for fresh login.
        
        // Actually, for a fresh login, we should probably fetch the profile from DB first.
        // But let's assume GameSession loads it eventually. 
        // For now, let's blindly upsert if local is set.
        
        // TODO: ideally check if DB profile exists. But simplified logic:
        // If we have a saved guest nickname, and we want to preserve it:
        if (savedGuestNickname != null && savedGuestNickname.isNotEmpty) {
           // We only set it if the user doesn't have one? 
           // Or maybe we force it if it's a new account?
           // Strategy: If GameSession.hostNickname is empty, use it.
           if (session.hostNickname == null || session.hostNickname!.isEmpty) {
              session.hostNickname = savedGuestNickname;
              await session.saveHostInfoToPrefs(); // Save locally
              // Also update profile in DB if you have a method for that
              // _updateProfileInDb(user.id, savedGuestNickname);
              debugPrint('MigrationManager: Migrated Nickname to Host Profile.');
           }
        }

        // 3. Cleanup
        await prefs.remove(_keyOldId);
        await prefs.remove(_keyGuestNickname);
        debugPrint('MigrationManager: Migration Complete. Cleanup done.');

      } catch (e) {
        debugPrint('MigrationManager: Error during migration: $e');
        // Do not clear prefs so we can retry next time? 
        // Or clear to avoid infinite error loop?
        // For now, keep it to retry.
      }
    }
  }
}
