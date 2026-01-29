import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talkbingo_app/screens/host_info_screen.dart';
import 'package:talkbingo_app/screens/home_screen.dart';
import 'package:talkbingo_app/screens/login_screen.dart'; // Add LoginScreen import
import 'package:talkbingo_app/screens/invite_code_screen.dart'; // Added for manual guest entry
import 'package:talkbingo_app/styles/app_colors.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talkbingo_app/utils/ad_state.dart';
import 'package:talkbingo_app/utils/dev_config.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/utils/localization.dart';
import 'package:talkbingo_app/widgets/animated_button.dart';


class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with WidgetsBindingObserver {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailSent = false;
  bool _isVerified = false;
  bool _isVerifying = false;
  bool _isCheckingSession = true; // New state for initial session check
  late final StreamSubscription<AuthState> _authSubscription;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialSession(); // Check session on load
    
    // Check if we are handling an auth callback (Magic Link)
    bool isAuthCallback = false;
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.queryParameters.containsKey('code')) {
        isAuthCallback = true;
        _isVerifying = true; 
        _isCheckingSession = false; // Skip session check UI if verifying
      } else if (uri.fragment.contains('access_token') || uri.fragment.contains('type=recovery')) {
        isAuthCallback = true;
        _isVerifying = true;
        _isCheckingSession = false;
      }
      
      if (uri.queryParameters['error_code'] == 'otp_expired') {
        _isVerifying = false; 
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verification link expired. Please send email again.'), backgroundColor: Colors.red),
            );
          }
        });
      }

      // If we are verifying, we must ensure we actually check the session!
      // Sometimes onAuthStateChange doesn't fire if the session is restored instantly.
      if (_isVerifying) {
         _waitForSession();
      }
    }

    if (!isAuthCallback) {
      // Don't sign out immediately, check session first
    }
    
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted && data.session != null) {
         _checkSession(data.session);
      }
    });
  }

  Future<void> _checkInitialSession() async {
    // Wait a bit to show the logo/loading state (optional, for smooth UX)
    await Future.delayed(const Duration(seconds: 1));

    final session = Supabase.instance.client.auth.currentSession;
    
    // Check Session (Ignore Anonymous users, they should see the Signup/Link UI)
    bool isRealUser = session != null && !session.user.isAnonymous;

    // Check Dev Mode or Real Session
    if (DevConfig.isDevMode.value || isRealUser) {
      if (mounted) {
        // Navigate to Home Screen (User requested Host Setup, but Home is the dashboard)
        // Using HomeScreen as it's the main entry point for logged-in users
        // Check if Profile is set to route correctly
        final gs = GameSession(); // Ensure instance
        // Best effort: we might not have updated prefs yet. 
        // But typically Splash handles routing. 
        // If we get here, it means we are already logged in.
        
        // Let's defer to Splash logic OR just go to HostInfo if name is missing.
        // For now, force HostInfoScreen as requested by user.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HostInfoScreen()), // Proceed to Profile Setup
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _isCheckingSession = false; // Show Signup UI
        });
      }
    }
  }

  Future<void> _waitForSession() async {
    // 1. Try to inspect URL for code immediately
    final uri = Uri.base;
    final code = uri.queryParameters['code'];
    
    if (code != null) {
       print('SignupScreen: Auth Code found ($code). Attempting manual exchange logic if needed.');
       // Sometimes Supabase auto-exchange works, sometimes it needs help on Web depending on config.
       // We'll give it a moment to auto-exchange first.
    }

    // Poll for a few seconds to see if session appears
    for (int i = 0; i < 20; i++) {
      if (!mounted) return;
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        print('SignupScreen: Session found via polling. Verifying.');
        _checkSession(session);
        return;
      }
      
      // If we have a code and we are halfway through polling without session, try manual exchange
      if (i == 5 && code != null) { // After 2.5 seconds
         print('SignupScreen: Auto-exchange might have failed. Attempting manual exchange.');
         try {
            await Supabase.instance.client.auth.exchangeCodeForSession(code);
            // If successful, next poll will catch the session
         } catch (e) {
            print('SignupScreen: Manual exchange failed or already used: $e');
         }
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // If timed out, stop verifying and show login
    if (mounted) {
      setState(() {
        _isVerifying = false;
        _isCheckingSession = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Verification timed out. Try refreshing or use the manual link.")),
      );
    }
  }

  void _startPolling() {
    int pollingCount = 0;
    const int maxPollingCount = 100; // 3 seconds * 100 = 5 minutes

    _pollingTimer?.cancel(); // Cancel existing timer if any
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      pollingCount++;
      if (pollingCount > maxPollingCount) {
        timer.cancel();
        return;
      }

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _checkSession(session);
        timer.cancel(); // Stop polling once verified
      }
    });
  }

  Future<void> _checkSession(Session? session) async {
    if (session != null && mounted) {
      // Ignore Anonymous sessions to allow Account Linking/Signup
      if (session.user.isAnonymous) {
        debugPrint("SignupScreen: Ignoring Anonymous Session during check");
        return;
      }

      // 1. Stop Loading / Timers
      _pollingTimer?.cancel();
      setState(() {
         _isLoading = false; 
         _isVerified = true;
      });

      // 2. Check Role/Profile to decide destination
      // If user already has a profile (e.g. linked account or returning user), go to Home directly
      // instead of forcing HostInfoScreen (onboarding).
      bool hasProfile = false;
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', session.user.id)
            .maybeSingle();
        hasProfile = profile != null;
      } catch (e) {
        debugPrint("SignupScreen: Error checking profile: $e");
      }

      if (!mounted) return;

      if (hasProfile) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HostInfoScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final session = Supabase.instance.client.auth.currentSession;
      _checkSession(session);
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

  Future<void> _handleManualLink() async {
    final TextEditingController linkController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Verification Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste the full link from your email here:'),
            const SizedBox(height: 10),
            TextField(
              controller: linkController,
              decoration: const InputDecoration(
                hintText: 'http://localhost:3000/?code=...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final link = linkController.text.trim();
              if (link.isEmpty) return;
              
              Navigator.pop(context); // Close dialog
              
              try {
                final uri = Uri.parse(link);
                final code = uri.queryParameters['code'];
                if (code != null) {
                  setState(() => _isLoading = true);
                  await Supabase.instance.client.auth.exchangeCodeForSession(code);
                  // The listener will pick up the session
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid link: No code found'), backgroundColor: Colors.red),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: _emailController.text.trim().toLowerCase(),
        emailRedirectTo: kIsWeb ? Uri.base.origin : 'io.supabase.talkbingo://login-callback', 
      );
      
        if (mounted) {
          setState(() {
            _isEmailSent = true;
          });
          _startPolling(); // Ensure polling starts after sending email
        }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                AnimatedButton(
                  onPressed: _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.hostPrimary, // Restore to Primary Color
                    foregroundColor: Colors.white,
                    elevation: 2,
                    minimumSize: const Size(double.infinity, 60), // Increased Height
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: SvgPicture.asset(
                          'assets/images/google_logo.svg', 
                          height: 18,
                          width: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.get('sign_up_google'),
                        style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'NURA')),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24), // Increased spacing

                // Manual Code Entry (Guest) - Hide if already anonymous (Converting Account)
                if ((Supabase.instance.client.auth.currentSession?.user.isAnonymous ?? false) == false)
                AnimatedOutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const InviteCodeScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.hostPrimary,
                    side: const BorderSide(color: AppColors.hostPrimary),
                    minimumSize: const Size(double.infinity, 60), // Increased Height
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.get('enter_invite_code'),
                    style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'NURA')),
                  ),
                ),

                const SizedBox(height: 16),
                
                // Link to Sign In
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.get('already_account'),
                          style: AppLocalizations.getTextStyle(baseStyle: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        ),
                        Text(
                          AppLocalizations.get('log_in'),
                          style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                         const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
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
        redirectTo: kIsWeb 
          ? Uri.base.origin 
          : 'io.supabase.talkbingo://login-callback',
      );
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
