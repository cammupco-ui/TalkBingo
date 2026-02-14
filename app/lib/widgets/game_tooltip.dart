import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

/// A floating tooltip that appears near the user's tap position.
/// Bright, vibrant text with a subtle glow — no heavy background.
/// Auto-dismisses after [duration] and calls [onDismiss] when done.
class GameTooltip extends StatefulWidget {
  final String message;
  final VoidCallback? onDismiss;
  final Duration duration;
  final Offset? tapPosition; // Screen-relative position of the tap

  const GameTooltip({
    super.key,
    required this.message,
    this.onDismiss,
    this.duration = const Duration(seconds: 3),
    this.tapPosition,
  });

  @override
  State<GameTooltip> createState() => _GameTooltipState();
}

class _GameTooltipState extends State<GameTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Auto-dismiss
    _dismissTimer = Timer(widget.duration - const Duration(milliseconds: 350), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: GestureDetector(
          onTap: () {
            _dismissTimer?.cancel();
            _controller.reverse().then((_) {
              widget.onDismiss?.call();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.message,
                    style: GoogleFonts.alexandria(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFFE066), // Bright golden yellow
                      shadows: [
                        Shadow(
                          color: Colors.orangeAccent.withOpacity(0.7),
                          blurRadius: 8,
                        ),
                      ],
                      textStyle: const TextStyle(
                        fontFamilyFallback: ['EliceDigitalBaeum'],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
