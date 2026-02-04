import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:talkbingo_app/widgets/animated_button.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:share_plus/share_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talkbingo_app/utils/ad_state.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/screens/game_setup_screen.dart';
import 'package:talkbingo_app/screens/home_screen.dart';

import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/styles/app_spacing.dart';


class HostSetupScreen extends StatefulWidget {
  final String? initialGender;
  final String? initialMainRelation;
  final String? initialSubRelation;
  final int? initialIntimacyLevel;

  const HostSetupScreen({
    super.key,
    this.initialGender,
    this.initialMainRelation,
    this.initialSubRelation,
    this.initialIntimacyLevel,
  });

  @override
  State<HostSetupScreen> createState() => _HostSetupScreenState();
}

class _HostSetupScreenState extends State<HostSetupScreen> {
  String? _inviteCode;
  bool _isGenerated = false;

  Future<void> _generateCode() async {
    // 1. Generate local code first for UI
    GameSession().generateInviteCode();
    setState(() {
      _inviteCode = GameSession().inviteCode;
      _isGenerated = true;
    });

    // 2. Immediately create the session in Supabase
    // This allows guests to join while Host is still on this screen.
    final success = await GameSession().createGame();
    if (!success) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Failed to create game session. Please try again.'), backgroundColor: Colors.red),
         );
      }
    } else {
      print('HostSetupScreen: Game Session Created! Code: $_inviteCode');
    }
  }

  Future<void> _shareCode() async {
    if (_inviteCode != null) {
      String link;
      if (kIsWeb) {
        // Fix: Ensure we include the base path (e.g. /TalkBingo/) 
        // Uri.base.origin gives "https://domain.com"
        // Uri.base.path gives "/TalkBingo/" (or similar)
        // Combine them to get "https://domain.com/TalkBingo/"
        String baseUrl = Uri.base.origin + Uri.base.path;
        // Remove trailing 'index.html' if present (unlikely but possible)
        baseUrl = baseUrl.replaceAll('index.html', '');
        // Remove trailing slash to clean up before appending query
        if (baseUrl.endsWith('/')) {
             baseUrl = baseUrl.substring(0, baseUrl.length - 1);
        }
        
        // Force Hash Routing Format for GitHub Pages consistency
        // Even if local dev doesn't use it, Prod does.
        link = '$baseUrl/#/?code=$_inviteCode';
      } else {
        // Mobile App: Use a deep link or valid web placeholder
        // Since we don't have a real domain yet, using a standard schema example or custom scheme
        link = 'talkbingo://join?code=$_inviteCode';
      }
      
      final String message = 
          '초대장이 도착했습니다! 💌\n'
          '[TalkBingo] 게임에 초대합니다.\n\n'
          '참여 코드: $_inviteCode\n'
          '바로 입장하기: $link';

      // 1. Try to open System Share Sheet
      // We attempt this on ALL platforms (including Web).
      // Modern mobile browsers (iOS Safari, Chrome Android) support proper sharing.
      // Legacy browsers/PC might fall back to 'mailto', but the 'Copy to Clipboard' below ensures the user is covered.
      final box = context.findRenderObject() as RenderBox?;
      
      try {
        await Share.share(
          message,
          subject: 'TalkBingo Invite Code',
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        );
      } catch (e) {
        debugPrint('Share failed: $e');
      }
      
      // 2. ALWAYS Copy to Clipboard as a safety net
      // This ensures that even if Share fails (or opens mailto), the user has the link ready to paste.
      await Clipboard.setData(ClipboardData(text: message));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link is ready! (Copied to clipboard & Opening Share...)'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFFBD0558),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hide Ad on Host Setup Screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdState.showAd.value = false;
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
          child: SvgPicture.asset(
            'assets/images/Logo Vector.svg',
            height: 30,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFBD0558)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Invite Code',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700, // Bold
                fontFamily: 'NURA',
                color: AppColors.hostPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sectionSpacing),

            if (_isGenerated) ...[

              // Code Display
              // Code Display
              // Code Display
              // Code Display (Tap to Copy)
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: _inviteCode!));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard!'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Color(0xFFBD0558),
                      ),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 150),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFBD0558)),
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    color: const Color(0xFFBD0558).withOpacity(0.1),

                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _inviteCode!,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NURA',
                          color: Color(0xFFBD0558),
                          letterSpacing: 4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to Copy',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFFBD0558).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.spacingMd),
              
              // Copy (Share) Button

              AnimatedOutlinedButton(
                onPressed: _shareCode,
                style: OutlinedButton.styleFrom(
                  fixedSize: const Size.fromHeight(AppSpacing.buttonHeight), // Strict 44px
                  side: const BorderSide(color: AppColors.hostPrimary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.share, color: AppColors.hostPrimary),
                    const SizedBox(width: 8),
                    const Text(
                      'Share', 
                      style: TextStyle(
                        fontSize: 16, 
                        fontFamily: 'NURA', 
                        fontWeight: FontWeight.bold,
                        color: AppColors.hostPrimary,
                      )
                    ),
                  ],
                ),
              ),
               const SizedBox(height: AppSpacing.spacingLg),

              // Next Button
              AnimatedButton(
                onPressed: () {
                   Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GameSetupScreen(
                        initialGender: widget.initialGender,
                        initialMainRelation: widget.initialMainRelation,
                        initialSubRelation: widget.initialSubRelation,
                        initialIntimacyLevel: widget.initialIntimacyLevel,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.hostPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  fixedSize: const Size.fromHeight(AppSpacing.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Next',
                  style: TextStyle(fontSize: AppSpacing.buttonFontSize, fontFamily: 'NURA', fontWeight: FontWeight.bold),
                ),
              ),
            ] else ...[
              // Generate Button
              AnimatedButton(
                onPressed: _generateCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.hostPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  fixedSize: const Size.fromHeight(AppSpacing.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Generate',
                  style: TextStyle(fontSize: AppSpacing.buttonFontSize, fontFamily: 'NURA', fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
