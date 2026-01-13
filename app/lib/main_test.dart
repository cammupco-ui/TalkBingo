import 'package:flutter/material.dart';
import 'package:talkbingo_app/test_harness/mini_game_test_screen.dart';

// Standalone Entry Point for Mini Game Testing
// Run with: flutter run -t lib/main_test.dart

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MiniGameTestApp());
}

class MiniGameTestApp extends StatelessWidget {
  const MiniGameTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Game Test Harness',
      theme: ThemeData.dark(),
      home: const MiniGameTestScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
