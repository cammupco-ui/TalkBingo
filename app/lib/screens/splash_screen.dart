import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talkbingo_app/screens/signup_screen.dart';
import 'package:talkbingo_app/screens/invite_code_screen.dart';
import 'package:talkbingo_app/screens/host_info_screen.dart';
import 'package:talkbingo_app/styles/app_colors.dart';

import 'package:talkbingo_app/models/game_session.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    print('SplashScreen: initState'); // Debug
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      print('SplashScreen: _checkSession started');
      
      // Simulate loading progress
      for (var i = 0; i <= 100; i += 20) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (mounted) {
          setState(() {
            _progress = i / 100;
          });
        }
      }

      if (!mounted) return;

      // Robust URL Parsing
      final uri = Uri.base;
      print('SplashScreen: Uri.base = $uri');
      
      String? inviteCode = uri.queryParameters['code'];
      
      // Fallback 1: Fragment
      if (inviteCode == null && uri.hasFragment && uri.fragment.contains('code=')) {
         final fragmentUri = Uri.parse(uri.fragment.replaceFirst('#', '?'));
         if (fragmentUri.queryParameters.containsKey('code')) {
           inviteCode = fragmentUri.queryParameters['code'];
         }
      }
      
      // Fallback 2: Raw String Parsing (for root query params before hash)
      if (inviteCode == null) {
        final urlString = uri.toString();
        if (urlString.contains('?code=')) {
           final parts = urlString.split('?code=');
           if (parts.length > 1) {
             final potentialCode = parts[1].split('&').first.split('#').first;
             if (potentialCode.length == 6) {
               inviteCode = potentialCode;
               print('SplashScreen: Found code via raw string parsing: $inviteCode');
             }
           }
        }
      }

      print('SplashScreen: Final Detected Code = $inviteCode');

      // 0. Detect Auth Callback (Magic Link)
      bool isAuthCallback = uri.queryParameters.containsKey('code') || 
                            uri.fragment.contains('access_token') ||
                            uri.fragment.contains('type=recovery');

      if (isAuthCallback) {
        print('SplashScreen: Auth Callback Detected. Waiting for Session...');
        if (mounted) setState(() => _progress = 0.8); // Visual Feedback
        
        // Wait for session with a timeout (e.g., 5 seconds)
        // logic: polling or stream listener
        final completer = Completer<Session?>();
        final subscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
           if (data.session != null) {
              if (!completer.isCompleted) completer.complete(data.session);
           }
        });

        // Try getting session immediately just in case
        final currentSession = Supabase.instance.client.auth.currentSession;
        if (currentSession != null && !completer.isCompleted) {
           completer.complete(currentSession);
        }

        // Wait
        final sessionOrNull = await completer.future.timeout(
           const Duration(seconds: 5),
           onTimeout: () => null,
        );
        
        subscription.cancel();

        if (sessionOrNull != null) {
           print('SplashScreen: Session Established via Callback.');
           // Proceed with this session
           _handleNavigation(sessionOrNull, inviteCode);
           return;
        } else {
           print('SplashScreen: Auth Callback Timeout or Failed.');
           // Fallthrough to normal check logic (which will likely go to Signup/Login)
        }
      }

      print('SplashScreen: Final Detected Code = $inviteCode');

      final session = Supabase.instance.client.auth.currentSession;
      _handleNavigation(session, inviteCode);

    } catch (e, stack) {
      print('SplashScreen Error: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleNavigation(Session? session, String? inviteCode) async {
      // 1-A. Validate Invite Code
       if (inviteCode != null && inviteCode.length != 6) {
        print('SplashScreen: Code "$inviteCode" looks like an Auth Code or invalid. Ignoring as Invite Code.');
        inviteCode = null; 
      }

      // [WEB-SPECIFIC] Force Guest Flow (SignupScreen) by default for Web Clients
      // unless it's a deep link with a specific invite code.
      if (kIsWeb && inviteCode == null && session == null) {
         print('SplashScreen: [Web] Force Fresh Start -> SignupScreen');
         // If a session existed from cache but we want to force guest flow? 
         // Actually, let's just proceed to Signup if inviteCode is null.
         // But wait, if they are logged in as Host on Web, do we want to kick them out?
         // User said: "Web initialization value always Guest Flow".
         // This implies we should ignore the cached session for Web unless explicit.
      }
      
      // If Web and we have a session but it might be a stale Host session...
      // The user specially asked for "Web case... always start with Guest Flow".
      // We will implement a check: If Web, and not a Redirect Callback, Force Logout/Guest Mode?
      // Or just navigate to SignupScreen even if Session exists?
      
      if (kIsWeb) {
         // Check if this is a "Zombie Session" or unwanted Host session
         if (session != null && inviteCode == null) {
            print('[Web Override] Clearing session to enforce Guest Flow default.');
            await Supabase.instance.client.auth.signOut();
            session = null;
         }
      }

      // 1. Host (Logged In) -> Home or Host Setup
      if (session != null && session.user.isAnonymous != true) {
         if (mounted) {
            print('SplashScreen: Authenticated Host.');
            
            // Check if Profile is set
            final gs = GameSession();
            await gs.loadHostInfoFromPrefs(); // Ensure loaded
            
            if (gs.hostNickname == null) {
               print('SplashScreen: Host Profile Missing. Going to HostInfoScreen.');
               Navigator.of(context).pushReplacement(
                 MaterialPageRoute(builder: (_) => HostInfoScreen()), 
               );
            } else {
               print('SplashScreen: Host Profile Found. Going to Home.');
               gs.myRole = 'A';
               Navigator.of(context).pushReplacementNamed('/home');
            }
         }
         return;
      }

      // 2. Guest with Code -> InviteCodeScreen OR Home if logged in
      if (inviteCode != null) {
          // Store locally
          GameSession().pendingInviteCode = inviteCode;
          print('SplashScreen: Stored Pending Code: $inviteCode');

          if (session != null && session.user.isAnonymous != true) {
             print('SplashScreen: Authenticated Member with Code. Going to Home.');
             if (mounted) {
               Navigator.of(context).pushReplacementNamed('/home');
             }
             return;
          }
        
        if (mounted) {
          print('SplashScreen: Guest with Code ($inviteCode). Going to InviteCodeScreen.');
          GameSession().myRole = 'B';
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => InviteCodeScreen(initialCode: inviteCode)),
          );
        }
        return;
      }
      
      // 3. Anonymous/Returning -> Signup or Home
      if (session != null) {
        if (session.user.isAnonymous == true) {
           print('SplashScreen: Anonymous User. Going to Signup.');
           if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SignupScreen()),
              );
           }
        } else {
           print('SplashScreen: Host Session Found. Going to Home.');
           if (mounted) {
            GameSession().myRole = 'A';
            Navigator.of(context).pushReplacementNamed('/home');
           }
        }
      } else {
        print('SplashScreen: No Session. Going to Signup.');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SignupScreen()),
          );
        }
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with Rotation Animation
            SvgPicture.asset(
              'assets/images/Logo Vector.svg',
              width: 72,
              height: 72,
            )
            .animate(onPlay: (controller) => controller.repeat())
            .rotate(duration: 1000.ms, curve: Curves.linear), 
            
            const SizedBox(height: 40),
            
            // Progress Bar
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey[200],
                color: AppColors.hostPrimary, // Host Primary Color
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${(_progress * 100).toInt()}%',
              style: const TextStyle(
                color: AppColors.hostPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
             const SizedBox(height: 20),
            // Debug Text to confirm Rendering
            const Text("Initializing...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
