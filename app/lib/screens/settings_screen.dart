import 'dart:math';
import 'package:flutter/material.dart';
import 'package:talkbingo_app/widgets/animated_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/utils/ad_state.dart';
import 'package:talkbingo_app/screens/sign_out_landing_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talkbingo_app/screens/home_screen.dart';
import 'package:talkbingo_app/screens/point_purchase_screen.dart';
import 'package:talkbingo_app/utils/migration_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkbingo_app/screens/splash_screen.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/styles/app_spacing.dart';
import 'package:talkbingo_app/utils/localization.dart';
import 'package:talkbingo_app/screens/signup_screen.dart';
import 'package:talkbingo_app/screens/profile_edit_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GameSession _session = GameSession(); 
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = "${info.version} (${info.buildNumber})";
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link.')),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.get('delete_account_title') ?? 'Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.get('delete_account_warning') ?? 'This action cannot be undone. All your data will be permanently deleted.'),
            const SizedBox(height: 10),
            const Text('Are you sure?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        // Best effort delete logic goes here
      } catch (e) {
        debugPrint("Delete error: $e");
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await Supabase.instance.client.auth.signOut();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      }
    }
  }
  
  Future<void> _launchFeedback() async {
     const url = 'https://docs.google.com/forms'; 
     final uri = Uri.parse(url);
     if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
     } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open feedback form.'))
           );
        }
     }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdState.showAd.value = false;
    });

    final bool isGuest = Supabase.instance.client.auth.currentSession?.user.isAnonymous ?? true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
        scrolledUnderElevation: 0, 
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingHorizontal, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Points Card
            _buildPointsOverview(),
            const SizedBox(height: 32),
            
            // 2. App Settings
            _buildSectionHeader(AppLocalizations.get('app_settings'), const Color(0xFFBD0558)), // Pink Header
            const SizedBox(height: 12),
            
            // Language Card
            _buildCard(
              child: Row(
                children: [
                  _buildLanguageChip('English', 'en'),
                  const SizedBox(width: 10),
                  _buildLanguageChip('한국어', 'ko'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Profile Card (Only for members)
            if (!isGuest)
              _buildCard(
                child: _buildSettingsTile(
                  icon: Icons.person_outline,
                  title: AppLocalizations.get('profile_settings'),
                  iconColor: const Color(0xFF6B14EC), // Purple
                  onTap: () {
                     Navigator.push(
                       context, 
                       MaterialPageRoute(builder: (_) => const ProfileEditScreen())
                     ).then((_) {
                        setState(() {}); 
                     });
                  },
                ),
              ),
            
            const SizedBox(height: 32),

             // 3. Support & Info Section
            _buildSectionHeader(AppLocalizations.get('support_info') ?? 'Customer Support & Info', const Color(0xFFBD0558)), // Pink Header
            const SizedBox(height: 12),
            
            // Info Card
            _buildCard(
              child: Column(
                children: [
                  // How to Play Bingo
                  _buildSettingsTile(
                    icon: Icons.help_outline,
                    title: '빙고 플레이 방법 (How to Play)',
                    iconColor: const Color(0xFFFFA000), // Amber/Orange
                    onTap: () => _launchUrl('https://cammupco-ui.github.io/TalkBingo/guide_bingo.html'), 
                  ),
                  const Divider(height: 24, thickness: 0.5),

                  // How to Use Points
                  _buildSettingsTile(
                    icon: Icons.monetization_on_outlined,
                    title: '포인트 사용 방법 (Points Guide)',
                    iconColor: const Color(0xFFFFA000), // Amber/Orange
                    onTap: () => _launchUrl('https://cammupco-ui.github.io/TalkBingo/guide_points.html'), 
                  ),
                  const Divider(height: 24, thickness: 0.5),

                  // Terms of Service
                  _buildSettingsTile(
                    icon: Icons.description_outlined,
                    title: AppLocalizations.get('terms_of_service') ?? 'Terms of Service',
                    iconColor: const Color(0xFF68CDFF), // Blue
                    onTap: () => _launchUrl('https://cammupco-ui.github.io/TalkBingo/terms.html'), 
                  ),
                  
                  // Privacy Policy
                  _buildSettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: AppLocalizations.get('privacy_policy') ?? 'Privacy Policy',
                    iconColor: const Color(0xFF68CDFF), // Blue
                    onTap: () => _launchUrl('https://cammupco-ui.github.io/TalkBingo/privacy.html'), 
                  ),
                  const Divider(height: 24, thickness: 0.5),

                  // License & Version (Merged)
                  _buildSettingsTile(
                    icon: Icons.info_outline,
                    title: '${AppLocalizations.get('licenses') ?? 'Licenses'} / v$_appVersion',
                    iconColor: Colors.grey, 
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Theme(
                            data: Theme.of(context).copyWith(
                              textTheme: const TextTheme(
                                headlineMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), 
                                titleLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), 
                                titleMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                titleSmall: TextStyle(fontSize: 10, color: Colors.white70),
                                bodyMedium: TextStyle(fontSize: 9, fontFamily: 'Courier', color: Colors.white70),
                                bodySmall: TextStyle(fontSize: 8, color: Colors.white60),
                              ),
                              scaffoldBackgroundColor: const Color(0xFF121212), 
                              cardColor: const Color(0xFF1E1E1E),
                              appBarTheme: const AppBarTheme(
                                backgroundColor: Color(0xFF121212),
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                            ),
                            child: LicensePage(
                              applicationName: 'TalkBingo',
                              applicationVersion: _appVersion,
                              applicationIcon: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SvgPicture.asset('assets/images/Logo Vector.svg', height: 48),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
             const SizedBox(height: 16),

             // Action Card (Contact & Delete)
             _buildCard(
               child: Column(
                 children: [
                    // Board (Feedback)
                    _buildSettingsTile(
                      icon: Icons.forum_outlined,
                      title: '게시판 (Board)',
                      iconColor: const Color(0xFFBD0558), // Pink
                      onTap: () => _launchUrl('https://example.com/board'), // TODO: Update with actual Board URL
                    ),
                    
                    // Delete Account
                    if (!isGuest) ...[
                      const Divider(height: 24, thickness: 0.5),
                       _buildSettingsTile(
                        icon: Icons.delete_forever,
                        title: AppLocalizations.get('delete_account') ?? 'Delete Account',
                        textColor: Colors.red,
                        iconColor: Colors.red,
                        onTap: _deleteAccount,
                      ),
                    ]
                 ],
               )
             ),
             
            const SizedBox(height: 32),

            // Conditional Button: Sign Up (Guest) vs Sign Out (Member)
            if (isGuest)
              SizedBox(
                width: double.infinity,
                child: AnimatedButton(
                  onPressed: () async {
                    await MigrationManager().prepareForMigration();
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SignupScreen()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.hostPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.login, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.get('sign_up_google'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: AnimatedOutlinedButton(
                  onPressed: () async {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignOutLandingScreen())
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black, width: 1), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    AppLocalizations.get('sign_out'),
                    style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),

             // Debug Reset
             if (isGuest)
               Padding(
                 padding: const EdgeInsets.only(top: 20),
                 child: TextButton(
                   onPressed: () async {
                     final prefs = await SharedPreferences.getInstance();
                     await prefs.clear();
                     await Supabase.instance.client.auth.signOut();
                     if (context.mounted) {
                       Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                     }
                   },
                   child: const Text("Reset Data (Debug)", style: TextStyle(color: Colors.red)),
                 ),
               ),

             const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---
  
  Widget _buildSectionHeader(String title, Color barColor) {
    return Row(
      children: [
        Container(
          width: 4, 
          height: 18, 
          decoration: BoxDecoration(
            color: barColor, 
            borderRadius: BorderRadius.circular(2)
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black, // Dark text for header
            fontFamily: 'NURA', 
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          )
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: child,
    );
  }

  Widget _buildSettingsTile({
    required IconData icon, 
    required String title, 
    required VoidCallback onTap, 
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.black54).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? Colors.black54, size: 20),
      ),
      title: Text(title, style: TextStyle(color: textColor ?? Colors.black87, fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      dense: true,
      minLeadingWidth: 0, // Reduces gap
    );
  }
  
  // Kept _buildPointsOverview and _buildScoreItem and _buildLanguageChip unchanged functionally but will verify their placement in context.
  // Actually, I need to include them in the replacement content to ensure the class is complete if I am replacing the whole class.
  // I'll grab them from the original file content provided in Step 858.

  Widget _buildPointsOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      // Dark Background #0C0219
      decoration: BoxDecoration(
        color: const Color(0xFF0C0219),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreItem("VP", _session.vp, isVP: true),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildScoreItem("AP", _session.ap), 
              Container(width: 1, height: 40, color: Colors.white30),
              _buildScoreItem("EP", _session.ep), 
            ],
          ),
          const SizedBox(height: 24),
          // Manage Button (Outlined)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: AnimatedOutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PointPurchaseScreen())
                ).then((_) => setState(() {})); 
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 0.5), // Thin Outline
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.get('manage_points'), 
                    style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, int score, {bool isVP = false, VoidCallback? onExchange, String? tooltip}) {
    return Column(
      children: [
        // Score with Animation
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: score),
          duration: const Duration(seconds: 2), // Slower animation (2s)
          builder: (context, value, child) {
             final isAnimating = value != score;
             return Text(
               value.toString(), 
               style: GoogleFonts.alexandria(
                 fontSize: 24, 
                 fontWeight: FontWeight.bold, 
                 color: isAnimating ? Colors.greenAccent : Colors.white // Highlight change
               )
             );
          },
        ),
        const SizedBox(height: 4),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.alexandria(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildLanguageChip(String label, String value) {
    // Current Language from Session
    final currentLang = _session.language;
    final isSelected = currentLang == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
             _session.setLanguage(value);
          });
        },
        child: Container(
          height: AppSpacing.toggleButtonHeight, // Slightly taller for settings
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.hostPrimary : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
            border: Border.all(
              color: isSelected ? AppColors.hostPrimary : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: value == 'en' 
                ? GoogleFonts.alexandria(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black87,
                  )
                : TextStyle(
                    fontFamily: 'EliceDigitalBaeum',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
          ),
        ),
      ),
    );
  }
}
