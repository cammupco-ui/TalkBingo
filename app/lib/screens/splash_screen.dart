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
  
  // Debug Logs
  final List<String> _logs = [];
  void _addLog(String msg) {
    if (!mounted) return;
    final log = "${DateTime.now().toString().substring(11, 19)} $msg";
    setState(() => _logs.insert(0, log));
    debugPrint("SPLASH_DEBUG: $msg");
  }

  // Single Random Text State
  late int _randomIndex;

  final List<String> _koreanTexts = [
    "스스로를 사랑하세요",
    "여기서는 너 그대로면 충분해",
    "지금의 너로 시작하면 돼",
    "정답은 없어 네 이야기면 돼",
    "천천히 가도 방향은 맞아",
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
    _addLog("InitState Started");
    
    // 1. Capture URL state IMMEDIATELY
    try {
      final uri = Uri.base;
      _initialInviteCode = uri.queryParameters['code']?.trim();
      _addLog("Captured URL Code: $_initialInviteCode");
    } catch (e) {
      _addLog("Error capturing URL: $e");
    }

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
      _addLog("Checking Existing Session...");
      try {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
            _addLog("Immediate Session Found: ${session.user.id.substring(0,5)}...");
            await _handleAuthenticatedUser(session);
        } else {
            _addLog("No Immediate Session");
        }
      } catch (e) {
        _addLog("Session Check Error: $e");
      }
  }

  void _setupAuthListener() {
    _addLog("Setting up Auth Listener");
    // 1. Listen to Auth State Changes
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      
      final session = data.session;
      final event = data.event;
      _addLog("Auth Event: $event");

      // Use _initialInviteCode if present, or check current URI
      final uri = Uri.base; 
      final currentCode = uri.queryParameters['code']?.trim();
      final effectiveCode = _initialInviteCode ?? currentCode;

      // Handle Invite Code (Deep Link / URL Param)
      if (effectiveCode != null && effectiveCode.length == 6) {
           _addLog("Invite Code Found: $effectiveCode -> Navigating");
           GameSession().pendingInviteCode = effectiveCode;
           Navigator.of(context).pushReplacement(
             MaterialPageRoute(builder: (_) => InviteCodeScreen(initialCode: effectiveCode)),
           );
           return;
      }

      // Handle Auth Session
      if (session != null) {
           _addLog("Session Found in Listener. Handling User.");
           _handleAuthenticatedUser(session);
      }
    });

    // 2. Initial Checks (Timeouts)
    // Extended timeout to 4.0s for Mobile Web latency
    Future.delayed(const Duration(milliseconds: 4000), () async {
      if (!mounted) return;
      _addLog("Timeout (4s) Reached. Checking State.");
      
      final session = Supabase.instance.client.auth.currentSession;
      String? inviteCode = _initialInviteCode; 
      
      bool isAuthCode = inviteCode != null && inviteCode.length > 6;
      bool isInviteCode = inviteCode != null && inviteCode.length == 6;

      if (isInviteCode) {
         _addLog("Navigating to Invite: $inviteCode");
         GameSession().pendingInviteCode = inviteCode;
         Navigator.of(context).pushReplacement(
           MaterialPageRoute(builder: (_) => InviteCodeScreen(initialCode: inviteCode)),
         );
         return;
      }

      if (session == null && !isAuthCode) {
         _addLog("No Session. Navigating to Signup...");
         Navigator.of(context).pushReplacement(
           MaterialPageRoute(builder: (_) => const SignupScreen()),
         );
      } else if (isAuthCode) {
         _addLog("Auth Code Detected. Waiting...");
      }
    });

    // Check 2: Safety Net (10s)
    Future.delayed(const Duration(seconds: 10), () {
        if (!mounted) return;
        _addLog("Safety Net (10s) Reached.");
        
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
            _addLog("Still No Session. Forced Signup.");
            Navigator.of(context).pushReplacement(
               MaterialPageRoute(builder: (_) => const SignupScreen()),
            );
        }
    });
  }

  Future<void> _handleAuthenticatedUser(Session session) async {
    _addLog("Handling Auth User. Migrating...");
    // 1. Attempt Migration (Guest -> Host) if pending
    await MigrationManager().attemptMigration();

    if (!mounted) return;

    // 2. Load Host Info to check if profile exists
    final gameSession = GameSession();
    await gameSession.loadHostInfoFromPrefs();
    _addLog("Host Nickname: ${gameSession.hostNickname}");
      
      if (gameSession.hostNickname == null) {
         _addLog("No Nickname. Going to HostInfoScreen.");
         Navigator.of(context).pushReplacement(
           MaterialPageRoute(builder: (_) => HostInfoScreen()), 
         );
      } else {
         _addLog("Profile OK. Going to Home.");
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
      body: Stack(
        children: [
          Center(
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
                      fontFamily: 'NanumSquareRound', 
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // --- VERSION LABEL ---
          Positioned(
            bottom: 230,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "v1.0.1 (HTML)",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),


        ],
      ),
    );
  }
}
