import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/screens/game_screen.dart';
import 'package:talkbingo_app/utils/dev_config.dart';
import 'package:talkbingo_app/styles/app_colors.dart';

class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  
  @override
  void initState() {
    super.initState();
    // Simulate polling for game start (Phase 4 will link to real backend)
    _listenForGameStart();
    
    // Polling Fallback (in case Realtime fails)
    Timer.periodic(const Duration(seconds: 3), (timer) async {
       if (!mounted) {
         timer.cancel();
         return;
       }
       await GameSession().refreshSession();
       // Check immediately after refresh
       _checkGameStarted();
    });
  }

  void _listenForGameStart() async {
    final session = GameSession();

    // HOST FLOW
    if (session.myRole == 'A') {
      // Host Logic (Already implemented roughly, but ensuring flow)
      // Host creates game at Start, fetches questions, then pushes GameScreen
      // This is usually handled before arriving here or immediately upon arrival.
      
      // If we arrived here, we assume session is created.
      // Fetch questions if not loaded
      if (session.questions.isEmpty) {
        await session.fetchQuestionsFromBackend();
      }
      
      // Update status to playing? Or wait for manual start?
      // PRD says "Waiting Screen -> Game Screen".
      // Let's assume auto-start for now once questions are ready.
       if (mounted && session.questions.isNotEmpty) {
         // Force Upload Questions to Supabase so Guest receives them
         await session.uploadInitialQuestions();

         WidgetsBinding.instance.addPostFrameCallback((_) {
           if (mounted) {
             Navigator.of(context).pushReplacement(
               MaterialPageRoute(builder: (_) => const GameScreen()),
             );
           }
         });
       }
       
    } 
    // GUEST FLOW
    else {
      print('WaitingScreen: Guest waiting for questions/game start...');
      
      // 1. Check if already ready (e.g. Host started before we arrived)
      // 1. Check if already ready (e.g. Host started before we arrived)
      if (session.questions.isNotEmpty) {
         print('WaitingScreen: Questions already loaded. Going to Game.');
         WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
               Navigator.of(context).pushReplacement(
                 MaterialPageRoute(builder: (_) => const GameScreen()),
               );
            }
         });
         return;
      }

      // 2. Listen for updates (Realtime)
      session.addListener(_checkGameStarted);
    }
  }

  void _checkGameStarted() {
     final session = GameSession();
     // Guest Logic: Check if questions are loaded/synced
     if (session.questions.isNotEmpty) {
       print('WaitingScreen: Questions loaded via Sync. Going to Game.');
       session.removeListener(_checkGameStarted);
       
       if (mounted) {
         WidgetsBinding.instance.addPostFrameCallback((_) {
           if (mounted) {
             Navigator.of(context).pushReplacement(
               MaterialPageRoute(builder: (_) => const GameScreen()),
             );
           }
         });
       }
     }
  }

  @override
  void dispose() {
    // Clean up listeners if any active references remain
    // GameSession().removeListener(_checkGameStarted); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.hostPrimary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             // Logo with Rotation Animation (White)
            SvgPicture.asset(
              'assets/images/logo_vector.svg',
              width: 72,
              height: 72,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .rotate(duration: 1000.ms, curve: Curves.linear),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white24,
                color: Colors.white,
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 32),
            
            Text(
              // Show appropriate text based on Role
              GameSession().myRole == 'A' 
               ? 'Waiting for Guest...\nCode: ${GameSession().inviteCode}' 
               : 'Waiting for Host to Start...',
              textAlign: TextAlign.center,
              style: GoogleFonts.alexandria(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              GameSession().myRole == 'A' 
               ? 'Share the code with your partner.'
               : 'The game will start soon!',
              style: GoogleFonts.alexandria(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
