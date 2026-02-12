import 'dart:math';
import 'package:flutter/material.dart';
import 'responsive_config.dart';

class TargetShooterConfig extends ResponsiveGameConfig {
  TargetShooterConfig(super.screenSize, {super.isGameArea});
  
  // Arrow Size (Increased for visibility)
  double get arrowWidth => max(
    safeGameArea.width * 0.06,  // 6% (was 5%)
    24.0,                        // Min 24px
  );
  
  double get arrowHeight => max(
    safeGameArea.width * 0.30,  // 30% (was 25%)
    120.0,                       // Min 120px
  );
  
  // Target Size — Circular (1:1), much larger
  double get targetWidth {
    switch (sizeClass) {
      case GameSize.small:  return safeGameArea.width * 0.35; // 35% (was 28%)
      case GameSize.medium: return safeGameArea.width * 0.38; // 38% (was 30%)
      case GameSize.large:  return safeGameArea.width * 0.40; // 40% (was 32%)
    }
  }
  
  double get targetHeight => targetWidth; // 1:1 Circular (was 2:1)
  
  // Player (Bow) Size — Larger for easier aiming
  double get playerSize => max(
    safeGameArea.width * 0.40, // 40% (was 35%)
    160.0, // Min 160px (was 140)
  );
  
  // Positions (Ratio Based)
  double get playerY => safeGameArea.height * 0.68; // Slightly higher for touch
  double get targetY => safeGameArea.height * 0.06; // Top 6%
  
  // Target Movement Speed
  double get targetSpeed => max(
    safeGameArea.width * 0.45, // Slightly slower for bigger target
    130.0,
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
  
  // Touch Threshold
  double get touchThreshold {
    switch (sizeClass) {
      case GameSize.small:  return 30.0;
      case GameSize.medium: return 40.0;
      case GameSize.large:  return 50.0;
    }
  }
  
  // Stuck Arrow Size (Slightly smaller than flying arrow)
  double get stuckArrowWidth => arrowWidth * 0.8;
  double get stuckArrowHeight => arrowHeight * 0.6;
}
