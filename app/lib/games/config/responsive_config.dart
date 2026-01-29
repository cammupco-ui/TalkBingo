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
  
  // Responsive Header Height
  double get headerHeight {
    switch (sizeClass) {
      case GameSize.small: return 50;
      case GameSize.medium: return 56;
      case GameSize.large: return 64;
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
