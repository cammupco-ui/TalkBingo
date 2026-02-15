import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talkbingo_app/utils/localization.dart';

/// Maps Supabase auth errors to user-friendly localized messages.
/// Returns a Korean/English message based on the current language setting.
String getAuthErrorMessage(Object error) {
  if (error is AuthException) {
    final msg = error.message.toLowerCase();

    // Invalid credentials (wrong email or password)
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials') ||
        msg.contains('wrong password') ||
        msg.contains('invalid password')) {
      return AppLocalizations.get('auth_error_invalid_credentials');
    }

    // Email not confirmed
    if (msg.contains('email not confirmed') ||
        msg.contains('email_not_confirmed')) {
      return AppLocalizations.get('auth_error_email_not_confirmed');
    }

    // User not found
    if (msg.contains('user not found') ||
        msg.contains('no user found')) {
      return AppLocalizations.get('auth_error_user_not_found');
    }

    // Too many requests / rate limit
    if (msg.contains('rate limit') ||
        msg.contains('too many requests') ||
        msg.contains('over_request_rate_limit')) {
      return AppLocalizations.get('auth_error_too_many_requests');
    }

    // Email already registered
    if (msg.contains('user already registered') ||
        msg.contains('unique constraint') ||
        msg.contains('already registered')) {
      return AppLocalizations.get('auth_error_already_registered');
    }

    // Weak password
    if (msg.contains('weak password') ||
        msg.contains('password should be')) {
      return AppLocalizations.get('auth_error_weak_password');
    }

    // Invalid email format
    if (msg.contains('invalid email') ||
        msg.contains('unable to validate email')) {
      return AppLocalizations.get('auth_error_invalid_email');
    }

    // Network / connection error
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('failed to decode')) {
      return AppLocalizations.get('auth_error_network');
    }

    // Fallback: return the original message if we can't map it
    return error.message;
  }

  // Non-AuthException errors (e.g. "No host specified in URI")
  final str = error.toString().toLowerCase();
  if (str.contains('no host specified') ||
      str.contains('invalid argument') ||
      str.contains('socketexception') ||
      str.contains('handshakeexception')) {
    return AppLocalizations.get('auth_error_network');
  }

  return AppLocalizations.get('auth_error_generic');
}
