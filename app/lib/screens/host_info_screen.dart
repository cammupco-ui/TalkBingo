import 'package:flutter/material.dart';
import 'package:talkbingo_app/widgets/animated_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talkbingo_app/screens/game_setup_screen.dart';
import 'package:talkbingo_app/screens/home_screen.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/utils/ad_state.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/screens/host_setup_screen.dart';
import 'package:talkbingo_app/styles/app_spacing.dart';
import 'package:talkbingo_app/utils/localization.dart';

class HostInfoScreen extends StatefulWidget {
  final bool isGameSetupFlow;

  const HostInfoScreen({super.key, this.isGameSetupFlow = false});

  @override
  State<HostInfoScreen> createState() => _HostInfoScreenState();
}

class _HostInfoScreenState extends State<HostInfoScreen> {
  final _nicknameController = TextEditingController();
  
  String? _selectedGender;
  bool get _isFormValid => _nicknameController.text.trim().isNotEmpty && _selectedGender != null;

  Future<void> _onNextPressed() async {
    if (_isFormValid) {
       final session = GameSession();
       session.hostNickname = _nicknameController.text;
       session.hostGender = _selectedGender;

      try {
        var user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          final authResponse = await Supabase.instance.client.auth.signInAnonymously();
          user = authResponse.user;
        }

        if (user != null) {
          String? genderCode;
          if (_selectedGender == 'Male') genderCode = 'M';
          if (_selectedGender == 'Female') genderCode = 'F';

          await Supabase.instance.client.from('profiles').upsert({
            'id': user.id,
            'nickname': _nicknameController.text,
            'gender': genderCode,
            'role': 'user', 
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
         debugPrint('Error saving profile: $e');
      }

      await session.saveHostInfoToPrefs();

      if (mounted) {
        if (widget.isGameSetupFlow) {
           Navigator.of(context).pushReplacement(
             MaterialPageRoute(builder: (_) => const HostSetupScreen()),
           );
        } else {
           Navigator.of(context).pushAndRemoveUntil(
             MaterialPageRoute(builder: (_) => const HomeScreen()),
             (route) => false,
           );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show Ad Banner on Host Info Screen
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
        iconTheme: const IconThemeData(color: Color(0xFFBD0558)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: AppSpacing.screenPadding,
          right: AppSpacing.screenPadding,
          top: AppSpacing.screenPadding,
          bottom: AppSpacing.screenPadding + 100, // Extra space for Ad Banner
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo removed - already in AppBar
            const SizedBox(height: 20),

            Text(
              AppLocalizations.get('main_player'),
              style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'NURA',
                color: AppColors.hostPrimary,
              )),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spacingLg),

            // Nickname
            _buildLabel(AppLocalizations.get('nickname')),

            TextField(
              controller: _nicknameController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: AppLocalizations.get('enter_nickname_hint'),
                hintStyle: GoogleFonts.alexandria(color: Colors.grey),
                errorText: _nicknameController.text.trim().isEmpty && _nicknameController.text.isNotEmpty 
                    ? AppLocalizations.get('nickname_validation') : null,
                suffixIcon: _nicknameController.text.trim().isNotEmpty 
                    ? const Icon(Icons.check_circle, color: Colors.green) 
                    : null,
                contentPadding: AppSpacing.inputContentPadding,
                isDense: false,
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
            const SizedBox(height: AppSpacing.spacingSm),

            // Gender
            _buildLabel(AppLocalizations.get('gender')),
            Row(
              children: [
                Expanded(child: _buildGenderButton(AppLocalizations.get('male'), 'Male')),
                const SizedBox(width: 16),
                Expanded(child: _buildGenderButton(AppLocalizations.get('female'), 'Female')),
              ],
            ),
            const SizedBox(height: AppSpacing.spacingLg),

            // Validation Message
            if (!_isFormValid)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  AppLocalizations.get('form_incomplete'),
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
              message: _isFormValid ? AppLocalizations.get('next') : AppLocalizations.get('form_incomplete'),
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
                child: Text(
                  AppLocalizations.get('next'),
                  style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(fontSize: AppSpacing.buttonFontSize, fontFamily: 'NURA', fontWeight: FontWeight.bold)),
                ),
              ),
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

  Widget _buildGenderButton(String label, String value) {
    final isSelected = _selectedGender == value;
    return InkWell(
      onTap: () => setState(() => _selectedGender = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: AppSpacing.inputHeight,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBD0558) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFFBD0558) : Colors.grey[400]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
