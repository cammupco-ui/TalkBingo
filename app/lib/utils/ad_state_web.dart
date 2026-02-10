import 'package:flutter/foundation.dart';

class AdState {
  static final ValueNotifier<bool> showAd = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> isGameActive = ValueNotifier<bool>(false);

  static String get interstitialAdUnitId => '';
  static String get rewardedAdUnitId => '';

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

  static void loadRewardedAd() {
    // No-op for web
    debugPrint("AdState: loadRewardedAd (Web Mock)");
  }

  static void showRewardedAd({
    required VoidCallback onRewarded,
    required VoidCallback onDismissed,
  }) {
    debugPrint("AdState: showRewardedAd (Web Mock) - immediately rewarding");
    onRewarded();
    onDismissed();
  }
}
