import 'package:flutter/material.dart';
import 'package:talkbingo_app/widgets/animated_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talkbingo_app/screens/guest_info_screen.dart'; // New Guest Screen
import 'package:talkbingo_app/screens/waiting_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talkbingo_app/screens/home_screen.dart';
import 'package:talkbingo_app/screens/signup_screen.dart'; // Added Import
import 'package:talkbingo_app/utils/ad_state.dart';
import 'package:talkbingo_app/styles/app_colors.dart';

import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/utils/localization.dart';

class InviteCodeScreen extends StatefulWidget {
  final String? initialCode;

  const InviteCodeScreen({super.key, this.initialCode});

  @override
  State<InviteCodeScreen> createState() => _InviteCodeScreenState();
}


class _InviteCodeScreenState extends State<InviteCodeScreen> {
  final List<TextEditingController> _controllers = [TextEditingController()];
  final List<FocusNode> _focusNodes = [FocusNode()];

  OverlayEntry? _pasteBubbleEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null) {
      _controllers[0].text = widget.initialCode!;
      // Auto-Submit if code is valid length
      if (widget.initialCode!.length == 6) {
         WidgetsBinding.instance.addPostFrameCallback((_) {
            _joinGame(widget.initialCode!);
         });
      }
    }
  }

  void _showPasteBubble() {
    _removePasteBubble();
    _pasteBubbleEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 120, // Compact width
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, -50), // Position above the field
          child: Material(
            elevation: 4,
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () async {
                  _removePasteBubble();
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                      final code = data!.text!.trim().toUpperCase();
                      if (code.length <= 6) {
                          setState(() => _controllers[0].text = code);
                          if (code.length == 6) _joinGame(code);
                      }
                  }
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.content_paste, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.get('paste'), 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_pasteBubbleEntry!);
    
    // Auto remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _removePasteBubble();
    });
  }

  void _removePasteBubble() {
    _pasteBubbleEntry?.remove();
    _pasteBubbleEntry = null;
  }

  @override
  void dispose() {
    _removePasteBubble();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _getEnteredCode() {
    return _controllers[0].text;
  }

  @override
  Widget build(BuildContext context) {
    // Hide Ad on Invite Code Screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdState.showAd.value = false;
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: () {
            final user = Supabase.instance.client.auth.currentUser;
            if (user != null && !user.isAnonymous) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            } else {
               // Guest or Anonymous -> Signup (Exit)
               Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignupScreen()),
                (route) => false,
              );
            }
          },
          child: SvgPicture.asset(
            'assets/images/Logo Vector.svg',
            height: 36,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.hostPrimary),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _removePasteBubble, // Tap outside closes bubble
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Text(
                AppLocalizations.get('invite_code_title'),
                style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700, 
                  fontFamily: 'NURA',
                  color: Color(0xFFBD0558),
                )),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Single Reliable Input Field Wrapped with Link and Detector
              CompositedTransformTarget(
                link: _layerLink,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: GestureDetector(
                    onTap: () {
                       _focusNodes[0].requestFocus();
                       _showPasteBubble();
                    },
                    child: AbsorbPointer( // Absorb pointer to let GestureDetector handle taps fully? No, we need typing.
                      // Actually, TextField needs focus. 
                      // If we wrap TextField with GestureDetector, TextField wins.
                      // We can listen to onTap in TextField? No property.
                      // We can use Listener?
                      // Or simply rely on the Touch-to-Paste requirement: "Touch input field".
                      // So onTap of TextField should trigger bubble.
                      absorbing: false,
                      child: TextField(
                        controller: _controllers[0],
                        focusNode: _focusNodes[0],
                        autofocus: true,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        onTap: _showPasteBubble, // Built-in onTap!
                        style: const TextStyle(
                          fontSize: 32, // Large, clear text
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NURA',
                          color: AppColors.hostPrimary,
                          letterSpacing: 8.0, // Spacing to give a "code" feel
                        ),
                        cursorColor: AppColors.hostPrimary,
                        textCapitalization: TextCapitalization.characters,
                        keyboardType: TextInputType.text,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                        ],
                        onChanged: (value) {
                          setState(() {});
                          if (value.length == 6) {
                            _joinGame(value);
                          }
                        },
                        decoration: InputDecoration(
                          counterText: '', // Hide char counter
                          hintText: 'CODE',
                          hintStyle: TextStyle(
                            color: AppColors.hostPrimary.withOpacity(0.3),
                            fontSize: 32,
                            fontFamily: 'NURA',
                            letterSpacing: 4.0,
                          ),
                          filled: true,
                          fillColor: AppColors.hostPrimary.withOpacity(0.05),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.hostPrimary, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.hostPrimary, width: 3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              // Removed Explicit Paste Button and Space


            // Next Button
            AnimatedButton(
              onPressed: () {
                final code = _getEnteredCode();
                if (code.length < 6) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.get('error_invalid_code'))),
                  );
                  return;
                }
                if (mounted) {
                   _joinGame(code); // Trigger Join Logic
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.hostPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 0),
                fixedSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                AppLocalizations.get('next'),
                style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(fontSize: 14, fontFamily: 'NURA', fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ));
  }
  Future<void> _joinGame(String code) async {
    try {
      await GameSession().joinGame(code); // Will throw if fails
      
      if (mounted) {
        final session = Supabase.instance.client.auth.currentSession;
        // If user is already authenticated (e.g. Host joining as Guest), skip Guest Info
        if (session != null && !session.user.isAnonymous) {
           Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const WaitingScreen()),
          );
        } else {
           Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const GuestInfoScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in _joinGame: $e'); // Added log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppLocalizations.get('error_prefix')}$e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
