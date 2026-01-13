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
import 'package:talkbingo_app/utils/migration_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;
  String? _initialInviteCode;
  StreamSubscription<AuthState>? _authSubscription;
  
  // Single Random Text State
  late int _randomIndex;

  final List<String> _koreanTexts = [
    "스스로를 사랑하세요",
    "여기서는 너 그대로면 충분해",
    "지금의 너로 시작하면 돼",
    "정답은 없어 네 이야기면 돼",
    "천천히 가도 방향은 맞아",
    // "잘하려 하지 않아도 괜찮아", // Typo fix or keep as is? User provided list has it.
    "잘하려 하지 않아도 괜찮아",
    "이 순간은 너를 위한 시간이야",
    "비교하지 않아도 빛나",
    "솔직해질 준비만 있으면 돼",
    "너의 속도를 존중해",
    "시작하기에 이미 충분해",
  ];

  final List<String> _englishTexts = [
    "Love yourself",
    "You are enough just as you are here",
    "You can start as you are now",
    "There is no right answer, your story is enough",
    "Even if slow, the direction is right",
    "It's okay not to be perfect",
    "This moment is for you",
    "You shine without comparing",
    "Just be ready to be honest",
    "Respect your own pace",
    "You are already enough to start",
  ];

  @override
  void initState() {
    super.initState();
    // 1. Capture URL state IMMEDIATELY
    final uri = Uri.base;
    _initialInviteCode = uri.queryParameters['code']?.trim();
    debugPrint("SplashScreen: InitState captured code: $_initialInviteCode");

    // Select random index once
    _randomIndex = DateTime.now().millisecondsSinceEpoch % _koreanTexts.length;

    _setupAuthListener();
    
    // Explicitly check session immediately to prevent waiting if already logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _checkExistingSession();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkExistingSession() async {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
          debugPrint("SplashScreen: Immediate Session Found. Navigating.");
          await _handleAuthenticatedUser(session);
      }
  }

  void _setupAuthListener() {
    // 1. Listen to Auth State Changes
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      
      final session = data.session;
      final event = data.event;
      debugPrint("SplashScreen: Auth Event: $event, Session: ${session != null}");

      // Use _initialInviteCode if present, or check current URI
      final uri = Uri.base; 
      final currentCode = uri.queryParameters['code']?.trim();
      final effectiveCode = _initialInviteCode ?? currentCode;

      // Handle Invite Code (Deep Link / URL Param)
      if (effectiveCode != null && effectiveCode.length == 6) {
           debugPrint("SplashScreen: Listener - Invite Code Found: $effectiveCode");
           GameSession().pendingInviteCode = effectiveCode;
           Navigator.of(context).pushReplacement(
             MaterialPageRoute(builder: (_) => InviteCodeScreen(initialCode: effectiveCode)),
           );
           return;
      }

      // Handle Auth Session
      if (session != null) {
           debugPrint("SplashScreen: Listener - Session Found. Handling User.");
           _handleAuthenticatedUser(session);
      }
    });

    // 2. Initial Checks (Timeouts)
    // Extended timeout to 4.0s for Mobile Web latency
    Future.delayed(const Duration(milliseconds: 4000), () async {
      if (!mounted) return;
      
      final session = Supabase.instance.client.auth.currentSession;
      String? inviteCode = _initialInviteCode; 
      
      bool isAuthCode = inviteCode != null && inviteCode.length > 6;
      bool isInviteCode = inviteCode != null && inviteCode.length == 6;

      if (isInviteCode) {
         debugPrint("SplashScreen: Timeout Force-Navigating to InviteCodeScreen with $inviteCode");
         GameSession().pendingInviteCode = inviteCode;
         Navigator.of(context).pushReplacement(
           MaterialPageRoute(builder: (_) => InviteCodeScreen(initialCode: inviteCode)),
         );
         return;
      }

      if (session == null && !isAuthCode) {
         debugPrint("SplashScreen: No Session. Attempting Anonymous Sign-In...");
         try {
             await Supabase.instance.client.auth.signInAnonymously();
             // The auth listener will catch the new session and navigate.
         } catch (e) {
             debugPrint("SplashScreen: Anonymous Auth Failed: $e");
             // Fallback to Signup if anonymous auth fails (critical error)
             if (mounted) {
                 Navigator.of(context).pushReplacement(
                   MaterialPageRoute(builder: (_) => const SignupScreen()),
                 );
             }
         }
      } else if (isAuthCode) {
         debugPrint("SplashScreen: Detected Auth Code ($inviteCode). Waiting for session exchange...");
      }
    });

    // Check 2: Safety Net (10s)
    Future.delayed(const Duration(seconds: 10), () {
        if (!mounted) return;
        // If we are STILL here, something went wrong with Auth Exchange
        debugPrint("SplashScreen: Safety Timeout (10s). Forcing unexpected state resolution.");
        
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
            Navigator.of(context).pushReplacement(
               MaterialPageRoute(builder: (_) => const SignupScreen()),
            );
        }
    });
  }

  Future<void> _handleAuthenticatedUser(Session session) async {
    // 1. Attempt Migration (Guest -> Host) if pending
    await MigrationManager().attemptMigration();

    if (!mounted) return;

    // 2. Load Host Info to check if profile exists
    final gameSession = GameSession();
    await gameSession.loadHostInfoFromPrefs();
      
      if (gameSession.hostNickname == null) {
         // Profile missing? Go to HostInfo to set it up.
         Navigator.of(context).pushReplacement(
           MaterialPageRoute(builder: (_) => HostInfoScreen()), 
         );
      } else {
         gameSession.myRole = 'A';
         Navigator.of(context).pushReplacementNamed('/home');
      }
  }

  @override
  Widget build(BuildContext context) {
    // Detect Language
    final Locale appLocale = Localizations.localeOf(context);
    final bool isKorean = appLocale.languageCode == 'ko';
    final List<String> texts = isKorean ? _koreanTexts : _englishTexts;
    
    // Show Single Random Text
    final String displayText = texts[_randomIndex % texts.length];

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
            if (_progress > 0)
              Text(
                '${(_progress * 100).toInt()}%',
                style: const TextStyle(
                  color: AppColors.hostPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
             const SizedBox(height: 20),
            
            // Static Random Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                displayText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54, 
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  fontFamily: 'NanumSquareRound', // Optional: Use a nice font if available, else default
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
