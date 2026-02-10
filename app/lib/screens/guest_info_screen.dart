import 'package:flutter/material.dart';
import 'package:talkbingo_app/widgets/animated_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talkbingo_app/utils/ad_state.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/screens/waiting_screen.dart';
import 'package:talkbingo_app/screens/home_screen.dart';
import 'package:talkbingo_app/utils/dev_config.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/styles/app_spacing.dart';


class GuestInfoScreen extends StatefulWidget {
  final String? initialNickname;
  
  const GuestInfoScreen({super.key, this.initialNickname});

  @override
  State<GuestInfoScreen> createState() => _GuestInfoScreenState();
}

class _GuestInfoScreenState extends State<GuestInfoScreen> {
  final _nicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialNickname != null) {
      _nicknameController.text = widget.initialNickname!;
    } else if (GameSession().guestNickname != null && GameSession().guestNickname!.isNotEmpty) {
       _nicknameController.text = GameSession().guestNickname!;
    } else if (DevConfig.isDevMode.value) {
      _nicknameController.text = 'GuestUser';
    }
  }

  bool get _isFormValid {
    return _nicknameController.text.isNotEmpty;
  }

  Future<void> _onNextPressed() async {
    if (_isFormValid) {
      // Save Guest Data to GameSession via Sync
      final session = GameSession();
      await session.updateGuestProfile(_nicknameController.text);
      
      print('Guest Info Saved: ${session.guestNickname}');

      // Navigate to Waiting Screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => WaitingScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
     WidgetsBinding.instance.addPostFrameCallback((_) {
      AdState.showAd.value = true;
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
            'assets/images/logo_vector.svg',
            height: 36,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.hostPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Guest Info',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'NURA',
                color: AppColors.hostPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spacingLg),

            // Nickname
            _buildLabel('Nickname'),

            TextField(
              controller: _nicknameController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Enter your nickname',
                hintStyle: GoogleFonts.alexandria(color: Colors.grey),
                errorText: _nicknameController.text.trim().isEmpty && _nicknameController.text.isNotEmpty 
                    ? 'Nickname cannot be empty' : null,
                suffixIcon: _nicknameController.text.trim().isNotEmpty 
                    ? const Icon(Icons.check_circle, color: Colors.green) 
                    : null,
                contentPadding: AppSpacing.inputContentPadding,
                // isDense: true, // Removed for standard height

                border: const OutlineInputBorder(),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.hostPrimary),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.hostPrimary, width: 2),
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.spacingLg),


            // Validation Message if Invalid
            if (!_isFormValid)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  '👆 Please enter your nickname to join',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Next Button
            Tooltip(
              message: _isFormValid ? 'Join Game' : 'Enter nickname first',
              child: AnimatedButton(
                onPressed: _isFormValid ? _onNextPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBD0558),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  fixedSize: const Size.fromHeight(AppSpacing.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: const Text(
                  'Join Room',
                  style: TextStyle(fontSize: AppSpacing.buttonFontSize, fontFamily: 'NURA', fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spacingMd),
            
            // Home Button
            AnimatedOutlinedButton(
               onPressed: () {
                  // Optional: Save before exit?
                  GameSession().updateGuestProfile(_nicknameController.text); 
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
               },
               style: OutlinedButton.styleFrom(
                 foregroundColor: AppColors.hostPrimary,
                 side: const BorderSide(color: AppColors.hostPrimary),
                 fixedSize: const Size.fromHeight(AppSpacing.buttonHeight),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
               ),

               child: const Text("HOME", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'NURA')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacingXs),

      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFFBD0558),
        ),
      ),
    );
  }
}
