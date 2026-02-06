import 'package:flutter/foundation.dart';

class AdState {
  static final ValueNotifier<bool> showAd = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> isGameActive = ValueNotifier<bool>(false);

  static String get interstitialAdUnitId => '';

  static Future<void> initialize() async {
    // No-op for web
    debugPrint("AdState: initialize (Web Mock)");
  }

  static void loadInterstitialAd() {
    // No-op for web
    debugPrint("AdState: loadInterstitialAd (Web Mock)");
  }

  static void showInterstitialAd(VoidCallback onAdDismissed) {
    debugPrint("AdState: showInterstitialAd (Web Mock) - immediately dismissing");
    onAdDismissed();
  }
}
