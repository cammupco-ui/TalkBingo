import 'package:flutter/material.dart';

/// A small, non-intrusive glowing dot that shows the opponent's touch position.
/// Host (A) = pink glow, Guest (B) = purple glow.
/// 
/// This widget should be placed as a top-level overlay in the game screen Stack.
/// It captures touch/pointer events from the current player and renders
/// the opponent's cursor position received via the game session.
class GlowingCursorOverlay extends StatefulWidget {
  final double opponentX; // Normalized 0-1
  final double opponentY; // Normalized 0-1
  final bool opponentVisible;
  final String opponentRole; // 'A' or 'B'
  final void Function(double normalizedX, double normalizedY) onPointerMove;
  final VoidCallback onPointerUp;

  const GlowingCursorOverlay({
    super.key,
    required this.opponentX,
    required this.opponentY,
    required this.opponentVisible,
    required this.opponentRole,
    required this.onPointerMove,
    required this.onPointerUp,
  });

  @override
  State<GlowingCursorOverlay> createState() => _GlowingCursorOverlayState();
}

class _GlowingCursorOverlayState extends State<GlowingCursorOverlay>
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Listener(
          behavior: HitTestBehavior.translucent, // Let touches pass through
          onPointerMove: (event) {
            // Normalize position to 0-1 range
            final nx = (event.localPosition.dx / width).clamp(0.0, 1.0);
            final ny = (event.localPosition.dy / height).clamp(0.0, 1.0);
            widget.onPointerMove(nx, ny);
          },
          onPointerUp: (_) => widget.onPointerUp(),
          onPointerCancel: (_) => widget.onPointerUp(),
          child: Stack(
            children: [
              // Opponent cursor dot
              if (widget.opponentVisible)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  left: (widget.opponentX * width) - 7, // Center the 14px dot
                  top: (widget.opponentY * height) - 7,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: widget.opponentVisible ? 1.0 : 0.0,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulse = 0.5 + (_pulseController.value * 0.5);
                        final isHost = widget.opponentRole == 'A';
                        final dotColor = isHost
                            ? const Color(0xFFFF4081) // Pink for Host
                            : const Color(0xFF7C4DFF); // Purple for Guest

                        return IgnorePointer(
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dotColor.withValues(alpha: 0.7),
                              boxShadow: [
                                // Inner glow
                                BoxShadow(
                                  color: dotColor.withValues(alpha: 0.6 * pulse),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                                // Outer glow
                                BoxShadow(
                                  color: dotColor.withValues(alpha: 0.3 * pulse),
                                  blurRadius: 16,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
