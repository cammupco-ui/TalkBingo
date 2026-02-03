import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/utils/localization.dart';
import 'package:talkbingo_app/widgets/animated_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your email'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
      // Determine Redirect URL (Same logic as SignupScreen)
      String? redirectUrl;
      if (kIsWeb) {
        final uri = Uri.base;
         // If we are on "cammupco-ui.github.io/TalkBingo/", we must redirect back to that.
        if (uri.path.contains('/TalkBingo')) {
           redirectUrl = '${uri.origin}/TalkBingo/';
        } else {
           redirectUrl = uri.origin;
        }
      } else {
        redirectUrl = 'io.supabase.talkbingo://reset-callback';
      }

      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectUrl,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(AppLocalizations.get('reset_link_sent') ?? 'Password reset link sent to your email.'),
            actions: [
              TextButton(
                onPressed: () {
                   Navigator.of(context).pop(); // Close Dialog
                   Navigator.of(context).pop(); // Go back to login
                }, 
                child: const Text("OK")
              ),
            ],
          ),
        );
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Text(
              AppLocalizations.get('forgot_password') ?? 'Forgot Password?',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Enter your email to receive a password reset link.",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Email Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.get('email') ?? 'Email', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.get('enter_email') ?? 'Enter email',
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            AnimatedButton(
              onPressed: _isLoading ? null : _sendResetLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.hostPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
               child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      AppLocalizations.get('send_reset_link') ?? 'Send Reset Link',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
