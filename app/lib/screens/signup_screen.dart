import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talkbingo_app/screens/home_screen.dart';
import 'package:talkbingo_app/screens/login_screen.dart';
import 'package:talkbingo_app/screens/invite_code_screen.dart';
import 'package:talkbingo_app/screens/host_info_screen.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/utils/localization.dart';
import 'package:talkbingo_app/widgets/animated_button.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter/foundation.dart'; // Added for kIsWeb

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // ... (controllers omitted) ...
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }

    if (password != confirmPassword) {
      _showSnack(AppLocalizations.get('password_mismatch') ?? 'Passwords do not match');
      return;
    }

    if (password.length < 6) {
      _showSnack(AppLocalizations.get('weak_password') ?? 'Password too weak');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Determine Redirect URL
      String? redirectUrl;
      if (kIsWeb) {
        // Fix for GitHub Pages subdirectory hosting
        // If we are on "cammupco-ui.github.io/TalkBingo/", we must redirect back to that, not root.
        final uri = Uri.base;
        if (uri.path.contains('/TalkBingo')) {
           redirectUrl = '${uri.origin}/TalkBingo/';
        } else {
           // Localhost or Custom Domain root
           redirectUrl = uri.origin;
        }
      }

      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: redirectUrl,
      );

      if (mounted) {
        if (response.session != null) {
          // Auto login successful (if confirm email is off)
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HostInfoScreen()),
          );
        } else {
          // Email confirmation required
          _showDialog(
            AppLocalizations.get('check_email_verification') ?? 'Check your email',
            () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        // Check for specific error messages indicating duplicate account
        if (e.message.contains('User already registered') || 
            e.message.contains('unique constraint')) { 
          
          _showDialog(
            AppLocalizations.get('account_exists') ?? '이미 가입된 계정입니다.\n로그인 페이지로 이동합니다.',
            () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          );
        } else if (e.message.contains('Failed to decode error response')) {
           // Handle generic Supabase Web error (likely network or 500)
           _showSnack("서버 연결 상태가 불안정합니다. (Network Error)\n새로고침 후 다시 시도해주세요.");
        } else {
           _showSnack(e.message);
        }
      }
    } catch (e) {
      if (mounted) _showSnack('Signup Failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showDialog(String message, VoidCallback onOk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: onOk, child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            children: [
              // Logo
              Center(
                child: SvgPicture.asset('assets/images/logo_vector.svg', width: 80, height: 80),
              ),
              const SizedBox(height: 20),
              Text(
                'TALKBINGO',
                style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'NURA', color: AppColors.hostPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Sign Up Title Removed

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
              const SizedBox(height: 16),

              // Confirm Password Field
              _buildTextField(
                controller: _confirmPasswordController,
                label: AppLocalizations.get('confirm_password') ?? 'Confirm Password',
                hint: AppLocalizations.get('confirm_password') ?? 'Confirm Password',
                icon: Icons.lock_outline,
                isPassword: true,
                isObscure: _obscureConfirmPassword,
                onToggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              const SizedBox(height: 30),

              // Sign Up Button
              AnimatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.hostPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      AppLocalizations.get('sign_up_email') ?? 'Sign Up',
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

              // Invite Code Button (Guest Mode) - KEPT AS REQUESTED
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  AppLocalizations.get('enter_invite_code') ?? 'Enter Invite Code',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.get('already_account') ?? 'Already have an account? '),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Text(
                      AppLocalizations.get('log_in') ?? 'Log In',
                      style: const TextStyle(color: AppColors.hostPrimary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
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
