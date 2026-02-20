import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A transparent, centered overlay shown to the waiting player
/// while the opponent plays a mini-game (challenge or normal).
///
/// Shows:
/// - Opponent nickname + game name
/// - Animated progress indicator
/// - Cancel button to stop the game
/// - Result announcement when finished
class MiniGameWaitingOverlay extends StatefulWidget {
  final String opponentName;
  final String gameName;     // e.g. "과녁 맞추기" / "골 넣기"
  final String gameIcon;     // emoji string, e.g. "🎯" or "⚽"
  final int roundNumber;     // 1 or 2
  final bool isFinished;
  final String? resultText;  // e.g. "OOO scored 5 points!"
  final VoidCallback? onCancel; // Cancel/stop the mini-game

  const MiniGameWaitingOverlay({
    super.key,
    required this.opponentName,
    required this.gameName,
    this.gameIcon = '🎮',
    this.roundNumber = 1,
    this.isFinished = false,
    this.resultText,
    this.onCancel,
  });

  @override
  State<MiniGameWaitingOverlay> createState() => _MiniGameWaitingOverlayState();
}

class _MiniGameWaitingOverlayState extends State<MiniGameWaitingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: widget.isFinished
            ? _buildResultView()
            : _buildWaitingView(),
      ),
    );
  }

  Widget _buildWaitingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Game icon with pulse animation
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.15);
            return Transform.scale(scale: scale, child: child);
          },
          child: Text(
            widget.gameIcon,
            style: const TextStyle(fontSize: 48),
          ),
        ),
        const SizedBox(height: 20),
        // Opponent name
        Text(
          widget.opponentName,
          style: GoogleFonts.alexandria(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.gameName} 도전 중...',
          style: GoogleFonts.alexandria(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 24),
        // Animated progress indicator
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Wait message
        Text(
          '당신의 턴을 기다리세요!',
          style: GoogleFonts.alexandria(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 28),
        // Cancel button
        if (widget.onCancel != null)
          TextButton.icon(
            onPressed: widget.onCancel,
            icon: Icon(
              Icons.stop_circle_outlined,
              color: Colors.redAccent.withValues(alpha: 0.8),
              size: 20,
            ),
            label: Text(
              '게임 중단',
              style: GoogleFonts.alexandria(
                fontSize: 13,
                color: Colors.redAccent.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🏆', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text(
          widget.resultText ?? '게임 종료!',
          textAlign: TextAlign.center,
          style: GoogleFonts.alexandria(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '이제 당신의 차례입니다 🔥',
          style: GoogleFonts.alexandria(
            fontSize: 14,
            color: Colors.amber.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
