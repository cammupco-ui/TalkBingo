import 'package:flutter/material.dart';

// Global Key for Navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Password recovery flag: captured in main() before Supabase.initialize() consumes URL tokens
bool isPasswordRecoveryFromUrl = false;
