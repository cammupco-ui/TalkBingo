import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talkbingo_app/widgets/animated_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/screens/home_screen.dart';
import 'package:talkbingo_app/screens/host_setup_screen.dart';
import 'package:talkbingo_app/screens/signup_screen.dart';
import 'package:talkbingo_app/screens/point_purchase_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class RewardScreen extends StatefulWidget {
  final bool isDraw;
  const RewardScreen({super.key, this.isDraw = false});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  late ConfettiController _confettiController;
  double _currentRating = 5.0; // Default rating


  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    if (!widget.isDraw) {
      // Play confetti if not a draw
      WidgetsBinding.instance.addPostFrameCallback((_) => _confettiController.play());
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = GameSession();
    final results = session.calculateEndGameResults();
    
    // Determine my stats based on role
    final myRole = session.myRole; // 'A' or 'B'
    final int myGp = ((myRole == 'A' ? results['gpA'] : results['gpB']) as num?)?.toInt() ?? 0;
    final int myVp = ((myRole == 'A' ? results['vpA'] : results['vpB']) as num?)?.toInt() ?? 0;
    final int myEp = ((myRole == 'A' ? results['epA'] : results['epB']) as num?)?.toInt() ?? 0;
    final int myAp = ((myRole == 'A' ? results['apA'] : results['apB']) as num?)?.toInt() ?? 0;
    
    // If Draw, overwrite GP to 0 and winner to DRAW
    final finalWinner = widget.isDraw ? 'DRAW' : results['winner'];
    final int finalGp = widget.isDraw ? 0 : myGp;
    final int finalVp = widget.isDraw ? 0 : myVp;
    final int finalEp = myEp; // EP always earned regardless of draw
    final int finalAp = myAp; // AP always earned regardless of draw

    // Determine if user is Host (MP) or Guest (CP)
    bool isHost = session.myRole == 'A';

    return Scaffold(
      backgroundColor: const Color(0xFFFBEFF2), // Rose Mist Base
      body: Stack(
        children: [
          Center(
          child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Header
              SvgPicture.asset(
                'assets/images/logo_vector.svg',
                height: 40,
              ),
              const SizedBox(height: 24),
              Text(
                finalWinner == 'DRAW' ? "DRAW GAME" : 
                finalWinner == myRole ? "YOU WON! 🏆" : "GAME OVER",
                style: GoogleFonts.alexandria(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.hostPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // 2. Points Card
              GestureDetector(
                onTap: () {
                   Navigator.of(context).push(
                     MaterialPageRoute(builder: (_) => PointPurchaseScreen())
                   );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Total Points (Tap to Manage)",
                        style: GoogleFonts.alexandria(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPointRow("Victory Points (VP)", finalVp, AppColors.hostPrimary),
                      const SizedBox(height: 8),
                      _buildPointRow("Game Points (GP)", finalGp, Colors.amber),
                      const SizedBox(height: 8),
                      _buildPointRow("Exploration Points (EP)", finalEp, Colors.teal),
                      const SizedBox(height: 8),
                      _buildPointRow("Achievement Points (AP)", finalAp, Colors.deepPurple),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 3. Actions based on Role
              if (isHost) ...[
                // Host (MP) -> Play Again or Home
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: AnimatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => HostSetupScreen(
                            initialGender: session.guestGender,
                            initialMainRelation: session.relationMain,
                            initialSubRelation: session.relationSub,
                            initialIntimacyLevel: session.intimacyLevel,
                          ),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.hostPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Play Again 🎮",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Home",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                // Guest (CP)
               const Text("Rate your partner (Trust Score):", style: TextStyle(fontWeight: FontWeight.bold)),
               const SizedBox(height: 10),
               
               // Star Display
               Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: List.generate(5, (index) {
                    // Logic for half stars could be added here, but simple full/dim logic for MVP
                    // Or use Icons.star_half
                    IconData icon = Icons.star_border;
                    Color color = Colors.grey[300]!;
                    
                    if (_currentRating >= index + 1) {
                       icon = Icons.star;
                       color = Colors.amber;
                    } else if (_currentRating > index) {
                       icon = Icons.star_half;
                       color = Colors.amber;
                    }
                    
                    return Icon(icon, size: 32, color: color);
                 }),
               ),
               Text(
                 _currentRating.toStringAsFixed(1), 
                 style: GoogleFonts.alexandria(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber[800])
               ),
               Slider(
                 value: _currentRating,
                 min: 0.0,
                 max: 5.0,
                 divisions: 50,
                 label: _currentRating.toStringAsFixed(1),
                 activeColor: Colors.amber,
                 onChanged: (val) {
                    setState(() {
                       _currentRating = val;
                    });
                 },
               ),
               
               const SizedBox(height: 16),
               
               // If Guest is actually a registered user (Member Guest)
               if (Supabase.instance.client.auth.currentSession?.user.isAnonymous == false) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 44, // Strict 44px
                    child: AnimatedButton(
                      onPressed: () async {
                        await session.submitGuestRating(_currentRating);
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const HomeScreen()),
                              (route) => false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.hostPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Submit & Home",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
               ] else ...[
                 // Anonymous Guest -> Exit / Signup
                 Row(
                   children: [
                     Expanded(
                       child: OutlinedButton(
                         onPressed: () async {
                           await session.submitGuestRating(_currentRating); // Submit even on Exit? Yes.
                           if (mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const HomeScreen()), 
                                (route) => false);
                           }
                         },
                         style: OutlinedButton.styleFrom(
                           padding:const EdgeInsets.symmetric(vertical: 16),
                           side: const BorderSide(color: Colors.grey),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                         ),
                         child: const Text("EXIT", style: TextStyle(color: Colors.grey)),
                       ),
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: ElevatedButton(
                         onPressed: () async {
                           await session.submitGuestRating(_currentRating);
                           if (mounted) {
                               Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SignupScreen()),
                               );
                           }
                         },
                         style: ElevatedButton.styleFrom(
                             padding:const EdgeInsets.symmetric(vertical: 16),
                           backgroundColor: AppColors.hostPrimary,
                           foregroundColor: Colors.white,
                           shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(16)),
                         ),
                         child: const Text("Signup", style: TextStyle(fontWeight: FontWeight.bold)),
                       ),
                     ),
                   ],
                 )
               ]
              ],
            ],
          ),
        ),
      ),
      // Confetti Layer
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // Down
              maxBlastForce: 10, // Stronger blast for victory
              minBlastForce: 5,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple, Colors.amber],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointRow(String label, int points, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.alexandria(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "+$points",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
