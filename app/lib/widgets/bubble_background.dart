import 'package:flutter/material.dart';
import 'dart:math';

class BubbleBackground extends StatefulWidget {
  final bool interactive;
  final Widget child;

  const BubbleBackground({
    super.key,
    this.interactive = true,
    required this.child,
  });

  @override
  State<BubbleBackground> createState() => _BubbleBackgroundState();
}

class _BubbleBackgroundState extends State<BubbleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Bubble> _bubbles = [];
  final Random _random = Random();
  Offset? _touchPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    // Initialize bubbles
    for (int i = 0; i < 20; i++) { // Generate 20 bubbles
      _bubbles.add(Bubble(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 0.1 + 0.05, // 5% to 15% of screen width
        speed: _random.nextDouble() * 0.002 + 0.001,
        color: _randomColor(),
      ));
    }
  }

  Color _randomColor() {
    // TalkBingo Color Palette
    List<Color> colors = [
      const Color(0xFFBD0558).withOpacity(0.2), // Host Dark
      const Color(0xFF430887).withOpacity(0.2), // Guest Primary
      const Color(0xFFFF0077).withOpacity(0.15), // Accent Pink
      const Color(0xFF6B14EC).withOpacity(0.15), // Accent Purple
      Colors.white.withOpacity(0.1),
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: widget.interactive ? (details) {
        setState(() {
           // Normalize touch position 0..1
           final size = MediaQuery.of(context).size;
           _touchPosition = Offset(
             details.localPosition.dx / size.width,
             details.localPosition.dy / size.height
           );
        });
      } : null,
      onPanEnd: (_) => setState(() => _touchPosition = null),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Color
          Container(
            decoration: const BoxDecoration(
               gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Color(0xFF1A0B2E)], // Deep Purple Black
               ),
            ),
          ),
          
          // Bubbles
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: BubblePainter(
                  bubbles: _bubbles,
                  controllerValue: _controller.value,
                  touchPosition: _touchPosition,
                ),
                size: Size.infinite,
              );
            },
          ),
          
          // Content
          widget.child,
        ],
      ),
    );
  }
}

class Bubble {
  double x;
  double y;
  double size;
  double speed;
  Color color;

  Bubble({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
  });
}

class BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;
  final double controllerValue;
  final Offset? touchPosition;

  BubblePainter({
    required this.bubbles,
    required this.controllerValue,
    this.touchPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var bubble in bubbles) {
      // Update Y Position (Rise Up)
      double currentY = (bubble.y - controllerValue * bubble.speed * 50) % 1.0;
      if (currentY < 0) currentY += 1.0;
      
      double currentX = bubble.x;
      
      // Interactive effect: move away from touch
      if (touchPosition != null) {
        double dist = sqrt(pow(currentX - touchPosition!.dx, 2) + pow(currentY - touchPosition!.dy, 2));
        if (dist < 0.2) {
           double angle = atan2(currentY - touchPosition!.dy, currentX - touchPosition!.dx);
           currentX += cos(angle) * 0.01;
           currentY += sin(angle) * 0.01;
        }
      }

      // Draw
      final paint = Paint()..color = bubble.color;
      canvas.drawCircle(
        Offset(currentX * size.width, currentY * size.height), 
        bubble.size * size.width / 2, 
        paint
      );
    }
  }

  @override
  bool shouldRepaint(covariant BubblePainter oldDelegate) => true;
}
