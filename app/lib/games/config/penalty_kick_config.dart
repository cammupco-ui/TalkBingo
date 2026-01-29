import 'dart:math';
import 'package:flutter/material.dart';
import 'responsive_config.dart';

class PenaltyKickConfig extends ResponsiveGameConfig {
  PenaltyKickConfig(super.screenSize, {super.isGameArea});
  
  // Ball Size
  double get ballSize => max(
    safeGameArea.width * 0.12,
    50.0, // Min Size
  );
  
  // Goalie Width
  double get goalieWidth {
    switch (sizeClass) {
      case GameSize.small:  return safeGameArea.width * 0.35;
      case GameSize.medium: return safeGameArea.width * 0.40;
      case GameSize.large:  return safeGameArea.width * 0.45;
    }
  }
  
  double get goalieHeight => goalieWidth * 0.5; // 2:1 Ratio
  
  // Goal Width
  double get goalWidth {
    switch (sizeClass) {
      case GameSize.small:  return safeGameArea.width * 0.70;
      case GameSize.medium: return safeGameArea.width * 0.75;
      case GameSize.large:  return safeGameArea.width * 0.80;
    }
  }
  
  double get goalHeight => safeGameArea.height * 0.25; // Top 25%
  
  // Positions
  double get ballStartY => safeGameArea.height * 0.85;
  double get goalieY => safeGameArea.height * 0.10;
  double get goalY => 0.0;
  
  // Goalie Movement Limits
  double get goalieMinX => gameMargin;
  double get goalieMaxX => safeGameArea.width - goalieWidth - gameMargin;
  
  // Goalie Speed (Pixels per sec)
  double get goalieSpeed {
    switch (sizeClass) {
      case GameSize.small:  return 150.0;
      case GameSize.medium: return 180.0;
      case GameSize.large:  return 200.0;
    }
  }
  
  // Trajectory Points Count
  int get trajectoryPoints {
    switch (sizeClass) {
      case GameSize.small:  return 8;
      case GameSize.medium: return 10;
      case GameSize.large:  return 12;
    }
  }
  
  // Shot Power Multiplier
  double get shotPowerMultiplier {
    switch (sizeClass) {
      case GameSize.small:  return 0.50;
      case GameSize.medium: return 0.55;
      case GameSize.large:  return 0.60;
    }
  }
}
