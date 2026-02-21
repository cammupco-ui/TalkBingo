import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talkbingo_app/screens/home_screen.dart'; // Redirect to Home
import 'package:talkbingo_app/screens/host_info_screen.dart';
import 'package:talkbingo_app/screens/signup_screen.dart'; // Link back to Signup
import 'package:talkbingo_app/screens/invite_code_screen.dart';
import 'package:talkbingo_app/screens/forgot_password_screen.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talkbingo_app/utils/ad_state.dart';
import 'package:talkbingo_app/utils/dev_config.dart';
import 'package:talkbingo_app/utils/localization.dart';
import 'package:talkbingo_app/widgets/animated_button.dart';
import 'package:talkbingo_app/utils/auth_error_helper.dart';
import 'package:talkbingo_app/services/social_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.get('auth_error_fill_all')), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        if (response.session != null) {
          _checkSession(response.session!);
        }
      }
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getAuthErrorMessage(e)), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getAuthErrorMessage(e)), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkSession(Session session) async {
    // Check Profile to decide destination (Home vs Onboarding)
    bool hasProfile = false;
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', session.user.id)
          .maybeSingle();
      hasProfile = profile != null;
    } catch (e) {
      debugPrint("LoginScreen: Error checking profile: $e");
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

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => AdState.showAd.value = false);
    final screenHeight = MediaQuery.of(context).size.height;
    final logoSize = (screenHeight * 0.08).clamp(48.0, 80.0);
    final titleFontSize = (screenHeight * 0.028).clamp(18.0, 26.0);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top padding — ensures logo is well below the status bar
              SizedBox(height: screenHeight * 0.04),

              Center(
                child: SvgPicture.asset('assets/images/logo_vector.svg', width: logoSize, height: logoSize),
              ),
              const SizedBox(height: 12),
              Text(
                'TALKBINGO',
                style: TextStyle(
                  fontSize: titleFontSize, fontWeight: FontWeight.w700, fontFamily: 'NURA', color: AppColors.hostPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.04),

              // Email Field
              _buildTextField(
                controller: _emailController,
                label: AppLocalizations.get('email') ?? 'Email',
                hint: AppLocalizations.get('enter_email') ?? 'Enter email',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),

              // Password Field
              _buildTextField(
                controller: _passwordController,
                label: AppLocalizations.get('password') ?? 'Password',
                hint: AppLocalizations.get('enter_password') ?? 'Enter password',
                icon: Icons.lock_outline,
                isPassword: true,
                isObscure: _obscurePassword,
                onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              
              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    AppLocalizations.get('forgot_password') ?? 'Forgot Password?',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Login Button
              AnimatedButton(
                onPressed: _isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.hostPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      AppLocalizations.get('log_in') ?? 'Log In',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
              ),
              
              const SizedBox(height: 20),

              // OR Divider
              Row(
                children: [
                   const Expanded(child: Divider()),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 16),
                     child: Text(AppLocalizations.get('or_divider') ?? 'OR', style: const TextStyle(color: Colors.grey)),
                   ),
                   const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),

              // Social Login Buttons (mobile only)
              if (!kIsWeb) ...[
                _buildSocialButton(
                  label: AppLocalizations.get('sign_in_google') ?? 'Google로 계속하기',
                  icon: Icons.g_mobiledata,
                  backgroundColor: Colors.white,
                  textColor: Colors.black87,
                  borderColor: Colors.grey[300]!,
                  onPressed: _isLoading ? null : _signInWithGoogle,
                ),
                const SizedBox(height: 12),
                _buildSocialButton(
                  label: AppLocalizations.get('sign_in_kakao') ?? '카카오로 계속하기',
                  icon: Icons.chat_bubble,
                  backgroundColor: const Color(0xFFFEE500),
                  textColor: const Color(0xFF191919),
                  onPressed: _isLoading ? null : _signInWithKakao,
                ),
                const SizedBox(height: 20),
              ],

              // Invite Code Button
              AnimatedOutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const InviteCodeScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.hostPrimary,
                  side: const BorderSide(color: AppColors.hostPrimary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  AppLocalizations.get('enter_invite_code') ?? 'Enter Invite Code',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 24),

              // Sign Up Link — with enough padding for tap target
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const SignupScreen()),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          AppLocalizations.get('sign_up_email') ?? 'Sign Up',
                          style: const TextStyle(color: AppColors.hostPrimary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Extra spacing to clear ad banner + bottom safe area
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final response = await SocialAuthService.signInWithGoogle();
      if (mounted && response.session != null) {
        _checkSession(response.session!);
      }
    } on AuthException catch (e) {
      debugPrint('Google sign-in AuthException: ${e.message}');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getAuthErrorMessage(e)), backgroundColor: Colors.red));
    } catch (e, stackTrace) {
      debugPrint('Google sign-in error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        final errorMsg = e.toString();
        // Show more helpful message based on common errors
        String displayMsg;
        if (errorMsg.contains('sign_in_canceled') || errorMsg.contains('canceled')) {
          displayMsg = AppLocalizations.get('auth_error_cancelled') ?? 'Login cancelled.';
        } else if (errorMsg.contains('network_error') || errorMsg.contains('ApiException: 7')) {
          displayMsg = AppLocalizations.get('auth_error_network') ?? 'Network error. Please check your connection.';
        } else if (errorMsg.contains('ApiException: 10')) {
          displayMsg = 'Google Play Services error. Please update Google Play Services.';
        } else if (errorMsg.contains('ApiException: 12500')) {
          displayMsg = 'Google Sign-In configuration error. Please check developer settings.';
        } else {
          displayMsg = '${AppLocalizations.get('auth_error_generic') ?? 'An error occurred.'}\n(${e.runtimeType}: $errorMsg)';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(displayMsg, maxLines: 3),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithKakao() async {
    setState(() => _isLoading = true);
    try {
      await SocialAuthService.signInWithKakao();
      // Kakao uses browser redirect; auth state listener handles the rest
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getAuthErrorMessage(e)), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: textColor, size: 24),
        label: Text(label, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: borderColor != null ? BorderSide(color: borderColor) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey),
            suffixIcon: isPassword 
              ? IconButton(
                  icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                  onPressed: onToggleObscure,
                )
              : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppColors.hostPrimary, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }
}
