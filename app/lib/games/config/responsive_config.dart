import 'package:flutter/material.dart';

enum GameSize { small, medium, large }

class ResponsiveGameConfig {
  final Size screenSize;
  final bool isGameArea; // If true, screenSize IS the safe area
  
  ResponsiveGameConfig(this.screenSize, {this.isGameArea = false});
  
  // Classify Screen Size
  GameSize get sizeClass {
    final width = screenSize.width;
    if (width < 375) return GameSize.small;
    if (width < 410) return GameSize.medium;
    return GameSize.large;
  }
  
  // Safe Game Area (Excluding Header/HUD)
  // Note: Values match the design spec but ensure safeArea is calculated safely
  // Safe Game Area (Excluding Header/HUD)
  // Note: Values match the design spec but ensure safeArea is calculated safely
  Size get safeGameArea {
    if (isGameArea) return screenSize;
    
    return Size(
      screenSize.width,
      screenSize.height - headerHeight - hudHeight - bottomPadding,
    );
  }
  
  // Responsive Header Height — proportional to screen height
  // Uses 10% of screen height with min/max clamps for visual balance
  double get headerHeight {
    final proportional = screenSize.height * 0.10;
    switch (sizeClass) {
      case GameSize.small: return proportional.clamp(50, 80);
      case GameSize.medium: return proportional.clamp(56, 90);
      case GameSize.large: return proportional.clamp(64, 100);
    }
  }
  
  // Responsive HUD Height
  double get hudHeight {
    switch (sizeClass) {
      case GameSize.small: return 40;
      case GameSize.medium: return 48;
      case GameSize.large: return 56;
    }
  }
  
  // Responsive Bottom Padding
  double get bottomPadding {
    switch (sizeClass) {
      case GameSize.small: return 16;
      case GameSize.medium: return 20;
      case GameSize.large: return 24;
    }
  }
  
  // Responsive Margin
  double get gameMargin {
    switch (sizeClass) {
      case GameSize.small: return 8;
      case GameSize.medium: return 12;
      case GameSize.large: return 16;
    }
  }
  
  // Minimum Touch Size (44x44 recommended)
  double get minTouchSize => 44.0;
}
