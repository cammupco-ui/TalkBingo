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
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Row(
            children: [
              // Timer Badge
              _buildTimerBadge(config, timeLeft),
              
              const SizedBox(width: 8),

              // Turn Indicator
              _buildTurnBadge(isMyTurn),

              const SizedBox(width: 8), 
              
              // Title
              Expanded(
                child: Text(
                  gameTitle,
                  style: GoogleFonts.alexandria(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Score Badges — show both when opponent score available
              if (opponentScore != null) ...[
                _buildScoreBadge(config, isMyTurn ? score : opponentScore!, label: isMyTurn ? 'ME' : 'OPP'),
                const SizedBox(width: 4),
                _buildScoreBadge(config, isMyTurn ? opponentScore! : score, label: isMyTurn ? 'OPP' : 'ME', isSecondary: true),
              ] else
                _buildScoreBadge(config, score),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTimerBadge(ResponsiveGameConfig config, double time) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
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
          const Icon(Icons.timer, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            '${time.toStringAsFixed(0)}s',
            style: GoogleFonts.alexandria(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScoreBadge(ResponsiveGameConfig config, int score, {String? label, bool isSecondary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star, 
            color: isSecondary ? Colors.grey[400] : Colors.amber, 
            size: 16,
          ),
          const SizedBox(width: 4),
          if (label != null) ...[
            Text(
              label,
              style: GoogleFonts.alexandria(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSecondary ? Colors.grey[300] : Colors.white70,
              ),
            ),
            const SizedBox(width: 2),
          ],
          Text(
            '$score',
            style: GoogleFonts.alexandria(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSecondary ? Colors.grey[300] : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnBadge(bool isMyTurn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isMyTurn ? const Color(0xFFBD0558) : Colors.grey[700],
        borderRadius: BorderRadius.circular(12),
        boxShadow: isMyTurn 
          ? [BoxShadow(color: const Color(0xFFBD0558).withOpacity(0.4), blurRadius: 6)] 
          : [],
      ),
      child: Text(
        isMyTurn ? "MY TURN" : "WAIT",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
