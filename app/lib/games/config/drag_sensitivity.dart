import 'responsive_config.dart';

// Sensitivity Configuration based on Screen Size
class DragSensitivity {
  final ResponsiveGameConfig config;
  
  DragSensitivity(this.config);
  
  // Minimum Drag Distance (Prevent accidental touches)
  double get minDragDistance {
    switch (config.sizeClass) {
      case GameSize.small:  return 5.0;  // Sensitive
      case GameSize.medium: return 8.0;
      case GameSize.large:  return 10.0; // Less sensitive
    }
  }
  
  // Power Scale Multiplier (Drag Distance -> Power)
  double get powerScale {
    switch (config.sizeClass) {
      case GameSize.small:  return 1.2; // Amplify power
      case GameSize.medium: return 1.0;
      case GameSize.large:  return 0.9; // Reduce power
    }
  }
}
