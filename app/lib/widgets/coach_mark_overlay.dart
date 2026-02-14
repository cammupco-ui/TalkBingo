import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talkbingo_app/services/onboarding_service.dart';
import 'package:talkbingo_app/utils/localization.dart';

/// A single coach-mark step: targets a GlobalKey, shows a label.
class CoachMarkStep {
  final GlobalKey targetKey;
  final String labelKey; // localization key
  final EdgeInsets spotlightPadding;

  const CoachMarkStep({
    required this.targetKey,
    required this.labelKey,
    this.spotlightPadding = const EdgeInsets.all(8),
  });
}

/// Full-screen overlay that highlights one element at a time.
///
/// Usage:
/// ```dart
/// CoachMarkOverlay(
///   screenName: 'home',
///   steps: [ CoachMarkStep(targetKey: _newGameKey, labelKey: 'coach_home_new_game'), ... ],
///   onFinished: () => setState(() => _showCoach = false),
/// )
/// ```
class CoachMarkOverlay extends StatefulWidget {
  final String screenName;
  final List<CoachMarkStep> steps;
  final VoidCallback onFinished;

  const CoachMarkOverlay({
    super.key,
    required this.screenName,
    required this.steps,
    required this.onFinished,
  });

  @override
  State<CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<CoachMarkOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _dontShowAgain = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _close();
    }
  }

  Future<void> _close() async {
    if (_dontShowAgain) {
      await OnboardingService.dismissForever(widget.screenName);
    }
    widget.onFinished();
  }

  // Get the Rect of the current target widget
  Rect? _getTargetRect() {
    final step = widget.steps[_currentStep];
    final ctx = step.targetKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return step.spotlightPadding.inflateRect(
      Rect.fromLTWH(offset.dx, offset.dy, box.size.width, box.size.height),
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetRect = _getTargetRect();
    final screenSize = MediaQuery.of(context).size;
    final step = widget.steps[_currentStep];
    final label = AppLocalizations.get(step.labelKey);
    final isLastStep = _currentStep == widget.steps.length - 1;

    // Decide if tooltip goes above or below the spotlight
    final bool showBelow =
        targetRect != null && targetRect.center.dy < screenSize.height * 0.5;

    return GestureDetector(
      onTap: _next,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) {
          return Stack(
            children: [
              // ── 1. Dark overlay with cutout ──
              if (targetRect != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SpotlightPainter(
                      targetRect: targetRect,
                      pulseRadius: _pulseAnim.value,
                    ),
                  ),
                )
              else
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.7)),
                ),

              // ── 2. Tooltip bubble ──
              if (targetRect != null)
                Positioned(
                  left: 24,
                  right: 24,
                  top: showBelow ? targetRect.bottom + 16 : null,
                  bottom: showBelow
                      ? null
                      : screenSize.height - targetRect.top + 16,
                  child: _buildTooltipCard(label, isLastStep, showBelow),
                ),

              // ── 3. Step indicator (top center) ──
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.steps.length, (i) {
                    return Container(
                      width: i == _currentStep ? 20 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == _currentStep
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),

              // ── 4. Skip button (top right) ──
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16,
                child: TextButton(
                  onPressed: _close,
                  child: Text(
                    AppLocalizations.get('coach_skip'),
                    style: AppLocalizations.getTextStyle(
                      baseStyle: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTooltipCard(String label, bool isLastStep, bool arrowUp) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Arrow pointing up
        if (!arrowUp)
          const SizedBox.shrink()
        else
          CustomPaint(
            size: const Size(20, 10),
            painter: _ArrowPainter(
                color: const Color(0xE6FFFFFF), pointUp: true),
          ),

        // Main card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xE6FFFFFF),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppLocalizations.getTextStyle(
                  baseStyle: const TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Progress + Don't show again row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // "Don't show again" checkbox
                  GestureDetector(
                    onTap: () =>
                        setState(() => _dontShowAgain = !_dontShowAgain),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: Checkbox(
                            value: _dontShowAgain,
                            onChanged: (v) =>
                                setState(() => _dontShowAgain = v ?? false),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            activeColor: const Color(0xFFF6005E),
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.get('coach_dont_show'),
                          style: AppLocalizations.getTextStyle(
                            baseStyle: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Next / Done button
                  TextButton(
                    onPressed: _next,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF6005E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      isLastStep
                          ? AppLocalizations.get('coach_done')
                          : AppLocalizations.get('coach_next'),
                      style: AppLocalizations.getTextStyle(
                        baseStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Arrow pointing down
        if (arrowUp)
          const SizedBox.shrink()
        else
          CustomPaint(
            size: const Size(20, 10),
            painter: _ArrowPainter(
                color: const Color(0xE6FFFFFF), pointUp: false),
          ),
      ],
    );
  }
}

// ── Painters ──

class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final double pulseRadius;

  _SpotlightPainter({required this.targetRect, required this.pulseRadius});

  @override
  void paint(Canvas canvas, Size size) {
    // Dark overlay
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.75);
    canvas.drawRect(Offset.zero & size, overlayPaint);

    // Clear the spotlight area (rounded rect)
    final rr = RRect.fromRectAndRadius(
      targetRect.inflate(pulseRadius),
      const Radius.circular(12),
    );
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, overlayPaint);
    canvas.drawRRect(rr, clearPaint);
    canvas.restore();

    // Subtle glow ring
    final glowPaint = Paint()
      ..color = const Color(0xFFF6005E).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(rr.inflate(2), glowPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.targetRect != targetRect || old.pulseRadius != pulseRadius;
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final bool pointUp;

  _ArrowPainter({required this.color, required this.pointUp});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (pointUp) {
      path.moveTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
