// import 'package:google_mobile_ads/google_mobile_ads.dart'; // Disabled for debug
import 'package:flutter/foundation.dart'; // For kIsWeb, defaultTargetPlatform

class AdState {
  static final ValueNotifier<bool> showAd = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> isGameActive = ValueNotifier<bool>(false);
  
  // Test Ad Unit IDs
  static String get interstitialAdUnitId => '';

  // static InterstitialAd? _interstitialAd; // Disabled
  static bool _isAdLoading = false;

  static Future<void> initialize() async {
     print("AdState Mobile (Debug Stub): Initialized");
    // await MobileAds.instance.initialize();
  }

  static void loadInterstitialAd() {
     print("AdState Mobile (Debug Stub): Load requested");
     /*
    if (kIsWeb) return; // Not used on web mock
    if (defaultTargetPlatform == TargetPlatform.android) {
        // ...
    }
    // ... logic disabled
    */
  }

  static void showInterstitialAd(VoidCallback onAdDismissed) {
    print("AdState Mobile (Debug Stub): Show requested -> calling dismissed");
    onAdDismissed();
    /*
    if (kIsWeb) { ... }
    if (_interstitialAd == null) { ... }
    _interstitialAd!.show();
    */
  }
}
