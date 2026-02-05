import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:app_links/app_links.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/utils/url_cleaner.dart';
import 'package:talkbingo_app/screens/invite_code_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkbingo_app/globals.dart'; // For navigatorKey

class DeepLinkService {
  // Singleton Pattern
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // Initialize and start listening
  Future<void> init() async {
    try {
      // 1. Check Initial Link (Cold Start)
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri, isColdStart: true);
      }

      // 2. Listen for Stream (Warm Start / Resumed)
      _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
        _handleDeepLink(uri, isColdStart: false);
      });
      
      debugPrint("🔗 DeepLinkService initialized.");
    } catch (e) {
      debugPrint("⚠️ DeepLinkService Init Error: $e");
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }

  // Unified Handling Logic
  void _handleDeepLink(Uri uri, {required bool isColdStart}) async {
    debugPrint("🔗 Processing URI (Cold: $isColdStart): $uri");

    // 1. Extract Code
    String? code = _extractCode(uri);

    if (code != null) {
       // Validate Format (6 Chars)
       final bool isValid = RegExp(r'^[A-Z0-9]{6}$', caseSensitive: false).hasMatch(code);

       if (isValid) {
          code = code!.toUpperCase();
          
          // Persistence
          GameSession().pendingInviteCode = code;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pending_invite_code', code);
          debugPrint("💾 DeepLink: Code $code persisted.");

          // If Warm Start, we must Navigate potentially
          if (!isColdStart) {
             _navigateToInvite(code);
          }
          
          // Clean URL if Web
          if (kIsWeb) {
             UrlCleaner.removeCodeParam();
          }
       } else {
         debugPrint("⚠️ DeepLink: Invalid Code format ignored: $code");
       }
    }
  }

  String? _extractCode(Uri uri) {
     String? code = uri.queryParameters['code']?.trim();
     
     // Robust Fallback for Hash Routing (e.g. /#/?code=...)
     // This logic is critical for Web Apps with HashStrategy
     if (code == null) {
        final frag = uri.fragment;
        final fullStr = uri.toString();
        
        // Try Fragment Regex
        var match = RegExp(r'[?&]code=([A-Za-z0-9]+)').firstMatch(frag);
        if (match != null) return match.group(1);
        
        // Try Full String Regex (Last Resort)
        match = RegExp(r'[?&]code=([A-Za-z0-9]+)').firstMatch(fullStr);
        if (match != null) return match.group(1);
     }
     
     return code;
  }

  void _navigateToInvite(String code) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint("⚠️ Navigator Context is null. Cannot navigate.");
      return;
    }

    // Check if we are already on Invite Code Screen or redundant?
    // We'll simplisticly push a Dialog/Alert or Screen.
    // Let's show a SnackBar or Dialog first to be polite? 
    // Or just go straight to InviteCodeScreen as requested ("Invite link clicked -> Go to Join")
    
    // We use a small delay to ensure UI is ready if needed
    Future.delayed(const Duration(milliseconds: 100), () {
        Navigator.of(context).push(
           MaterialPageRoute(builder: (_) => InviteCodeScreen(initialCode: code)),
        );
    });
  }
}
