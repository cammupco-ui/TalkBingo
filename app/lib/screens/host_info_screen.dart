import 'package:flutter/material.dart';
import 'package:talkbingo_app/widgets/animated_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talkbingo_app/utils/ad_state.dart';
import 'package:talkbingo_app/screens/game_setup_screen.dart';
import 'package:talkbingo_app/screens/home_screen.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/screens/game_screen.dart';
import 'package:talkbingo_app/screens/host_setup_screen.dart';
import 'package:talkbingo_app/screens/signup_screen.dart'; // Added for auto-logout redirect

import 'package:talkbingo_app/utils/dev_config.dart';

class HostInfoScreen extends StatefulWidget {
  const HostInfoScreen({super.key});

  @override
  State<HostInfoScreen> createState() => _HostInfoScreenState();
}

class _HostInfoScreenState extends State<HostInfoScreen> {
  final _nicknameController = TextEditingController();
  String? _selectedGender;
  
  @override
  void initState() {
    super.initState();
    if (DevConfig.isDevMode.value) {
      _nicknameController.text = 'Anna';
      _selectedGender = 'Female';
    }
  }

  bool get _isFormValid {
    return _nicknameController.text.isNotEmpty &&
        _selectedGender != null;
  }

  Future<void> _onNextPressed() async {
    if (_isFormValid) {
      final session = GameSession();
      session.hostNickname = _nicknameController.text;
      session.hostGender = _selectedGender;

      // Save to Supabase Profiles Table
      try {
        var user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          // Ensure we have a user account (Anonymously)
          final authResponse = await Supabase.instance.client.auth.signInAnonymously();
          user = authResponse.user;
        }

        if (user != null) {
          // Map Gender String to Enum Code
          String? genderCode;
          if (_selectedGender == 'Male') genderCode = 'M';
          if (_selectedGender == 'Female') genderCode = 'F';

          await Supabase.instance.client.from('profiles').upsert({
            'id': user.id,
            'nickname': _nicknameController.text,
            'gender': genderCode, // DB Column: gender (ENUM 'M', 'F')
            'role': 'user', 
            'updated_at': DateTime.now().toIso8601String(),
          });
          print('Host Info Saved to Supabase: ${session.hostNickname} (ID: ${user.id})');
        } else {
           print('Warning: Failed to sign in, saving locally only.');
        }
      } catch (e) {
        debugPrint('Error saving profile to Supabase: $e');

        if (mounted) {
           showDialog(
             context: context,
             builder: (ctx) => AlertDialog(
               title: const Text("Profile Save Error"),
               content: SingleChildScrollView(
                 child: Text("Details: $e\n\nUser ID: ${Supabase.instance.client.auth.currentUser?.id}"),
               ),
               actions: [
                 TextButton(
                   onPressed: () => Navigator.of(ctx).pop(),
                   child: const Text("OK"),
                 ),
                 // Temporary Bypass Button for testing
                 TextButton(
                   onPressed: () async {
                      Navigator.of(ctx).pop();
                      await session.saveHostInfoToPrefs();
                      if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (route) => false,
                          );
                      }
                   },
                   child: const Text("Force Skip (Local Only)", style: TextStyle(color: Colors.red)),
                 )
               ],
             ),
           );
        }
        return; 
      }

      await session.saveHostInfoToPrefs(); // Persist locally

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show Ad on Host Info Screen
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
            'assets/images/Logo Vector.svg',
            height: 36,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFBD0558)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'MainPlayer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'NURA',
                color: AppColors.hostPrimary, // Was 0xFFBD0558
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

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
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                isDense: true,
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
            const SizedBox(height: 12),

            // Gender
            _buildLabel('Gender'),
            Row(
              children: [
                Expanded(child: _buildGenderButton('Male', 'Male')),
                const SizedBox(width: 16),
                Expanded(child: _buildGenderButton('Female', 'Female')),
              ],
            ),
            const SizedBox(height: 24),

            // Validation Message if Invalid
            if (!_isFormValid)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  '👆 Please enter nickname and select gender',
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
              message: _isFormValid ? 'Continue' : 'Complete the form first',
              child: AnimatedButton(
                onPressed: _isFormValid ? _onNextPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBD0558),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  fixedSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(fontSize: 14, fontFamily: 'NURA', fontWeight: FontWeight.bold),
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
      padding: const EdgeInsets.only(bottom: 8.0),
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
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBD0558) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFFBD0558) : Colors.grey[400]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
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
