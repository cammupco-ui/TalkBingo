import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/screens/splash_screen.dart';
import 'package:talkbingo_app/utils/dev_config.dart';

class SignOutLandingScreen extends StatelessWidget {
  const SignOutLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon or Logo
              Icon(Icons.waving_hand_rounded, size: 64, color: AppColors.hostPrimary.withOpacity(0.8)),
              const SizedBox(height: 24),
              
              // Title
              Text(
                'See you again!',
                style: GoogleFonts.alexandria(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.hostPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Subtitle
              Text(
                'You have been successfully signed out.',
                style: GoogleFonts.alexandria(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Option 1: Log In Again (Return to Title)
              ElevatedButton(
                onPressed: () {
                   // Disable Dev Mode to ensure we don't auto-redirect
                   DevConfig.isDevMode.value = false;
                   
                   Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SplashScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.hostPrimary,
                  foregroundColor: Colors.white,
                  fixedSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: Row( // Row to center text with icon optionally, or just text
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.login, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Log In Again / Start',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Option 2: Exit App
              OutlinedButton(
                onPressed: () {
                  SystemNavigator.pop(); // Note: Might not work on iOS based on Apple guidelines, but standard for Android
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[300]!),
                  fixedSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Exit App',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
