import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling social authentication (Google, Kakao).
/// Only used on mobile platforms; web continues to use email login.
class SocialAuthService {
  // ─── Google OAuth Client IDs ───────────────────────────────────
  // TODO: Replace with your own Google Cloud Console OAuth Client IDs
  // Web Client ID (also used as serverClientId on Android)
  static const _webClientId = '755086635011-ue1shvih0kji9r3sncuvtg4l9jjejkdq.apps.googleusercontent.com';
  // iOS Client ID
  static const _iosClientId = '755086635011-kdku3m74uppikudm0u2ss1jjvlbp5if9.apps.googleusercontent.com';

  /// Signs in with Google using native ID-token flow.
  /// Returns the Supabase [AuthResponse] on success.
  /// Throws [AuthException] on failure.
  static Future<AuthResponse> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: _iosClientId,
      serverClientId: _webClientId,
      scopes: ['email', 'profile'],
    );

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('Google sign-in cancelled by user.');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final String? idToken = googleAuth.idToken;
    final String? accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw const AuthException('No ID Token found from Google.');
    }

    return await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  /// Signs in with Kakao using OAuth browser redirect flow.
  /// Returns true if the sign-in was initiated successfully.
  static Future<bool> signInWithKakao() async {
    try {
      final success = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: 'io.supabase.talkbingo://login-callback/',
      );
      return success;
    } catch (e) {
      debugPrint('Kakao sign-in error: $e');
      return false;
    }
  }
}
