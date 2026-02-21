import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talkbingo_app/games/config/responsive_config.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/styles/app_colors.dart';

class GameHeader extends StatelessWidget {
  final String gameTitle;
  final int score;
  final int? opponentScore;
  final double timeLeft;
  final bool isMyTurn;
  final VoidCallback? onMenuTap;
  
  const GameHeader({
    super.key,
    required this.gameTitle,
    required this.score,
    this.opponentScore,
    required this.timeLeft,
    this.isMyTurn = true,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final config = ResponsiveGameConfig(screenSize);
    final session = GameSession();
    
    // Use screen width for responsive sizing (more stable than height)
    // Compute a single responsive factor from width, capped for consistency
    // iPhone SE=375, iPhone 15=393, Pro Max=430, iPad=768+, Web=800+
    final double w = min(screenSize.width, 500.0); // Cap at 500 to avoid oversized web/tablet
    
    // Font sizes: directly proportional to width with tight ranges
    final double titleSize = (w * 0.036).clamp(12.0, 16.0);     // 13.5 @ 375 → 16 @ 444+
    final double bodySize = (w * 0.030).clamp(10.0, 14.0);      // 11.3 @ 375 → 14 @ 467+
    final double labelSize = (w * 0.020).clamp(7.0, 10.0);      // 7.5 @ 375 → 10 @ 500
    final double iconSize = (w * 0.036).clamp(12.0, 16.0);      // matches title
    final double smallIconSize = (w * 0.028).clamp(10.0, 14.0);
    
    final bool isCompact = w < 400;
    final double hPad = isCompact ? 8 : 12;
    final double vPad = isCompact ? 6 : 8;
    
    // Determine Role Colors
    final myColor = session.myRole == 'A' 
        ? AppColors.hostPrimary 
        : AppColors.guestPrimary;
    final darkColor = session.myRole == 'A'
        ? AppColors.hostDark
        : AppColors.guestDark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [myColor, darkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          child: Row(
            children: [
              // Timer Badge
              _buildTimerBadge(timeLeft, isCompact, iconSize, bodySize),
              
              SizedBox(width: isCompact ? 4 : 6),

              // Turn Indicator
              _buildTurnBadge(isMyTurn, isCompact, labelSize),

              SizedBox(width: isCompact ? 4 : 6), 
              
              // Title
              Expanded(
                child: Text(
                  gameTitle,
                  style: GoogleFonts.alexandria(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              SizedBox(width: isCompact ? 4 : 6),
              
              // Score Badges
              if (opponentScore != null) ...[
                _buildScoreBadge(score, label: 'ME', isCompact: isCompact, fontSize: bodySize, labelFontSize: labelSize, iconSz: smallIconSize),
                const SizedBox(width: 3),
                _buildScoreBadge(opponentScore!, label: 'OPP', isSecondary: true, isCompact: isCompact, fontSize: bodySize, labelFontSize: labelSize, iconSz: smallIconSize),
              ] else
                _buildScoreBadge(score, isCompact: isCompact, fontSize: bodySize, labelFontSize: labelSize, iconSz: smallIconSize),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTimerBadge(double time, bool isCompact, double iconSz, double fontSize) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, color: Colors.white, size: iconSz),
          const SizedBox(width: 3),
          Text(
            '${time.toStringAsFixed(0)}',
            style: GoogleFonts.alexandria(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScoreBadge(int score, {String? label, bool isSecondary = false, bool isCompact = false, required double fontSize, required double labelFontSize, required double iconSz}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 10,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: isSecondary 
            ? Colors.white.withOpacity(0.15) 
            : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(isSecondary ? 0.2 : 0.4),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null)
            Text(
              label,
              style: GoogleFonts.alexandria(
                fontSize: labelFontSize,
                fontWeight: FontWeight.w600,
                color: isSecondary ? Colors.grey[300] : Colors.white70,
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star, 
                color: isSecondary ? Colors.grey[400] : Colors.amber, 
                size: iconSz,
              ),
              const SizedBox(width: 2),
              Text(
                '$score',
                style: GoogleFonts.alexandria(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: isSecondary ? Colors.grey[300] : Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTurnBadge(bool isMyTurn, bool isCompact, double fontSize) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8, 
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: isMyTurn ? const Color(0xFFBD0558) : Colors.grey[700],
        borderRadius: BorderRadius.circular(10),
        boxShadow: isMyTurn 
          ? [BoxShadow(color: const Color(0xFFBD0558).withOpacity(0.4), blurRadius: 6)] 
          : [],
      ),
      child: Text(
        isMyTurn ? (isCompact ? "MY" : "MY TURN") : "WAIT",
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
