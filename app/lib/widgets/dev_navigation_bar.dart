import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:talkbingo_app/screens/signup_screen.dart';
import 'package:talkbingo_app/screens/host_setup_screen.dart';
import 'package:talkbingo_app/screens/host_info_screen.dart';
import 'package:talkbingo_app/screens/game_setup_screen.dart';
import 'package:talkbingo_app/screens/game_screen.dart';
import 'package:talkbingo_app/screens/home_screen.dart';
import 'package:talkbingo_app/screens/settings_screen.dart';
import 'package:talkbingo_app/screens/invite_code_screen.dart';
import 'package:talkbingo_app/screens/guest_info_screen.dart';
import 'package:talkbingo_app/screens/waiting_screen.dart';
import 'package:talkbingo_app/screens/reward_screen.dart'; // Import RewardScreen
import 'package:talkbingo_app/screens/point_purchase_screen.dart'; // Import PointPurchaseScreen
import 'package:talkbingo_app/main.dart'; // Import for navigatorKey

class DevNavigationBar extends StatelessWidget {
  const DevNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('DEV MODE:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              _buildNavButton(context, 'Home', const HomeScreen()),
              _buildNavButton(context, 'Settings', const SettingsScreen()),
              _buildNavButton(context, 'Signup', const SignupScreen()),
              _buildNavButton(context, 'Host Setup', const HostSetupScreen()),
              _buildNavButton(context, 'Host Info', const HostInfoScreen()),
              _buildNavButton(context, 'Game Setup', const GameSetupScreen()),
              _buildNavButton(context, 'Invite Code', const InviteCodeScreen()),
              _buildNavButton(context, 'Guest Info', const GuestInfoScreen()),
              _buildNavButton(context, 'Waiting', WaitingScreen()),
              _buildNavButton(context, 'Game', const GameScreen()),
              _buildNavButton(context, 'Reward', const RewardScreen()), // Add Reward Button
              _buildNavButton(context, 'Points', const PointPurchaseScreen()), // Add Points Button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, String label, Widget screen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 12),
        ),
        onPressed: () {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => screen),
          );
        },
        child: Text(label),
      ),
    );
  }
}
