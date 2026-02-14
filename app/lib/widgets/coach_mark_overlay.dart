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
    final bool textBelow = targetCenter.dy < screenSize.height * 0.5;

    // Text position
    final double textY = textBelow
        ? targetCenter.dy + (targetRect != null ? targetRect.height / 2 : 0) + 60
        : targetCenter.dy - (targetRect != null ? targetRect.height / 2 : 0) - 60;

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

              // ── 2. Curly arrow + text ──
              if (targetRect != null)
                Positioned.fill(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: CustomPaint(
                      painter: _CurlyArrowPainter(
                        from: Offset(screenSize.width / 2, textY + (textBelow ? -10 : 10)),
                        to: targetCenter,
                        color: _arrowColor.withOpacity(0.9),
                        pulseScale: _pulseAnim.value,
                        pointDown: textBelow,
                      ),
                    ),
                  ),
                ),

              // ── 3. Label text (no background) ──
              if (targetRect != null)
                Positioned(
                  left: 32,
                  right: 32,
                  top: textBelow ? textY : null,
                  bottom: textBelow ? null : screenSize.height - textY,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Transform.scale(
                      scale: 0.9 + (_pulseAnim.value - 0.85) * 0.33, // subtle pulse 0.9–1.0
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
                  opacity: 0.5 + (_pulseAnim.value - 0.85) * 1.67, // 0.5–1.0
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
    // Try GameSession first
    try {
      final lang = AppLocalizations.get('_lang_test_marker');
      // If the marker doesn't exist, fall back to PlatformDispatcher
    } catch (_) {}

    // Use PlatformDispatcher directly for coach marks
    try {
      final locale = ui.PlatformDispatcher.instance.locale;
      if (locale.languageCode == 'ko') return 'ko';
    } catch (_) {}

    // Also check via GameSession (it reads same source)
    try {
      // GameSession().language already does this, but let's trust it
      final gameSessionLang = _getCurrentLanguageFromSession();
      return gameSessionLang;
    } catch (_) {}

    return 'en';
  }

  String _getCurrentLanguageFromSession() {
    // Access through the localization utility (which reads GameSession)
    // If we can get a known Korean key and it returns Korean text, we know it's KO
    final testVal = AppLocalizations.get('coach_skip');
    if (testVal == '건너뛰기') return 'ko';
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

/// Curly pig-tail dotted arrow painter
class _CurlyArrowPainter extends CustomPainter {
  final Offset from; // near the text
  final Offset to;   // target center
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
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Build the curly path from text area toward target
    final path = _buildCurlyPath(from, to);

    // Convert to dashed path
    final dashedPath = _dashPath(path, dashLength: 6, gapLength: 4);
    canvas.drawPath(dashedPath, paint);

    // Draw arrowhead at the end (at 'to')
    _drawArrowhead(canvas, from, to, paint);

    // Pulsing dot at arrow tip
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final dotRadius = 4.0 * pulseScale;
    canvas.drawCircle(to, dotRadius, dotPaint);

    // Outer glow on tip
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(to, dotRadius * 1.8, glowPaint);
  }

  Path _buildCurlyPath(Offset start, Offset end) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final dist = sqrt(dx * dx + dy * dy);

    // Create a gentle S-curve with a pig-tail loop
    // Control points for an expressive curly arrow

    // Midpoint
    final mx = (start.dx + end.dx) / 2;
    final my = (start.dy + end.dy) / 2;

    // Perpendicular offset for the curl
    final perpX = -dy / dist;
    final perpY = dx / dist;
    final curlAmount = dist * 0.25; // How far the curl extends sideways

    // First curve: from start, curling to one side
    final cp1x = start.dx + dx * 0.15 + perpX * curlAmount;
    final cp1y = start.dy + dy * 0.15 + perpY * curlAmount;

    // Pig-tail: small loop near the middle
    final loopX = mx + perpX * curlAmount * 0.8;
    final loopY = my + perpY * curlAmount * 0.8;

    // Second curve: from loop back toward target
    final cp2x = mx - perpX * curlAmount * 0.4;
    final cp2y = my - perpY * curlAmount * 0.4;

    final cp3x = end.dx + perpX * curlAmount * 0.3;
    final cp3y = end.dy + perpY * curlAmount * 0.3;

    // Build the curly S-shape with loop
    path.cubicTo(cp1x, cp1y, loopX, loopY, mx, my);
    path.cubicTo(cp2x, cp2y, cp3x, cp3y, end.dx, end.dy);

    return path;
  }

  Path _dashPath(Path source, {double dashLength = 6, double gapLength = 4}) {
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

  void _drawArrowhead(Canvas canvas, Offset from, Offset to, Paint paint) {
    // Direction vector from near-end to tip
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) return;

    final ux = dx / dist;
    final uy = dy / dist;

    // Arrowhead size
    const headLen = 12.0;
    const headWidth = 6.0;

    final basePt = Offset(to.dx - ux * headLen, to.dy - uy * headLen);
    // Perpendicular
    final px = -uy;
    final py = ux;

    final left = Offset(basePt.dx + px * headWidth, basePt.dy + py * headWidth);
    final right = Offset(basePt.dx - px * headWidth, basePt.dy - py * headWidth);

    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final headPath = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(headPath, headPaint);
  }

  @override
  bool shouldRepaint(covariant _CurlyArrowPainter old) =>
      old.from != from || old.to != to || old.pulseScale != pulseScale;
}
