import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talkbingo_app/screens/login_screen.dart';
import 'package:talkbingo_app/screens/invite_code_screen.dart';
import 'package:talkbingo_app/screens/host_info_screen.dart';
import 'package:talkbingo_app/styles/app_colors.dart';

import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/utils/migration_manager.dart';
import 'package:talkbingo_app/utils/url_cleaner.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;
  StreamSubscription<AuthState>? _authSubscription;

  bool _isAuthInProgress = false; // Add this line
  
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

  bool _isDeepLinkCheckDone = false; // Flag to prevent race conditions

  @override
  void initState() {
    super.initState();
    _addLog("InitState Started");
    
    // 1. Capture URL state IMMEDIATELY and sequentially
    _sequenceInitialization();

    _setupAuthListener();
  }

  Future<void> _sequenceInitialization() async {
    // Deep Link is now handled by DeepLinkService in main.dart globally.
    // But we add a direct web fallback for iOS Safari where app_links may not
    // properly parse hash-based URLs (e.g. /#/?code=XXXXXX).
    
    _addLog("Sequence Init. Deep Link handled globally.");
    
    // WEB FALLBACK: Direct Uri.base parsing for iOS Safari compatibility
    if (kIsWeb) {
      final existingCode = GameSession().pendingInviteCode;
      if (existingCode == null) {
        _addLog("Web Fallback: Checking Uri.base for invite code...");
        String? code;
        final uri = Uri.base;
        
        // Try standard query param first
        code = uri.queryParameters['code']?.trim();
        
        // Fallback: Parse hash fragment (e.g. /#/?code=XXXXXX)
        if (code == null) {
          final frag = uri.fragment; // e.g. "/?code=XXXXXX" or "?code=XXXXXX"
          final fullStr = uri.toString();
          var match = RegExp(r'[?&]code=([A-Za-z0-9]+)').firstMatch(frag);
          match ??= RegExp(r'[?&]code=([A-Za-z0-9]+)').firstMatch(fullStr);
          if (match != null) code = match.group(1);
        }
        
        if (code != null && RegExp(r'^[A-Z0-9]{6}$', caseSensitive: false).hasMatch(code)) {
          code = code.toUpperCase();
          GameSession().pendingInviteCode = code;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pending_invite_code', code);
          _addLog("✅ Web Fallback: Code $code extracted from Uri.base");
          
          // Clean URL
          UrlCleaner.removeCodeParam();
        } else {
          _addLog("Web Fallback: No valid code found in Uri.base");
        }
      } else {
        _addLog("Code already captured by DeepLinkService: $existingCode");
      }
    }
    
    _isDeepLinkCheckDone = true; 
    await _checkExistingSession();
  }




  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkExistingSession() async {
      // WAIT for Deep Link Check to finish if called prematurely
      if (!_isDeepLinkCheckDone) {
         _addLog("Session Check waiting for Deep Link...");
         return; // _sequenceInitialization will call us again
      }

      _addLog("Checking Existing Session...");
      try {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
            _addLog("Immediate Session Found");
            await _handleAuthenticatedUser(session);
        } else {
            _addLog("No Immediate Session. Waiting for Timeout fallback.");
        }
      } catch (e) {
        _addLog("Session Check Error: $e");
      }
  }

  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (!mounted) return;
      if (data.session != null) {
          _addLog("✅ Session Found in Listener.");
          // We MUST wait for deep link check before handling user
          if (_isDeepLinkCheckDone) {
             _handleAuthenticatedUser(data.session!);
          } else {
             _addLog("Queued Auth Handling until Deep Link check done.");
             // The sequence loop will eventually call _checkExistingSession which handles this case or currentSession
          }
      }
    });

    // Timeout Logic
    Future.delayed(const Duration(milliseconds: 4000), () async {
      if (!mounted) return;
      _addLog("⏳ Timeout (4s) Reached.");
      
      if (!_isDeepLinkCheckDone) {
         // Force finish deep link check if stuck?
         _addLog("Deep link check still pending? Forcing proceed.");
         _isDeepLinkCheckDone = true;
      }

      if (_isAuthInProgress) return;

      final session = Supabase.instance.client.auth.currentSession;
      String? inviteCode = GameSession().pendingInviteCode; 
      
      bool isInviteCode = inviteCode != null && inviteCode.length == 6;

      if (session != null) {
          _handleAuthenticatedUser(session);
      } else if (isInviteCode) {
          _addLog("Invite Code Detected w/o Session. Fast Track.");
          // Fast Track Auto-Login logic...
          try {
             final authResponse = await Supabase.instance.client.auth.signInAnonymously();
             if (authResponse.session != null) {
                _handleAuthenticatedUser(authResponse.session!);
             } else {
                throw Exception("Anon Sign-in failed");
             }
          } catch (e) {
             Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
          }
      } else {
         Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
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
    
    // CRITICAL FIX: Ensure we try to load from Server BEFORE checking validity
    await gameSession.loadProfile(); 

    _addLog("Host Nickname: ${gameSession.hostNickname}");
      
      // If code is pending, SKIP HostInfo requirement to allow Fast Track
      // This is crucial for "Guest Mode" join where we don't want to force profile setup yet.
      // Also check for empty string to prevent false positives from stale/default data
      if ((gameSession.hostNickname == null || gameSession.hostNickname!.isEmpty) && gameSession.pendingInviteCode == null) {
         _addLog("No Nickname (Null or Empty). Going to HostInfoScreen.");
         Navigator.of(context).pushReplacement(
           MaterialPageRoute(builder: (_) => HostInfoScreen()), 
         );
      } else {
         _addLog("Profile OK or Fast Track. Going to Home.");
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
          



        ],
      ),
    );
  }
}
