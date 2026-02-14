import 'package:shared_preferences/shared_preferences.dart';

/// Tracks visit counts and "don't show again" state for coach marks.
class OnboardingService {
  static const int _maxVisits = 3;

  // ── Visit Count ──

  static Future<int> getVisitCount(String screen) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${screen}_visit_count') ?? 0;
  }

  static Future<void> incrementVisit(String screen) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('${screen}_visit_count') ?? 0;
    await prefs.setInt('${screen}_visit_count', current + 1);
  }

  // ── Coach Mark Visibility ──

  static Future<bool> shouldShowCoachMark(String screen) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('coach_dismissed_$screen') ?? false;
    if (dismissed) return false;
    final visits = prefs.getInt('${screen}_visit_count') ?? 0;
    return visits < _maxVisits;
  }

  static Future<void> dismissForever(String screen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('coach_dismissed_$screen', true);
  }

  // ── Debug: Reset (for testing) ──

  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final screen in ['home', 'game']) {
      await prefs.remove('${screen}_visit_count');
      await prefs.remove('coach_dismissed_$screen');
    }
  }
}
