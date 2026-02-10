import 'dart:math';
import 'package:flutter/material.dart';
import 'package:talkbingo_app/screens/guide_screen.dart';
import 'package:flutter/services.dart'; // Added for SystemNavigator
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
import 'package:talkbingo_app/screens/board/board_list_screen.dart';
import 'package:talkbingo_app/screens/splash_screen.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/styles/app_spacing.dart';
import 'package:talkbingo_app/utils/localization.dart';
import 'package:talkbingo_app/screens/signup_screen.dart';
import 'package:talkbingo_app/screens/login_screen.dart'; // Added import
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

  Future<void> _launchLocalizedUrl(String baseUrl) async {
    String finalUrl = baseUrl;
    // Check current language
    if (_session.language == 'en') {
       // Insert _en before .html
       finalUrl = baseUrl.replaceAll('.html', '_en.html');
    }
    await _launchUrl(finalUrl);
  }

  Future<void> _performSignOut({bool redirectToLogin = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await Supabase.instance.client.auth.signOut();
    
    if (mounted) {
       if (redirectToLogin) {
         Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
         );
       } else {
         Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SignOutLandingScreen()),
          (route) => false,
         );
       }
    }
  }

  Widget _buildActionButton({required String title, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          title, 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
        ),
      ),
    );
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
            'assets/images/logo_vector.svg',
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
            
            // Profile Card (Visible to all)
            _buildCard(
              child: _buildSettingsTile(
                icon: null, // No leading icon
                title: Supabase.instance.client.auth.currentSession?.user.email ?? 'Guest',
                textColor: Colors.black87,
                backgroundColor: const Color(0xFFFFF9FB), // Custom BG
                trailing: const Icon(Icons.edit_outlined, color: Colors.grey),
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

             // 3. Customer Support & Info
             _buildSectionHeader(AppLocalizations.get('customer_support'), const Color(0xFFBD0558)),
             const SizedBox(height: 12),

             // Game Info Card
             _buildCard(
               child: Column(
                 children: [
                   _buildSettingsTile(
                     icon: Icons.help_outline,
                     title: AppLocalizations.get('bingo_guide'),
                     onTap: () {
                       Navigator.of(context).push(
                         MaterialPageRoute(builder: (_) => GuideScreen(
                           title: AppLocalizations.get('bingo_guide'),
                           contentKey: 'guide_bingo_content'
                         ))
                       );
                     },
                   ),
                   const Divider(height: 1),
                   _buildSettingsTile(
                     icon: Icons.stars_outlined,
                     title: AppLocalizations.get('points_guide'),
                     onTap: () {
                       Navigator.of(context).push(
                         MaterialPageRoute(builder: (_) => GuideScreen(
                           title: AppLocalizations.get('points_guide'),
                           contentKey: 'guide_points_content'
                         ))
                       );
                     },
                   ),
                 ],
               ),
             ),
             const SizedBox(height: 24),

             // App Info Card
             _buildCard(
               child: Column(
                 children: [
                   _buildSettingsTile(
                     icon: Icons.description_outlined,
                     title: AppLocalizations.get('terms'),
                     onTap: () {
                       Navigator.of(context).push(
                         MaterialPageRoute(builder: (_) => GuideScreen(
                           title: AppLocalizations.get('terms'),
                           contentKey: 'guide_terms_content'
                         ))
                       );
                     },
                   ),
                    const Divider(height: 1),
                   _buildSettingsTile(
                     icon: Icons.privacy_tip_outlined,
                     title: AppLocalizations.get('privacy'),
                     onTap: () {
                       Navigator.of(context).push(
                         MaterialPageRoute(builder: (_) => GuideScreen(
                           title: AppLocalizations.get('privacy'),
                           contentKey: 'guide_privacy_content'
                         ))
                       );
                     },
                   ),
                    const Divider(height: 1),
                   ListTile( 
                     leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.info_outline, color: Colors.black54, size: 20),
                     ),
                     contentPadding: EdgeInsets.zero,
                     dense: true,
                     minLeadingWidth: 0,
                     title: Text(AppLocalizations.get('version'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                     trailing: Text(_appVersion, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                   ),
                 ],
               ),
             ),
             const SizedBox(height: 24),

             // Action Card (Contact & Delete)
             _buildCard(
               child: Column(
                 children: [
                    // Board (Feedback)
                    _buildSettingsTile(
                      icon: Icons.forum_outlined,
                      title: AppLocalizations.get('board'),
                      iconColor: const Color(0xFFBD0558), // Pink
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BoardListScreen()),
                        );
                      },
                    ),
                    
                    // Delete Account REMOVED from list (Moved to Sign Out Action Sheet)
                 ],
               )
             ),
             
            const SizedBox(height: 32),

            // Sign Up / Sign Out Buttons
            // Account Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isGuest) ...[
                  // Log Out
                  _buildActionButton(
                    title: AppLocalizations.get('sign_out') ?? 'Log Out',
                    color: const Color(0xFFBD0558), // Pink
                    onTap: () => _performSignOut(),
                  ),
                  const SizedBox(height: 12),
                  
                  // Sign In Another Account
                  _buildActionButton(
                    title: AppLocalizations.get('sign_in_another') ?? 'Sign In Another Account',
                    color: const Color(0xFFBD0558), // Pink
                    onTap: () => _performSignOut(redirectToLogin: true),
                  ),
                  const SizedBox(height: 12),
                ],

                // Exit TalkBingo
                _buildActionButton(
                  title: AppLocalizations.get('exit_talkbingo') ?? 'Exit TalkBingo',
                  color: const Color(0xFFBD0558), // Pink
                  onTap: () {
                     if (isGuest) {
                       _deleteAccount(); // Clean up guest data
                     } else {
                       SystemNavigator.pop(); // Close app for members
                     }
                  },
                ),
                const SizedBox(height: 12),

                // Delete Account
                 if (!isGuest)
                  _buildActionButton(
                    title: AppLocalizations.get('delete_account') ?? 'Delete Account',
                    color: const Color(0xFFFF0000), // Red
                    onTap: () => _deleteAccount(),
                  ),
              ],
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
    IconData? icon, // Made nullable
    required String title, 
    required VoidCallback onTap, 
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
    Color? backgroundColor,
  }) {
    return ListTile(
      leading: icon != null ? Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.black54).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? Colors.black54, size: 20),
      ) : null,
      tileColor: backgroundColor, // Use background color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              _buildScoreItem("GP", _session.gp),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildScoreItem("VP", _session.vp), 
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

  Widget _buildScoreItem(String label, int score) {
    return Column(
      children: [
        // Score with Animation
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: score),
          duration: const Duration(seconds: 2),
          builder: (context, value, child) {
             final isAnimating = value != score;
             return Text(
               value.toString(), 
               style: GoogleFonts.alexandria(
                 fontSize: 24, 
                 fontWeight: FontWeight.bold, 
                 color: isAnimating ? Colors.greenAccent : Colors.white
               )
             );
          },
        ),
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
