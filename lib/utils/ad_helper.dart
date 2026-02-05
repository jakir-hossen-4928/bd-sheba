import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AdHelper {
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-7337713061573645/3878057173';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get nativeAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/2247696110';
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-7337713061573645/1507054447';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get appOpenAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/9257399521';
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-7337713061573645/1687008109';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/1033173712';
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-7337713061573645/9163007590';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static Future<bool> hasConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  // App Open Ad variables
  static AppOpenAd? _appOpenAd;
  static bool _isShowingAd = false;
  static DateTime? _lastAdShowTime;
  static DateTime? _appOpenAdLoadTime;

  /// Check if the loaded ad is still valid (App Open ads expire after 4 hours)
  static bool get _isAdAvailable {
    if (_appOpenAd == null) return false;
    if (_appOpenAdLoadTime == null) return false;
    return DateTime.now().difference(_appOpenAdLoadTime!).inHours < 4;
  }

  static Future<void> loadAppOpenAd() async {
    try {
      if (!await hasConnection()) return;
      if (_appOpenAd != null && _isAdAvailable) return;

      await AppOpenAd.load(
        adUnitId: appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _appOpenAdLoadTime = DateTime.now();
            debugPrint('AppOpenAd loaded successfully');
          },
          onAdFailedToLoad: (error) {
            debugPrint('AppOpenAd failed to load: $error');
            _appOpenAd = null;
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading AppOpenAd: $e');
    }
  }

  static void showAppOpenAdIfAvailable() {
    try {
      if (!_isAdAvailable || _isShowingAd) {
        loadAppOpenAd();
        return;
      }

      if (_lastAdShowTime != null &&
          DateTime.now().difference(_lastAdShowTime!).inMinutes < 1) {
        return;
      }

      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          _isShowingAd = true;
        },
        onAdDismissedFullScreenContent: (ad) {
          _isShowingAd = false;
          ad.dispose();
          _appOpenAd = null;
          _appOpenAdLoadTime = null;
          _lastAdShowTime = DateTime.now();
          loadAppOpenAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          _isShowingAd = false;
          ad.dispose();
          _appOpenAd = null;
          loadAppOpenAd();
        },
      );

      _appOpenAd!.show();
    } catch (e) {
      debugPrint('Error showing AppOpenAd: $e');
      _isShowingAd = false;
    }
  }
}
