import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb, defaultTargetPlatform

class AdState {
  static final ValueNotifier<bool> showAd = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> isGameActive = ValueNotifier<bool>(false);
  
  // Test Ad Unit IDs
  static String get interstitialAdUnitId {
    if (kIsWeb) return ''; // Not used on web mock
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Test Rewarded Ad ID
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // Test Rewarded Ad ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static InterstitialAd? _interstitialAd;
  static bool _isAdLoading = false;

  static RewardedAd? _rewardedAd;
  static bool _isRewardedAdLoading = false;

  static Future<void> initialize() async {
    if (kIsWeb) return; // Skip checking plugin on web
    await MobileAds.instance.initialize();
  }

  // ── Interstitial Ad ──

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

  // ── Rewarded Ad ──

  static void loadRewardedAd() {
    if (kIsWeb) return;
    if (_isRewardedAdLoading) return;
    _isRewardedAdLoading = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          print('RewardedAd loaded');
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('RewardedAd failed to load: $error');
          _rewardedAd = null;
          _isRewardedAdLoading = false;
        },
      ),
    );
  }

  static void showRewardedAd({
    required VoidCallback onRewarded,
    required VoidCallback onDismissed,
  }) {
    if (kIsWeb) {
      // Mock: immediately reward on web
      print("Ad Mock: Showing Rewarded Ad... (Mocked on Web)");
      onRewarded();
      onDismissed();
      return;
    }

    if (_rewardedAd == null) {
      print('Warning: Attempted to show rewarded ad before loaded.');
      onDismissed();
      loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (Ad ad) {
        print('RewardedAd dismissed.');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // Preload next one
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
        print('RewardedAd failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onDismissed();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        print('User earned reward: ${reward.amount} ${reward.type}');
        onRewarded();
      },
    );
  }
}
