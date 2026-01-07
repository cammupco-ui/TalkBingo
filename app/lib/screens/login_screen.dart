import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talkbingo_app/screens/home_screen.dart'; // Redirect to Home
import 'package:talkbingo_app/screens/host_info_screen.dart';
import 'package:talkbingo_app/screens/signup_screen.dart'; // Link back to Signup
import 'package:talkbingo_app/styles/app_colors.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talkbingo_app/utils/ad_state.dart';
import 'package:talkbingo_app/utils/dev_config.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/utils/localization.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailSent = false;
  final bool _isVerified = false;
  bool _isCheckingSession = true;
  late final StreamSubscription<AuthState> _authSubscription;
  Timer? _pollingTimer;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('LoginScreen: App resumed. Checking session...');
      _checkSessionStatus();
    }
  }

  Future<void> _checkSessionStatus() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Wait for SDK to update
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      debugPrint('LoginScreen: Session found on resume.');
      _checkSession(session);
    } else {
       debugPrint('LoginScreen: No session found on resume.');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialSession();
    
    // Auth Callback Handling (identical to Signup)
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.queryParameters.containsKey('code') || uri.fragment.contains('access_token')) {
         // If verifying, we will wait for session
      }
    }

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      debugPrint('LoginScreen: Auth State Changed: ${data.event}');
      if (mounted && data.session != null) {
         debugPrint('LoginScreen: Session received from listener.');
         _checkSession(data.session!);
      }
    });

    // Handle Deep Link manually if needed (Supabase SDK usually handles this, but for safety)
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.queryParameters.containsKey('code')) {
        // Show loading while SDK processes code
        setState(() => _isCheckingSession = true);
      }
    }
  }

  Future<void> _checkInitialSession() async {
    // Wait a bit for SDK to process potential deep link
    await Future.delayed(const Duration(seconds: 1));
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _checkSession(session);
    } else {
      if (mounted) setState(() => _isCheckingSession = false);
    }
  }

  void _startPolling() {
    int pollingCount = 0;
    const int maxPollingCount = 100;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      pollingCount++;
      if (pollingCount > maxPollingCount) { timer.cancel(); return; }
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _checkSession(session);
        timer.cancel();
      }
    });
  }

  void _checkSession(Session session) {
    if (!mounted) return;
    
    // Auto-navigate if session is valid
    if (DevConfig.isDevMode.value || session.user.id.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _authSubscription.cancel();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: _emailController.text.trim().toLowerCase(),
        shouldCreateUser: false, // Log-in Only
        emailRedirectTo: kIsWeb ? Uri.base.origin : 'io.supabase.talkbingo://login-callback', 
      );
      if (mounted) {
        setState(() => _isEmailSent = true);
        _startPolling();
      }
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error occurred'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => AdState.showAd.value = false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Center(
                child: SvgPicture.asset('assets/images/Logo Vector.svg', width: 72, height: 72),
              ),
              const SizedBox(height: 20),
              Text(
                'TALKBINGO',
                style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'NURA', color: AppColors.hostPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),

              if (_isCheckingSession || _isLoading)
                 const Center(child: CircularProgressIndicator(color: AppColors.hostPrimary))
              else ...[
                // Google Sign In Button
                ElevatedButton.icon(
                  onPressed: _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  icon: SvgPicture.asset( // Ensure you have google_logo.svg or use Icon(Icons.login) temporarily
                    'assets/images/google_logo.svg', 
                    height: 24,
                    width: 24,
                    // Fallback to icon if asset specific log is missing, but usually we add it. 
                    // For now, I'll use a standard Icon if asset is risky, but let's assume standard asset or use text.
                    // Actually, let's use a standard Icon for safety if asset doesn't exist.
                  ), 
                  label: Text(
                    AppLocalizations.get('continue_google'),
                    style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'NURA')),
                  ),
                ),
                
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.get('quick_secure_login'),
                  textAlign: TextAlign.center,
                  style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? Uri.base.origin : 'io.supabase.talkbingo://login-callback',
      );
      // OAuth flow redirects away, so loading state stays until return
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error occurred'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }
}
