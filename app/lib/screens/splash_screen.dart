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

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;
  String? _initialInviteCode;
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

  @override
  void initState() {
    super.initState();
    _addLog("InitState Started");
    
    // 1. Capture URL state IMMEDIATELY
    _initDeepLinks();

    // Select random index once
    _randomIndex = DateTime.now().millisecondsSinceEpoch % _koreanTexts.length;

    _setupAuthListener();
    
    // Explicitly check session immediately to prevent waiting if already logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _checkExistingSession();
    });
  }

  Future<void> _initDeepLinks() async {
    try {
      Uri? targetUri;
      if (kIsWeb) {
        targetUri = Uri.base;
      } else {
        final appLinks = AppLinks();
        targetUri = await appLinks.getInitialLink();
        
        // Listen for Stream (Foreground/Background)
        appLinks.uriLinkStream.listen((uri) => _handleDeepLink(uri));
      }

      if (targetUri != null) {
        _handleDeepLink(targetUri);
      }

    } catch (e) {
      _addLog("Error capturing Deep Link: $e");
    }
  }

  void _handleDeepLink(Uri uri) {
     if (!mounted) return;

     // 1. Check for Auth Params (Magic Link, Signup, Recovery)
     final hasFragmentToken = uri.fragment.contains('access_token');
     final hasQueryToken = uri.queryParameters.containsKey('access_token');
     final authType = uri.queryParameters['type']; // signup, recovery, magiclink, invite
     
     if (hasFragmentToken || hasQueryToken || authType == 'signup' || authType == 'recovery' || authType == 'magiclink') {
        _addLog("🔐 Auth Params Detected! (Type: $authType)");
        setState(() {
          _isAuthInProgress = true;
        });
        return; 
     }

     // 2. Check for Invite Code
     String? code = uri.queryParameters['code']?.trim();
     
     // Fallback: Check Fragment (Hash Routing support for Web)
     if (code == null && uri.fragment.isNotEmpty) {
        try {
            // Fragment often looks like "/?code=XXXXXX" or "/invite?code=XXXXXX"
            // We construct a dummy URI to parse parameters easily
            final fragmentString = uri.fragment.startsWith('/') ? uri.fragment : '/${uri.fragment}';
            final fragmentUri = Uri.parse("http://dummy$fragmentString");
            code = fragmentUri.queryParameters['code']?.trim();
        } catch (e) {
            // Last resort regex
            final match = RegExp(r'code=([A-Z0-9]{6})', caseSensitive: false).firstMatch(uri.fragment);
            if (match != null) code = match.group(1);
        }
     }
     
     if (code != null) {
        // Recursive Clean: If code acts as a URL container (bug fix)
        if (code.contains('http') || code.contains('://')) {
            try {
               final innerUri = Uri.parse(code);
               code = innerUri.queryParameters['code']?.trim();
            } catch (e) { /* ignore */ }
        }

        // Validate Format (6 Chars, Alphanumeric)
        // Note: invite codes generated are 6 chars, usually uppercase + numbers.
        final bool isValid = code != null && RegExp(r'^[A-Z0-9]{6}$', caseSensitive: false).hasMatch(code!);

        if (isValid) { 
           // Standardize to Uppercase
           code = code!.toUpperCase();
           
           _initialInviteCode = code; 
           GameSession().pendingInviteCode = code; 
           _addLog("📩 Invite Code Captured: $code");
           UrlCleaner.removeCodeParam(); 
           
           if (!_isAuthInProgress) _checkExistingSession(); 
        } else {
           _addLog("⚠️ Invalid Code Ignored: ${uri.queryParameters['code']}");
        }
     }
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
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (!mounted) return;
      
      final session = data.session;
      final event = data.event;
      _addLog("Auth Event: $event");

      if (session != null) {
           _addLog("✅ Session Found in Listener. Handling User.");
           if (mounted) setState(() => _isAuthInProgress = false);
           _handleAuthenticatedUser(session);
      } else if (event == AuthChangeEvent.signedOut) {
         if (mounted) setState(() => _isAuthInProgress = false);
      }
    });

    // 2. Initial Checks (Timeouts)
    Future.delayed(const Duration(milliseconds: 4000), () async {
      if (!mounted) return;
      _addLog("⏳ Timeout (4s) Reached.");
      
      // If Auth is in Progress, DO NOT REDIRECT yet.
      if (_isAuthInProgress) {
         _addLog("✋ Auth In Progress. Skipping Timeout Redirect. Waiting for Stream...");
         return;
      }

      final session = Supabase.instance.client.auth.currentSession;
      String? inviteCode = _initialInviteCode ?? GameSession().pendingInviteCode; 
      
      bool isInviteCode = inviteCode != null && inviteCode.length == 6;

      if (isInviteCode) {
         _addLog("Invite Code Detected: $inviteCode. Fast Track...");
         
         if (session == null) {
            _addLog("No Session. Auto-login for Fast Track...");
             try {
                final authResponse = await Supabase.instance.client.auth.signInAnonymously();
                if (authResponse.session != null) {
                   _handleAuthenticatedUser(authResponse.session!);
                } else {
                   throw Exception("Anon Sign-in failed");
                }
             } catch (e) {
                _addLog("Auto-login failed: $e. Going to Login.");
                Navigator.of(context).pushReplacement(
                   MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
             }
         } else {
             _handleAuthenticatedUser(session);
         }
         return;
      }

      if (session == null) {
         _addLog("No Session & No Auth in Progress. Navigating to Login...");
         Navigator.of(context).pushReplacement(
           MaterialPageRoute(builder: (_) => const LoginScreen()),
         );
      }
    });

    // Check 2: Safety Net (20s)
    Future.delayed(const Duration(seconds: 20), () {
        if (!mounted) return;
        _addLog("🚨 Safety Net (20s) Reached.");
        
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
            _addLog("Still No Session. Forced Signup.");
            Navigator.of(context).pushReplacement(
               MaterialPageRoute(builder: (_) => const LoginScreen()),
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
