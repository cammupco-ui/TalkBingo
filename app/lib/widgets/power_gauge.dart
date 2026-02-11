import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/utils/localization.dart';

class PowerGauge extends StatelessWidget {
  final double power; // 0.0 ~ 1.2+
  final String? label; // Optional custom label
  final bool showLevels; // Whether to show color-coded levels
  
  const PowerGauge({
    super.key,
    required this.power,
    this.label,
    this.showLevels = false,
  });
  
  // Power Level Logic
  Color get _levelColor {
    if (!showLevels) return Colors.white; // Default for simple gauge
    
    if (power < 0.3) return Colors.yellow[700]!;
    if (power < 0.7) return Colors.green;
    if (power < 1.0) return Colors.orange;
    return Colors.red;
  }
  
  String get _levelLabel {
    if (label != null) return label!;
    if (!showLevels) return "POWER";
    
    if (power < 0.3) return "WEAK";
    if (power < 0.7) return "GOOD!";
    if (power < 1.0) return "STRONG";
    return "TOO STRONG!";
  }

  @override
  Widget build(BuildContext context) {
    final session = GameSession();
    final myColor = session.myRole == 'A'
        ? AppColors.hostPrimary
        : AppColors.guestPrimary;
    
    final levelColor = _levelColor;
    final effectiveColor = showLevels ? levelColor : myColor;
    
    // Responsive width
    final screenWidth = MediaQuery.of(context).size.width;
    final gaugeWidth = screenWidth < 375 
        ? screenWidth * 0.7  // Small screen: 70%
        : 220.0;             // Large screen: fixed 220px

    return Container(
      width: gaugeWidth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0219).withOpacity(0.9), // Dark background for contrast
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: effectiveColor.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                "POWER",
                style: GoogleFonts.alexandria(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  letterSpacing: 1.5,
                ),
               ),
               const SizedBox(width: 8),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                   color: effectiveColor.withOpacity(0.2),
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: effectiveColor, width: 1),
                 ),
                 child: Text(
                   _levelLabel,
                   style: GoogleFonts.doHyeon( // Use DoHyeon for punchy labels if available, else standard
                     fontSize: 11,
                     fontWeight: FontWeight.bold,
                     color: effectiveColor,
                   ),
                 ),
               )
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Gauge Bar
          SizedBox(
            height: 24, // Taller bar
            child: Stack(
              children: [
                // Background Track
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                
                // Fill
                FractionallySizedBox(
                  widthFactor: power.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          effectiveColor.withOpacity(0.6),
                          effectiveColor,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: effectiveColor.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Percentage Text (Centered)
                Center(
                  child: Text(
                    "${(power * 100).toInt()}%",
                    style: GoogleFonts.alexandria(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        const Shadow(color: Colors.black, blurRadius: 2),
                      ],
                    ),
                  ),
                ),
                
                // Good Zone Markers (30% - 70%)
                if (showLevels) ...[
                   Positioned(
                     left: 0, right: 0, bottom: 0, top: 0,
                     child: LayoutBuilder(
                       builder: (ctx, constraints) {
                          return Stack(
                            children: [
                               Positioned(
                                 left: constraints.maxWidth * 0.3,
                                 top: 0, bottom: 0,
                                 child: Container(width: 2, color: Colors.white30),
                               ),
                               Positioned(
                                 left: constraints.maxWidth * 0.7,
                                 top: 0, bottom: 0,
                                 child: Container(width: 2, color: Colors.white30),
                               ),
                            ],
                          );
                       },
                     ),
                   )
                ]
              ],
            ),
          ),
          
          // Optional Tip (For showLevels mode)
          if (showLevels)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    size: 14,
                    color: Colors.green.withOpacity(0.8),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      AppLocalizations.get('power_gauge_tip'),
                      style: GoogleFonts.doHyeon(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
