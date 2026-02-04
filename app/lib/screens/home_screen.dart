import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:talkbingo_app/widgets/animated_button.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talkbingo_app/utils/ad_state.dart';
import 'package:talkbingo_app/screens/host_setup_screen.dart'; // Ensure this is present
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/screens/host_info_screen.dart'; // Added import
import 'package:talkbingo_app/screens/game_screen.dart';
import 'package:talkbingo_app/screens/settings_screen.dart';
import 'package:talkbingo_app/widgets/game_history_item.dart';
import 'package:talkbingo_app/screens/bingo_history_screen.dart';
import 'package:talkbingo_app/screens/invite_code_screen.dart'; // Still useful if we want to reuse logic, but here we inline
import 'package:talkbingo_app/screens/point_purchase_screen.dart';
import 'package:talkbingo_app/screens/notice_screen.dart';
import 'package:talkbingo_app/models/notice.dart';

import 'package:talkbingo_app/screens/game_setup_screen.dart';
import 'package:talkbingo_app/utils/localization.dart'; // Localization
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _inviteCodeController = TextEditingController();
  final GameSession _session = GameSession();
  bool _showSignupNudge = false;

  
  @override
  void initState() {
    super.initState();
    // Ensure transparent status bar for full-screen background
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, 
    ));

    _loadHostInfo();
    
    // Defer UI logic to after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _checkInitialFlows();
    });
  }

  Future<void> _checkInitialFlows() async {
    // 1. Fast Track Join (Deep Link)
    String? code = GameSession().pendingInviteCode;

    // Persistence Check (Fallback)
    if (code == null) {
       final prefs = await SharedPreferences.getInstance();
       code = prefs.getString('pending_invite_code');
       if (code != null) {
          debugPrint("💾 Valid Code recovered from Storage: $code");
          // Do NOT clear immediately. Persist until explicit join or manual clear.
          // await prefs.remove('pending_invite_code'); 
       }
    }

    // Safety Validation (Double Check)
    if (code != null && (code.length != 6 || !RegExp(r'^[A-Z0-9]+$', caseSensitive: false).hasMatch(code))) {
       debugPrint("⚠️ HomeScreen: Invalid Pending Code detected and cleared: $code");
       code = null;
       GameSession().pendingInviteCode = null;
    }

    if (code != null) {
      GameSession().pendingInviteCode = null; // Clear memory
      
      _inviteCodeController.text = code;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(AppLocalizations.get('join_game'), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text("Guest Mode로 참여하시겠습니까?\n(코드: $code)"), // TODO: Localize
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.get('cancel'), style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final nav = Navigator.of(context);
                nav.pop(); // Close Dialog
                
                // Clear prefs in background (fire & forget, or await if needed but don't block UI)
                SharedPreferences.getInstance().then((prefs) {
                   prefs.remove('pending_invite_code');
                });

                nav.push(
                   MaterialPageRoute(builder: (_) => InviteCodeScreen(initialCode: code)),
                );
              },
              child: Text(AppLocalizations.get('join'), style: const TextStyle(color: AppColors.hostPrimary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return; // Prioritize Game Join over Nudge
    }

    // 2. Conversion Nudge (Returning Guest)
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.isAnonymous) {
       setState(() {
         _showSignupNudge = true;
       });
    }
  }

  Future<void> _loadHostInfo() async {
    final session = GameSession();
    if (session.hostNickname == null) {
      await session.loadHostInfoFromPrefs();
      if (mounted) setState(() {});
    }
  }
  
  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  void _showFullHistory() {
     Navigator.of(context).push(
       MaterialPageRoute(builder: (_) => const BingoHistoryScreen()),
     );
  }

  Widget _buildNavHub(Color accentColor) {
    // Layout based on 516x380 Design Specs
    const designWidth = 516.0;
    const designHeight = 380.0;
    
    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: designWidth,
          height: designHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Background Frame
              Positioned.fill(
                child: SvgPicture.asset(
                  'assets/images/HomeMainButton.svg',
                  fit: BoxFit.contain,
                ),
              ),
              
              // 2. Center Button (HomeMainButton2.svg)
              // Text "NEW GAME" is baked into SVG, so we remove the Text overlay.
              Positioned.fill(
                child: _AnimatedSvgButton(
                   assetPath: 'assets/images/HomeMainButton2.svg',
                   label: AppLocalizations.get('new_game'),
                   width: designWidth,
                   height: designHeight,
                   onTap: () {
                     // Helper to check profile
                     void startNewGame() {
                       final session = GameSession();
                       if (session.hostNickname == null || session.hostNickname!.isEmpty) {
                          // Redirect to Profile Setup first
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HostInfoScreen(isGameSetupFlow: true))
                          );
                       } else {
                          // Proceed to Game Setup
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HostSetupScreen()));
                       }
                     }

                     if (GameSession().isGameActive) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Text(AppLocalizations.get('start_new_game'), style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                            content: Text(AppLocalizations.get('start_new_warning'), style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(color: Colors.black87))),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context), 
                                child: Text(AppLocalizations.get('cancel'), style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(color: Colors.black54)))
                              ),
                              TextButton(
                                onPressed: () {
                                  GameSession().reset();
                                  Navigator.pop(context);
                                  startNewGame(); // Use helper
                                },
                                child: Text(AppLocalizations.get('start_new'), style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(color: Colors.red))),
                              ),
                            ],
                          ),
                        );
                     } else {
                       startNewGame(); // Use helper
                     }
                   },
                ),
              ),

              // 3. Touch Targets (Ghost Buttons over text areas)
              // Text is baked into SVG. We just keep the GestureDetector areas.
              
              // Resume Game (Top Left Quadrant)
              Positioned(
                left: 55, top: 10,
                width: 160, height: 140,
                child: _InteractiveTextButton(
                  text: AppLocalizations.get('resume_game'),
                  isActive: true, // Always allow interaction to show hover effect
                  onTap: () {
                    if (GameSession().isGameActive) {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GameScreen()));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.get('no_active_game')),
                          duration: const Duration(seconds: 1),
                          backgroundColor: Colors.grey,
                        ),
                      );
                    }
                  },
                  fontSize: 18,
                  width: 160,
                  height: 140,
                ),
              ),

              // Find Players (Bottom Right Quadrant)
              Positioned(
                right: 55, bottom: 10,
                width: 160, height: 140,
                child: _InteractiveTextButton(
                  text: AppLocalizations.get('find_players'),
                  isActive: true, 
                  textColor: Colors.white60, // Visible but dimmed
                  fontSize: 16,
                  width: 160,
                  height: 140,
                  onTap: () {
                     showDialog(
                       context: context,
                       builder: (context) => AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Text(AppLocalizations.get('coming_soon'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          content: Text(AppLocalizations.get('service_unavailable'), style: const TextStyle(color: Colors.black87)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context), 
                              child: const Text("OK", style: TextStyle(color: AppColors.hostPrimary, fontWeight: FontWeight.bold))
                            )
                          ],
                       ),
                     );
                  },
                ),
              ),
              
              // Welcome Text (Bottom Left Area) with Animation
              Positioned(
                left: 80, bottom: 20, 
                width: 220, // Constrain width to fill left quadrant for alignment
                child: _WelcomeMessage(nickname: _session.hostNickname ?? "Guest"),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Method to build the main Screen body (now transparent to show BG)
  // We need to wrap the whole scaffold body in the new Background Widget?
  // Refactoring usage in build() later.
  
// ... (omitted methods) ...

  @override
  Widget build(BuildContext context) {
    // Ad logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // AdState.showAd.value = true;
    });

    final hostPrimary = const Color(0xFFF6005E); 

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0918), // Dark base to prevent white flashes
        extendBodyBehindAppBar: true, 
        body: Stack(
        children: [
          // 1. Animated Aurora Background
          const Positioned.fill(child: _AnimatedAuroraBackground()),
          
           // 2. Main Content
          SafeArea(
             child: SingleChildScrollView(
               padding: const EdgeInsets.only(left: 12.0, top: 12.0, right: 12.0, bottom: 80.0), // Adjusted for 64px Ad
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: [
                   // Conversion Nudge Banner
                   if (_showSignupNudge)
                     Container(
                       margin: const EdgeInsets.only(bottom: 16),
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                       decoration: BoxDecoration(
                         color: AppColors.hostPrimary.withOpacity(0.9),
                         borderRadius: BorderRadius.circular(12),
                         boxShadow: [
                           BoxShadow(
                             color: Colors.black.withOpacity(0.2),
                             blurRadius: 8,
                             offset: const Offset(0, 4),
                           )
                         ],
                       ),
                       child: Row(
                         children: [
                           const Icon(Icons.stars, color: Colors.amber, size: 24),
                           const SizedBox(width: 12),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   "포인트 적립과 기록 보존!",
                                   style: GoogleFonts.alexandria(
                                     color: Colors.white,
                                     fontWeight: FontWeight.bold,
                                     fontSize: 14,
                                   ),
                                 ),
                                 Text(
                                   "계정을 등록하고 혜택을 받으세요.",
                                   style: GoogleFonts.alexandria(
                                     color: Colors.white.withOpacity(0.9),
                                     fontSize: 12,
                                   ),
                                 ),
                               ],
                             ),
                           ),
                           TextButton(
                             onPressed: () {
                               Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                               );
                             },
                             style: TextButton.styleFrom(
                               backgroundColor: Colors.white,
                               foregroundColor: AppColors.hostPrimary,
                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                               minimumSize: Size.zero,
                               tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                             ),
                             child: const Text("등록", style: TextStyle(fontWeight: FontWeight.bold)),
                           ),
                           const SizedBox(width: 8),
                           InkWell(
                             onTap: () => setState(() => _showSignupNudge = false),
                             child: const Icon(Icons.close, color: Colors.white70, size: 20),
                           ),
                         ],
                       ),
                     ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.5, end: 0),

                    // --- Custom Header ---
                    // Row 1: Logo
                    const Center(
                      child: Text(
                        "TALKBINGO",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30, // Reduced from 40
                          fontWeight: FontWeight.w900,
                          fontFamily: 'NURA',
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Row 2: Icons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           // Left: Notification
                           GestureDetector(
                            onTap: () async {
                               await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NoticeScreen()));
                               if (mounted) setState(() {});
                            },
                            child: Badge(
                              isLabelVisible: NoticeRepository().unreadCount > 0,
                              label: Text('${NoticeRepository().unreadCount}'),
                              backgroundColor: const Color(0xFFF6005E),
                              child: SvgPicture.asset(
                                'assets/images/Notice.svg', 
                                width: 16, height: 16, // Reduced from 24
                                colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                              ),
                            ),
                          ),
                          
                          // Right: VP + Language + Settings
                          Row(
                             children: [
                                // VP Display
                                InkWell(
                                   onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PointPurchaseScreen())),
                                   child: Row(
                                     children: [
                                       Text("${AppLocalizations.get('vp_label')} ${_session.vp}", style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13))),
                                       const SizedBox(width: 8),
                                       SvgPicture.asset(
                                         'assets/images/PointPlus.svg', 
                                         width: 16, height: 16, 
                                         colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                                       ),
                                     ],
                                   ),
                                 ),
                                 const SizedBox(width: 16),
                                 
                                 // Language Toggle (EN / KR)
                                 GestureDetector(
                                    onTap: () {
                                      final newLang = _session.language == 'en' ? 'ko' : 'en';
                                      setState(() {
                                        _session.setLanguage(newLang);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.withOpacity(0.5)),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _session.language.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ),
                                 ),
                                 const SizedBox(width: 12),
                                 
                                 // Settings Icon
                                 GestureDetector(
                                   onTap: () async {
                                     await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
                                     if (mounted) setState(() {}); // Refresh UI (e.g. nickname) on return
                                   },
                                   child: SvgPicture.asset(
                                     'assets/images/Setting.svg', 
                                     width: 18, height: 18, // Slightly Larger
                                     colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                                   ),
                                 ),
                             ],
                          ),
                        ],
                      ),
                    ),
                    // ---------------------
                    
                    const SizedBox(height: 20),
                    _buildNavHub(AppColors.hostPrimary),
                    const SizedBox(height: 30),
                    _buildJoinSection(AppColors.playerA),
                    const SizedBox(height: 20),
                    _buildHistorySection(),
                 ],
               ),
             ),
          ),
        ],
      ),
      ),
    );
  }

// ... helper widgets ...

  Widget _buildJoinSection(Color accentColor) {
    return Column(
      children: [
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(color: accentColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
            ]
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12), // Adjusted padding
          child: Row(
             children: [
               // Removed Key Icon
               Expanded(
                 child: TextField(
                   controller: _inviteCodeController,
                   style: GoogleFonts.sourceCodePro(
                      fontSize: 14, 
                      fontWeight: FontWeight.bold,
                      color: Colors.black87
                   ), 
                   decoration: InputDecoration(
                     hintText: AppLocalizations.get('enter_invite_placeholder'),
                     border: InputBorder.none,
                     hintStyle: GoogleFonts.alexandria(fontSize: 12, color: Colors.grey[500]),
                     isDense: true,
                     contentPadding: EdgeInsets.zero,
                   ),
                 ),
               ),
               // Removed Paste Button
               
               // Divider
               Container(width: 1, height: 24, color: Colors.grey[300]),
               const SizedBox(width: 8),
               
               // Join Button (Vivid Color)
               AnimatedTextButton(
                 onPressed: () {
                   if (_inviteCodeController.text.length >= 2) {
                       Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => InviteCodeScreen(initialCode: _inviteCodeController.text)),
                       );
                   }
                 },
                 style: TextButton.styleFrom(
                   foregroundColor: const Color(0xFFF6005E), // Vivid Pink
                   padding: const EdgeInsets.symmetric(horizontal: 16),
                 ),
                  child: Text(
                    AppLocalizations.get('join'), 
                    style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'NURA', fontSize: 16)
                  ),
               )
             ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.get('bingo_history'), style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w600))),
              TextButton(
                onPressed: _showFullHistory,
                child: Text(AppLocalizations.get('view_all'), style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600))),
              )
            ],
          ),
        ),
        
        // List Container (Layered Design)
        Container(
          height: 280, // Fixed height for scrolling
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFE0E0E0).withOpacity(0.1), 
                const Color(0xFFBDBDBD).withOpacity(0.1)
              ], 
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Scrollable List
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _session.fetchGameHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                     return const Center(child: Text("No game history yet.", style: TextStyle(color: Colors.black54)));
                  }
                  
                  final games = snapshot.data!;
                  
                  return ListView.separated(
                    padding: const EdgeInsets.only(top: 10, bottom: 180), // Increased padding to clear ads
                    itemCount: games.length,
                    separatorBuilder: (context, index) => const Divider(color: Colors.black12, height: 1, indent: 20, endIndent: 20),
                    itemBuilder: (context, index) {
                      return GameHistoryItem(game: games[index]);
                    },
                  );
                },
              ),
              
              // Dimming Gradient at Bottom (Stronger Fade)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 180, // Increased height
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFF1E0A2D).withOpacity(1.0), // Fade to Dark Background
                        const Color(0xFF1E0A2D).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



}


class _AnimatedSvgButton extends StatefulWidget {
  final String assetPath;
  final String label;
  final double width;
  final double height;
  final VoidCallback onTap;

  const _AnimatedSvgButton({
    super.key,
    required this.assetPath,
    required this.label,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  State<_AnimatedSvgButton> createState() => _AnimatedSvgButtonState();
}

class _AnimatedSvgButtonState extends State<_AnimatedSvgButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;



  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _controller.reverse(),
        onTapUp: (_) {
          _controller.forward();
          widget.onTap();
        },
        onTapCancel: () => _controller.forward(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SvgPicture.asset(
                  widget.assetPath,
                  width: widget.width,
                  height: widget.height,
                  fit: BoxFit.fill,
                ),
                _InteractiveTextButton(
                  text: widget.label,
                  onTap: widget.onTap,
                  textColor: Colors.black,
                  fontSize: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedAuroraBackground extends StatefulWidget {
  const _AnimatedAuroraBackground();

  @override
  State<_AnimatedAuroraBackground> createState() => _AnimatedAuroraBackgroundState();
}

class _AnimatedAuroraBackgroundState extends State<_AnimatedAuroraBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Colors from User: "Angular Gradient" scheme
  // #2E0645 (Deep Purple), #0F0918 (Dark), #610C39 (Magenta)
  final Color cPurple = const Color(0xFF2E0645);
  final Color cDark = const Color(0xFF0F0918);
  final Color cMagenta = const Color(0xFF610C39);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // Faster animation (was 10)
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cDark, // Base background
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Organic movement simulation
          final t = _controller.value;
          return Stack(
            children: [
              // 1. Moving Purple Orb
              Positioned(
                top: -100 + (100 * t), // Increased range
                left: -100 + (60 * t),
                width: 600,
                height: 600,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [cPurple.withOpacity(0.6), Colors.transparent],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
              ),
              
              // 2. Moving Magenta Orb (Opposite corner)
              Positioned(
                bottom: -150 + (120 * t), // Increased range
                right: -50 + (80 * t),
                width: 700,
                height: 700,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [cMagenta.withOpacity(0.5), Colors.transparent],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
              ),

              // 3. Central Deep Orb (Breathing)
              Align(
                alignment: Alignment(0.4 * t, -0.6 * t), // Increased movement
                child: Container(
                  width: 500 + (200 * t), // Increased sizing
                  height: 500 + (200 * t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [cPurple.withOpacity(0.4), Colors.transparent],
                      stops: const [0.0, 0.8],
                    ),
                  ),
                ),
              ),
              
              // 4. Mesh/Overlay for texture (optional, keeping clean for now)
            ],
          );
        },
      ),
    );
  }
}

class _WelcomeMessage extends StatefulWidget {
  final String nickname;
  const _WelcomeMessage({super.key, required this.nickname});

  @override
  State<_WelcomeMessage> createState() => _WelcomeMessageState();
}

class _WelcomeMessageState extends State<_WelcomeMessage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity1;
  late Animation<double> _opacity2;
  late Animation<Offset> _slide1;
  late Animation<Offset> _slide2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Slow motion effect
    );

    // "Welcome Back," appears 0.0 -> 0.6
    _opacity1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _slide1 = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    // Nickname appears 0.4 -> 1.0
    _opacity2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );
    _slide2 = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine stars
    final score = GameSession().hostTrustScore;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: _opacity1,
          child: SlideTransition(
            position: _slide1,
            child: Text(AppLocalizations.get('welcome_back'), style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(color: Colors.white70, fontSize: 13))),
          ),
        ),
        const SizedBox(height: 4),
        FadeTransition(
          opacity: _opacity2,
          child: SlideTransition(
            position: _slide2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                   width: 150,
                   child: Text(
                    widget.nickname,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8), // Spacing
                const SizedBox(height: 8), 
                Align(
                  alignment: Alignment.centerRight,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                         showDialog(
                           context: context,
                           builder: (context) => AlertDialog(
                             backgroundColor: Colors.white,
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                             title: Row(
                               children: [
                                 const Icon(Icons.verified, color: Colors.blueAccent),
                                 const SizedBox(width: 8),
                                 Text(
                                   AppLocalizations.get('trust_score_title'), 
                                   style: const TextStyle(
                                     fontFamily: 'NURA', 
                                     fontWeight: FontWeight.bold, 
                                     fontSize: 20,
                                     color: Colors.black,
                                   )
                                 ),
                               ],
                             ),
                             content: Column(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 Text(
                                   score.toStringAsFixed(1),
                                   style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.blueAccent),
                                 ),
                                 Row(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   children: List.generate(5, (index) {
                                      IconData icon = Icons.star_border;
                                      if (score >= index + 1) icon = Icons.star;
                                      else if (score > index) icon = Icons.star_half;
                                      return Icon(icon, color: Colors.amber, size: 32);
                                   }),
                                 ),
                                 const SizedBox(height: 16),
                                 // Removed "Based on evaluations" as per request
                                 Text(
                                   AppLocalizations.get('trust_score_desc'),
                                   textAlign: TextAlign.center,
                                   style: AppLocalizations.getTextStyle(
                                      baseStyle: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black87)
                                   ),
                                 ),
                               ],
                             ),
                             actions: [
                               TextButton(
                                 onPressed: () => Navigator.pop(context), 
                                 child: Text(
                                   AppLocalizations.get('close'), 
                                   style: AppLocalizations.getTextStyle(
                                      baseStyle: const TextStyle(
                                        color: AppColors.hostPrimary, 
                                        fontWeight: FontWeight.bold
                                      )
                                   )
                                 )
                               )
                             ],
                           ),
                         );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min, 
                          crossAxisAlignment: CrossAxisAlignment.center, 
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (index) {
                                 IconData icon = Icons.star_border;
                                 if (score >= index + 1) {
                                     icon = Icons.star;
                                 } else if (score > index) {
                                     icon = Icons.star_half;
                                 }
                                 
                                 return Icon(
                                   icon, 
                                   size: 22, 
                                   color: const Color(0xB268CDFF), 
                                 );
                              }),
                            ),
                            const SizedBox(width: 8), 
                            Text(
                              score.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Color(0xB268CDFF), 
                                fontSize: 22, 
                                fontWeight: FontWeight.bold,
                                height: 1.0, 
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InteractiveTextButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isActive;
  final double fontSize;
  final Color textColor;
  final double? width;
  final double? height;

  const _InteractiveTextButton({
    super.key,
    required this.text,
    this.onTap,
    this.isActive = true,
    this.fontSize = 18,
    this.textColor = Colors.white,
    this.width,
    this.height,
  });

  @override
  State<_InteractiveTextButton> createState() => _InteractiveTextButtonState();
}

class _InteractiveTextButtonState extends State<_InteractiveTextButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (widget.isActive) {
          setState(() => _isHovered = true);
          _controller.forward();
        }
      },
      onExit: (_) {
        if (widget.isActive) {
          setState(() => _isHovered = false);
          _controller.reverse();
        }
      },
      cursor: widget.isActive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.isActive ? widget.onTap : null,
        behavior: HitTestBehavior.opaque, // Correctly capture taps in the translucent area
        child: Container(
          width: widget.width,
          height: widget.height,
          alignment: Alignment.center,
          color: Colors.transparent, // Required for HitTestBehavior to work on empty space
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NURA',
                    color: widget.isActive ? widget.textColor : Colors.white60,
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    shadows: _isHovered && widget.isActive
                        ? [
                            BoxShadow(
                              color: widget.textColor.withOpacity(0.8),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
