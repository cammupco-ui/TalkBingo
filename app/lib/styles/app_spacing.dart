import 'package:flutter/material.dart';

class AppSpacing {
  // Screen Layout
  static const double screenPaddingHorizontal = 20.0;
  
  // Vertical Spacing
  static const double spacingXs = 8.0;   // Label to Input
  static const double spacingSm = 12.0;  // Section internal
  static const double spacingMd = 16.0;  // Title to Section
  static const double spacingLg = 24.0;  // Section to Section
  static const double spacingXl = 32.0;  // Major blocks

  // Component Dimensions
  static const double inputFieldHeight = 48.0;
  static const double buttonHeight = 56.0;
  static const double toggleButtonHeight = 48.0;

  // Paddings
  static const double inputPaddingHorizontal = 16.0;
  static const double inputPaddingVertical = 12.0;
  static const EdgeInsets inputContentPadding = EdgeInsets.symmetric(
    horizontal: inputPaddingHorizontal,
    vertical: inputPaddingVertical,
  );

  // Border Radius
  static const double borderRadiusSm = 8.0;
  static const double borderRadiusMd = 12.0;
  static const double borderRadiusLg = 20.0; // Toggle buttons

  // Typography
  static const double labelFontSize = 14.0;
  static const double inputFontSize = 16.0;
  static const double buttonFontSize = 16.0;
  static const double titleFontSize = 24.0;
  
  // Legacy Aliases (to prevent interactions breaking if used elsewhere)
  static const double screenPadding = screenPaddingHorizontal;
  static const double sectionSpacing = spacingLg;
  static const double labelSpacing = spacingXs;
  static const double inputHeight = inputFieldHeight;
  static const double buttonRadius = borderRadiusMd;
}
