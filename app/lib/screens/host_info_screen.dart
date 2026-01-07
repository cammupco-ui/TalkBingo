import 'package:flutter/material.dart';
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
        print('Error saving profile to Supabase: $e');

        // Handle "Zombie Session" (User deleted from DB but App has Token)
        // Error 23503: insert or update on table "profiles" violates foreign key constraint "profiles_id_fkey"
        if (e.toString().contains('23503') || e.toString().contains('Key is not present in table "users"')) {
            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Session expired (User deleted). Signing out...'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                    ),
                );
            }
            await Supabase.instance.client.auth.signOut();
            if (mounted) {
                 Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                    (route) => false,
                 );
            }
            return;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving profile: $e')),
          );
        }
        return; // STOP HERE if save fails
      }

      await session.saveHostInfoToPrefs(); // Persist locally

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HostSetupScreen()),
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
                _buildGenderChip('Male', 'Male'),
                const SizedBox(width: 10),
                _buildGenderChip('Female', 'Female'),
              ],
            ),
            const SizedBox(height: 24),

            // Next Button
            ElevatedButton(
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

  Widget _buildGenderChip(String label, String value) {
    final isSelected = _selectedGender == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedGender = selected ? value : null),
      selectedColor: const Color(0xFFBD0558),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey),
      ),
    );
  }
}
