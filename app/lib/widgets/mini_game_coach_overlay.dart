import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talkbingo_app/utils/localization.dart';
import 'package:talkbingo_app/services/onboarding_service.dart';

/// Full-screen coach-mark overlay for mini-games.
/// Shows an animated finger gesture tutorial (swipe / pull-back)
/// with a "don't show again" checkbox and X close button.
class MiniGameCoachOverlay extends StatefulWidget {
  /// 'penalty' or 'target'
  final String gameType;
  final VoidCallback onClose;

  const MiniGameCoachOverlay({
    super.key,
    required this.gameType,
    required this.onClose,
  });

  @override
  State<MiniGameCoachOverlay> createState() => _MiniGameCoachOverlayState();
}

class _MiniGameCoachOverlayState extends State<MiniGameCoachOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fingerController;
  late AnimationController _fadeController;
  bool _dontShowAgain = false;

  @override
  void initState() {
    super.initState();

    // Repeating finger gesture animation (1.2s per cycle)
    _fingerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Fade-in on open
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _fingerController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleClose() async {
    if (_dontShowAgain) {
      final key = widget.gameType == 'penalty' ? 'mini_penalty' : 'mini_target';
      await OnboardingService.dismissForever(key);
    }
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final isPenalty = widget.gameType == 'penalty';
    final hintKey = isPenalty ? 'mini_coach_penalty' : 'mini_coach_target';
    final hintText = AppLocalizations.get(hintKey);
    final dismissText = AppLocalizations.get('mini_coach_dismiss');

    return FadeTransition(
      opacity: _fadeController,
      child: Material(
        color: Colors.black.withOpacity(0.82),
        child: SafeArea(
          child: Stack(
            children: [
              // ── X Close Button ──
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  onPressed: _handleClose,
                  icon: const Icon(Icons.close, color: Colors.white70, size: 32),
                ),
              ),

              // ── Center Content ──
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gesture Animation Area
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: _FingerGestureWidget(
                        animation: _fingerController,
                        isPenalty: isPenalty,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Instruction Text
                    Text(
                      hintText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.alexandria(
                        color: const Color(0xFFF5E6D3),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Don't show again checkbox
                    GestureDetector(
                      onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white54, width: 1.5),
                              borderRadius: BorderRadius.circular(4),
                              color: _dontShowAgain
                                  ? Colors.white24
                                  : Colors.transparent,
                            ),
                            child: _dontShowAgain
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            dismissText,
                            style: GoogleFonts.alexandria(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated finger gesture — uses AnimatedWidget to repaint at 60fps
class _FingerGestureWidget extends AnimatedWidget {
  final bool isPenalty;

  const _FingerGestureWidget({
    required Animation<double> animation,
    required this.isPenalty,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final double t = (listenable as Animation<double>).value;

    // Eased progress with pause at start
    final double eased = t < 0.15
        ? 0.0
        : t > 0.85
            ? 1.0
            : Curves.easeInOut.transform((t - 0.15) / 0.7);

    // Penalty: finger moves upward (swipe to goal)
    // Target: finger moves downward (pull back toward self)
    final double startY = isPenalty ? 80 : -60;
    final double endY = isPenalty ? -60 : 80;
    final double fingerY = startY + (endY - startY) * eased;

    // Opacity: fade out at end of gesture
    final double opacity = t > 0.85 ? (1.0 - (t - 0.85) / 0.15) : 1.0;

    return CustomPaint(
      painter: _GesturePainter(
        fingerY: fingerY,
        opacity: opacity,
        trailStartY: startY,
        trailEndY: fingerY,
        isPenalty: isPenalty,
        progress: eased,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _GesturePainter extends CustomPainter {
  final double fingerY;
  final double opacity;
  final double trailStartY;
  final double trailEndY;
  final bool isPenalty;
  final double progress;

  _GesturePainter({
    required this.fingerY,
    required this.opacity,
    required this.trailStartY,
    required this.trailEndY,
    required this.isPenalty,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // ── Trail dotted line ──
    if (progress > 0) {
      final trailPaint = Paint()
        ..color = Colors.white.withOpacity(0.25 * opacity)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      const dashLen = 6.0;
      const gapLen = 4.0;
      final from = cy + trailStartY;
      final to = cy + trailEndY;
      final dir = to > from ? 1.0 : -1.0;
      double y = from;
      while ((dir > 0 && y < to) || (dir < 0 && y > to)) {
        final end = y + dir * dashLen;
        canvas.drawLine(
          Offset(cx, y),
          Offset(cx, dir > 0 ? end.clamp(from, to) : end.clamp(to, from)),
          trailPaint,
        );
        y += dir * (dashLen + gapLen);
      }
    }

    // ── Arrow indicator ──
    if (progress > 0) {
      final arrowPaint = Paint()
        ..color = Colors.white.withOpacity(0.4 * opacity)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final arrowY = cy + (isPenalty ? -70 : 90);
      final arrowDir = isPenalty ? -1.0 : 1.0;
      canvas.drawLine(
        Offset(cx - 8, arrowY + arrowDir * 8),
        Offset(cx, arrowY),
        arrowPaint,
      );
      canvas.drawLine(
        Offset(cx + 8, arrowY + arrowDir * 8),
        Offset(cx, arrowY),
        arrowPaint,
      );
    }

    // ── Finger icon (touch circle) ──
    // Glow ring
    final glowPaint = Paint()
      ..color = const Color(0xFFF5E6D3).withOpacity(0.15 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy + fingerY), 32, glowPaint);

    // Touch indicator
    final touchPaint = Paint()
      ..color = const Color(0xFFF5E6D3).withOpacity(0.7 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy + fingerY), 16, touchPaint);

    // Inner dot
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.9 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy + fingerY), 6, dotPaint);

    // Outer ring
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.3 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy + fingerY), 24, ringPaint);

    // ── Game icon hint at destination ──
    if (isPenalty) {
      _drawGoalHint(canvas, cx, cy - 80, opacity);
    } else {
      _drawTargetHint(canvas, cx, cy - 80, opacity);
    }
  }

  void _drawGoalHint(Canvas canvas, double cx, double cy, double opacity) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rect = Rect.fromCenter(center: Offset(cx, cy), width: 50, height: 30);
    canvas.drawRect(rect, paint);

    // Net lines
    final thinPaint = Paint()
      ..color = Colors.white.withOpacity(0.2 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (int i = 1; i < 4; i++) {
      final x = rect.left + (rect.width / 4) * i;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), thinPaint);
    }
    for (int i = 1; i < 3; i++) {
      final y = rect.top + (rect.height / 3) * i;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), thinPaint);
    }
  }

  void _drawTargetHint(Canvas canvas, double cx, double cy, double opacity) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset(cx, cy), 18, paint);
    canvas.drawCircle(Offset(cx, cy), 10, paint);

    final fillPaint = Paint()
      ..color = Colors.white.withOpacity(0.4 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 3, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _GesturePainter oldDelegate) =>
      fingerY != oldDelegate.fingerY ||
      opacity != oldDelegate.opacity ||
      progress != oldDelegate.progress;
}
