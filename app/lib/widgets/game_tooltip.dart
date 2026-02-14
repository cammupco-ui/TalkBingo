import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

/// A reusable animated speech-bubble tooltip for in-game contextual hints.
/// Auto-dismisses after [duration] and calls [onDismiss] when done.
class GameTooltip extends StatefulWidget {
  final String message;
  final VoidCallback? onDismiss;
  final Duration duration;
  final Alignment alignment;

  const GameTooltip({
    super.key,
    required this.message,
    this.onDismiss,
    this.duration = const Duration(seconds: 4),
    this.alignment = Alignment.center,
  });

  @override
  State<GameTooltip> createState() => _GameTooltipState();
}

class _GameTooltipState extends State<GameTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Auto-dismiss
    _dismissTimer = Timer(widget.duration - const Duration(milliseconds: 400), () {
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
    return SlideTransition(
      position: _slideAnim,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D3A),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.message,
                    style: GoogleFonts.alexandria(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF5F0D0),
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
