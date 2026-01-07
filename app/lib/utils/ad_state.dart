import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb

class AdState {
  static final ValueNotifier<bool> showAd = ValueNotifier<bool>(true);
  
  // Test Ad Unit IDs
  static String get interstitialAdUnitId {
    if (kIsWeb) return ''; // Not used on web mock
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static InterstitialAd? _interstitialAd;
  static bool _isAdLoading = false;

  static Future<void> initialize() async {
    if (kIsWeb) return; // Skip checking plugin on web
    await MobileAds.instance.initialize();
  }

  static void loadInterstitialAd() {
    if (kIsWeb) return; // Mock on web
    if (_isAdLoading) return;
    _isAdLoading = true;
    
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          print('$ad loaded');
          _interstitialAd = ad;
          _isAdLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('InterstitialAd failed to load: $error');
          _interstitialAd = null;
          _isAdLoading = false;
        },
      ),
    );
  }

  static void showInterstitialAd(VoidCallback onAdDismissed) {
    if (kIsWeb) {
      // Mock Ad for Web
      print("Ad Mock: Showing Interstitial Ad... (Skipped on Web)");
      onAdDismissed();
      return;
    }

    if (_interstitialAd == null) {
      print('Warning: Attempted to show interstitial before loaded.');
      onAdDismissed();
      loadInterstitialAd(); // Reload for next time
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd(); // Preload next one
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onAdDismissed();
      },
    );

    _interstitialAd!.show();
  }
}
