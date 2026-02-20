import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talkbingo_app/games/config/responsive_config.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/styles/app_colors.dart';

class GameHeader extends StatelessWidget {
  final String gameTitle;
  final int score;
  final int? opponentScore; // Real-time opponent score (for spectator mode)
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
    final config = ResponsiveGameConfig(MediaQuery.of(context).size);
    final session = GameSession();
    final isCompact = config.sizeClass == GameSize.small || config.sizeClass == GameSize.medium;
    // Scale factor: 1.0 at height=64, grows proportionally for taller headers
    final double scale = (config.headerHeight / 64.0).clamp(1.0, 1.5);
    
    // Determine Role Colors
    final myColor = session.myRole == 'A' 
        ? AppColors.hostPrimary 
        : AppColors.guestPrimary;
    final darkColor = session.myRole == 'A'
        ? AppColors.hostDark
        : AppColors.guestDark;
    
    return Container(
      height: config.headerHeight,
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
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 16,
            vertical: isCompact ? 4 : 8,
          ),
          child: Row(
            children: [
              // Timer Badge
              _buildTimerBadge(config, timeLeft, isCompact, scale),
              
              SizedBox(width: isCompact ? 4 : 8),

              // Turn Indicator
              _buildTurnBadge(isMyTurn, isCompact, scale),

              SizedBox(width: isCompact ? 4 : 8), 
              
              // Title
              Expanded(
                child: Text(
                  gameTitle,
                  style: GoogleFonts.alexandria(
                    fontSize: (isCompact ? 13 : 18) * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: isCompact ? 0.5 : 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              SizedBox(width: isCompact ? 4 : 12),
              
              // Score Badges — show both when opponent score available
              // Always: score=ME, opponentScore=OPP (caller must pass correct values)
              if (opponentScore != null) ...[
                _buildScoreBadge(config, score, label: 'ME', isCompact: isCompact, scale: scale),
                SizedBox(width: isCompact ? 2 : 4),
                _buildScoreBadge(config, opponentScore!, label: 'OPP', isSecondary: true, isCompact: isCompact, scale: scale),
              ] else
                _buildScoreBadge(config, score, isCompact: isCompact, scale: scale),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTimerBadge(ResponsiveGameConfig config, double time, bool isCompact, double scale) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 12,
        vertical: isCompact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, color: Colors.white, size: (isCompact ? 12 : 16) * scale),
          SizedBox(width: isCompact ? 2 : 4),
          Text(
            '${time.toStringAsFixed(0)}',
            style: GoogleFonts.alexandria(
              fontSize: (isCompact ? 11 : 14) * scale,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScoreBadge(ResponsiveGameConfig config, int score, {String? label, bool isSecondary = false, bool isCompact = false, double scale = 1.0}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 12,
        vertical: isCompact ? 2 : 6,
      ),
      decoration: BoxDecoration(
        color: isSecondary 
            ? Colors.white.withOpacity(0.15) 
            : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
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
                fontSize: (isCompact ? 7 : 10) * scale,
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
                size: (isCompact ? 10 : 16) * scale,
              ),
              SizedBox(width: isCompact ? 1 : 4),
              Text(
                '$score',
                style: GoogleFonts.alexandria(
                  fontSize: (isCompact ? 11 : 14) * scale,
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

  Widget _buildTurnBadge(bool isMyTurn, bool isCompact, double scale) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 10, 
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: isMyTurn ? const Color(0xFFBD0558) : Colors.grey[700],
        borderRadius: BorderRadius.circular(12),
        boxShadow: isMyTurn 
          ? [BoxShadow(color: const Color(0xFFBD0558).withOpacity(0.4), blurRadius: 6)] 
          : [],
      ),
      child: Text(
        isMyTurn ? (isCompact ? "MY" : "MY TURN") : "WAIT",
        style: TextStyle(
          color: Colors.white,
          fontSize: (isCompact ? 8 : 10) * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: isCompact ? 0.5 : 1.0,
        ),
      ),
    );
  }
}
