import 'dart:ui';
import 'package:flutter/material.dart';

/// Base class for any object in the mini-game
class GameEntity {
  double x;
  double y;
  double width;
  double height;
  double vx; // Velocity X
  double vy; // Velocity Y
  Color color;
  bool isDead = false;

  GameEntity({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.vx = 0,
    this.vy = 0,
    this.color = Colors.blue,
  });

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
  }

  void render(Canvas canvas) {
    final paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(x, y, width, height), paint);
  }
  
  Rect get rect => Rect.fromLTWH(x, y, width, height);
}

/// Simple Physics Utilities
class PhysicsUtils {
  
  static bool checkCollision(GameEntity a, GameEntity b) {
    return a.rect.overlaps(b.rect);
  }

  static bool checkCircleCollision(GameEntity a, GameEntity b) {
    // Assuming width is diameter
    double r1 = a.width / 2;
    double r2 = b.width / 2;
    double cx1 = a.x + r1;
    double cy1 = a.y + r1;
    double cx2 = b.x + r2;
    double cy2 = b.y + r2;

    double dx = cx1 - cx2;
    double dy = cy1 - cy2;
    double distance = dx*dx + dy*dy;
    
    return distance < (r1 + r2) * (r1 + r2);
  }
}
