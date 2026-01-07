import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class FloatingScore extends StatelessWidget {
  final int points;
  final String label; // e.g. "EP", "AP"
  final VoidCallback onComplete;

  const FloatingScore({
    super.key,
    required this.points,
    required this.label,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '+$points $label',
      style: GoogleFonts.alexandria(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFFFD700), // Gold
        shadows: [
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
    )
    .animate(onComplete: (controller) => onComplete())
    .moveY(begin: 0, end: -50, duration: 800.ms, curve: Curves.easeOut)
    .fadeOut(begin: 0.8, duration: 800.ms);
  }
}
