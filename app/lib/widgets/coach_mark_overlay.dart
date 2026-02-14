import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // Text color: white 90% + yellow 10% blend
  static const Color _textColor = Color(0xFFF5F0D0);
  static const Color _arrowColor = Color(0xFFF5F0D0);

  @override
  void initState() {
    super.initState();
    // Pulse animation for arrow/text
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Fade-in for each step
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < widget.steps.length - 1) {
      _fadeController.reset();
      setState(() => _currentStep++);
      _fadeController.forward();
    } else {
      _close();
    }
  }

  Future<void> _close() async {
    await OnboardingService.dismissForever(widget.screenName);
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

    // Determine language for font selection
    final lang = _getDeviceLanguage();
    final isKo = lang == 'ko';

    // Decide if text goes above or below the target center
    final targetCenter = targetRect?.center ?? screenSize.center(Offset.zero);
    final bool textBelow = targetCenter.dy < screenSize.height * 0.45;

    // ── Compute text position ──
    // Text is placed with a comfortable gap from the spotlight edge
    const double gapFromSpotlight = 50.0;
    double textY;
    if (textBelow) {
      // Text below: position after bottom edge of target
      final spotlightBottom = targetRect?.bottom ?? targetCenter.dy;
      textY = spotlightBottom + gapFromSpotlight;
    } else {
      // Text above: position before top edge of target
      final spotlightTop = targetRect?.top ?? targetCenter.dy;
      textY = spotlightTop - gapFromSpotlight;
    }

    // ── Compute arrow endpoints ──
    // Arrow "from" starts near the label text, slightly toward the target
    // Arrow "to" points at the nearest edge of the spotlight, not the center
    Offset arrowFrom;
    Offset arrowTo;
    if (targetRect != null) {
      // "To" = closest point on spotlight edge to text
      if (textBelow) {
        // Text is below → arrow points up to bottom edge of spotlight
        arrowTo = Offset(targetCenter.dx, targetRect.top + targetRect.height * 0.75);
        arrowFrom = Offset(targetCenter.dx, textY - 8);
      } else {
        // Text is above → arrow points down to top edge of spotlight
        arrowTo = Offset(targetCenter.dx, targetRect.top + targetRect.height * 0.25);
        arrowFrom = Offset(targetCenter.dx, textY + 8);
      }
    } else {
      arrowFrom = Offset(screenSize.width / 2, textY);
      arrowTo = targetCenter;
    }

    return GestureDetector(
      onTap: _next,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnim, _fadeAnim]),
        builder: (context, child) {
          return Stack(
            children: [
              // ── 1. Dark overlay with spotlight cutout ──
              if (targetRect != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SpotlightPainter(
                      targetRect: targetRect,
                      pulseRadius: (_pulseAnim.value - 0.85) * 26.67, // 0..8
                    ),
                  ),
                )
              else
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.75)),
                ),

              // ── 2. Gentle curved arrow ──
              if (targetRect != null)
                Positioned.fill(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: CustomPaint(
                      painter: _CurlyArrowPainter(
                        from: arrowFrom,
                        to: arrowTo,
                        color: _arrowColor.withOpacity(0.9),
                        pulseScale: _pulseAnim.value,
                        pointDown: textBelow,
                      ),
                    ),
                  ),
                ),

              // ── 3. Label text ──
              if (targetRect != null)
                Positioned(
                  left: 32,
                  right: 32,
                  top: textBelow ? textY : null,
                  bottom: textBelow ? null : screenSize.height - textY,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Transform.scale(
                      scale: 0.9 + (_pulseAnim.value - 0.85) * 0.33,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: isKo ? 'EliceDigitalBaeum' : null,
                          fontFamilyFallback: isKo ? null : const ['EliceDigitalBaeum'],
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _textColor,
                          height: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.7),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // ── 4. Step dots (top center) ──
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.steps.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: i == _currentStep ? 20 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == _currentStep
                            ? _textColor
                            : _textColor.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),

              // ── 5. Skip button (top right) ──
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16,
                child: TextButton(
                  onPressed: _close,
                  child: Text(
                    AppLocalizations.get('coach_skip'),
                    style: TextStyle(
                      fontFamily: isKo ? 'EliceDigitalBaeum' : null,
                      color: Colors.white60,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // ── 6. Tap hint (bottom center) ──
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: 0.5 + (_pulseAnim.value - 0.85) * 1.67,
                  child: Text(
                    _currentStep < widget.steps.length - 1
                        ? AppLocalizations.get('coach_next')
                        : AppLocalizations.get('coach_done'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: isKo ? 'EliceDigitalBaeum' : null,
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  /// Detect device language (bypass GameSession if needed)
  String _getDeviceLanguage() {
    try {
      final locale = ui.PlatformDispatcher.instance.locale;
      if (locale.languageCode == 'ko') return 'ko';
    } catch (_) {}

    try {
      final testVal = AppLocalizations.get('coach_skip');
      if (testVal == '건너뛰기') return 'ko';
    } catch (_) {}

    return 'en';
  }
}

// ── Painters ──

/// Spotlight cutout painter
class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final double pulseRadius;

  _SpotlightPainter({required this.targetRect, required this.pulseRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.75);
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
      ..color = const Color(0xFFF5F0D0).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(rr.inflate(2), glowPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.targetRect != targetRect || old.pulseRadius != pulseRadius;
}

/// Gentle curved dotted arrow painter — clean S-curve, no exaggerated loops
class _CurlyArrowPainter extends CustomPainter {
  final Offset from; // near the text
  final Offset to;   // spotlight edge
  final Color color;
  final double pulseScale;
  final bool pointDown;

  _CurlyArrowPainter({
    required this.from,
    required this.to,
    required this.color,
    required this.pulseScale,
    required this.pointDown,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    // Build the smooth curve (gentle S-curve, no pig-tail)
    final path = _buildSmoothCurve(from, to);

    // Convert to dashed path
    final dashedPath = _dashPath(path, dashLength: 6, gapLength: 5);
    canvas.drawPath(dashedPath, paint);

    // Draw arrowhead aligned to the curve's tangent at the tip
    _drawArrowheadAlongCurve(canvas, path);

    // Pulsing dot at arrow tip
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final dotRadius = 3.5 * pulseScale;
    canvas.drawCircle(to, dotRadius, dotPaint);

    // Outer glow on tip
    final glowPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(to, dotRadius * 2.0, glowPaint);
  }

  /// Build a gentle S-curve from text to target edge.
  /// Uses a single cubic bezier with modest lateral offset — no loops.
  Path _buildSmoothCurve(Offset start, Offset end) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < 1) {
      path.lineTo(end.dx, end.dy);
      return path;
    }

    // Perpendicular direction for the curve offset
    final perpX = -dy / dist;
    final perpY = dx / dist;

    // Subtle lateral curve — capped to avoid wild arcs
    final curlAmount = min(dist * 0.15, 40.0);

    // Control point 1: ~30% along, offset to one side
    final cp1 = Offset(
      start.dx + dx * 0.3 + perpX * curlAmount,
      start.dy + dy * 0.3 + perpY * curlAmount,
    );

    // Control point 2: ~70% along, offset to opposite side
    final cp2 = Offset(
      start.dx + dx * 0.7 - perpX * curlAmount * 0.5,
      start.dy + dy * 0.7 - perpY * curlAmount * 0.5,
    );

    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
    return path;
  }

  Path _dashPath(Path source, {double dashLength = 6, double gapLength = 5}) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashLength : gapLength;
        final end = (distance + len).clamp(0.0, metric.length);
        if (draw) {
          result.addPath(
            metric.extractPath(distance, end),
            Offset.zero,
          );
        }
        distance = end;
        draw = !draw;
      }
    }
    return result;
  }

  /// Draw arrowhead aligned to the curve's actual tangent at the tip,
  /// so it always looks natural regardless of curve direction.
  void _drawArrowheadAlongCurve(Canvas canvas, Path curvePath) {
    final metrics = curvePath.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.last;
    final length = metric.length;
    if (length < 2) return;

    // Get tangent at the very end of the curve
    final tangent = metric.getTangentForOffset(length);
    if (tangent == null) return;

    final tipPos = tangent.position;
    final dir = tangent.vector; // unit direction at tip
    final ux = dir.dx;
    final uy = dir.dy;

    const headLen = 10.0;
    const headWidth = 5.0;

    final basePt = Offset(tipPos.dx - ux * headLen, tipPos.dy - uy * headLen);
    final px = -uy; // perpendicular
    final py = ux;

    final left = Offset(basePt.dx + px * headWidth, basePt.dy + py * headWidth);
    final right = Offset(basePt.dx - px * headWidth, basePt.dy - py * headWidth);

    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final headPath = Path()
      ..moveTo(tipPos.dx, tipPos.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(headPath, headPaint);
  }

  @override
  bool shouldRepaint(covariant _CurlyArrowPainter old) =>
      old.from != from || old.to != to || old.pulseScale != pulseScale;
}
