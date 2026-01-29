import 'dart:math';
import 'package:flutter/material.dart';
import 'responsive_config.dart';

class TargetShooterConfig extends ResponsiveGameConfig {
  TargetShooterConfig(super.screenSize, {super.isGameArea});
  
  // Arrow Size (Ratio + Min)
  double get arrowWidth => max(
    safeGameArea.width * 0.05,  // 5%
    20.0,                        // Min 20px
  );
  
  double get arrowHeight => max(
    safeGameArea.width * 0.25,  // 25% (Relative to width for aspect)
    100.0,                       // Min 100px
  );
  
  // Target Size (By Screen Class) - Reduced for better balance
  double get targetWidth {
    switch (sizeClass) {
      case GameSize.small:  return safeGameArea.width * 0.28; // 28%
      case GameSize.medium: return safeGameArea.width * 0.30; // 30%
      case GameSize.large:  return safeGameArea.width * 0.32; // 32%
    }
  }
  
  double get targetHeight => targetWidth * 0.5; // 2:1 Ratio
  
  // Player (Bow) Size - Increased for better visibility and touch
  double get playerSize => max(
    safeGameArea.width * 0.35, // Increased from 30% to 35%
    140.0, // Increased min from 120px to 140px
  );
  
  // Positions (Ratio Based)
  // Player positioned higher for easier touch access
  double get playerY => safeGameArea.height * 0.70; // 70% from top (was at bottom)
  double get targetY => safeGameArea.height * 0.08; // Top 8% (slightly lower for visibility)
  
  // Target Movement Speed (Pixels per Second) - Ensure minimum speed
  double get targetSpeed => max(
    safeGameArea.width * 0.5, // Moves 50% of width per sec
    150.0, // Minimum 150px/sec to ensure visible movement
  );
  
  // Aim Line Length
  double get aimLineLength {
    switch (sizeClass) {
      case GameSize.small:  return 120.0;
      case GameSize.medium: return 150.0;
      case GameSize.large:  return 180.0;
    }
  }
  
  // Power Bar Width
  double get powerBarWidth {
    switch (sizeClass) {
      case GameSize.small:  return safeGameArea.width * 0.5;
      case GameSize.medium: return safeGameArea.width * 0.6;
      case GameSize.large:  return safeGameArea.width * 0.7;
    }
  }
  
  double get powerBarHeight => 20.0;
  
  // Touch Threshold (Drag start distance)
  double get touchThreshold {
    switch (sizeClass) {
      case GameSize.small:  return 30.0;
      case GameSize.medium: return 40.0;
      case GameSize.large:  return 50.0;
    }
  }
}
