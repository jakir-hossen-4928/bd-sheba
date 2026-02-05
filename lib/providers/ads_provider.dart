import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/ad_helper.dart';

class AdState {
  final NativeAd? nativeAd;
  final InterstitialAd? exitAd;
  final bool isExitAdLoading;

  AdState({this.nativeAd, this.exitAd, this.isExitAdLoading = false});

  AdState copyWith({
    NativeAd? nativeAd,
    InterstitialAd? exitAd,
    bool? isExitAdLoading,
  }) {
    return AdState(
      nativeAd: nativeAd ?? this.nativeAd,
      exitAd: exitAd ?? this.exitAd,
      isExitAdLoading: isExitAdLoading ?? this.isExitAdLoading,
    );
  }
}

class AdsNotifier extends Notifier<AdState> {
  @override
  AdState build() {
    ref.onDispose(() {
      state.nativeAd?.dispose();
      state.exitAd?.dispose();
    });
    return AdState();
  }

  void loadNativeAd(BuildContext context) async {
    try {
      if (!await AdHelper.hasConnection()) return;

      NativeAd(
        adUnitId: AdHelper.nativeAdUnitId,
        request: const AdRequest(),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
          mainBackgroundColor: Theme.of(context).colorScheme.surface,
          cornerRadius: 12.0,
        ),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            state = state.copyWith(nativeAd: ad as NativeAd);
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            debugPrint('NativeAd failed to load: $error');
          },
        ),
      ).load();
    } catch (e) {
      debugPrint('Error in loadNativeAd: $e');
    }
  }

  void loadExitAd() async {
    try {
      if (state.isExitAdLoading || state.exitAd != null) return;
      if (!await AdHelper.hasConnection()) return;

      state = state.copyWith(isExitAdLoading: true);

      InterstitialAd.load(
        adUnitId: AdHelper.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            state = state.copyWith(exitAd: ad, isExitAdLoading: false);
          },
          onAdFailedToLoad: (error) {
            state = state.copyWith(isExitAdLoading: false);
            debugPrint('InterstitialAd failed to load: $error');
          },
        ),
      );
    } catch (e) {
      debugPrint('Error in loadExitAd: $e');
      state = state.copyWith(isExitAdLoading: false);
    }
  }

  Future<void> showExitAd(VoidCallback onClosed) async {
    try {
      if (state.exitAd == null) {
        onClosed();
        return;
      }

      state.exitAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          state = state.copyWith(exitAd: null);
          onClosed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          state = state.copyWith(exitAd: null);
          onClosed();
        },
      );

      await state.exitAd!.show();
    } catch (e) {
      debugPrint('Error in showExitAd: $e');
      onClosed();
    }
  }
}

final adsProvider = NotifierProvider<AdsNotifier, AdState>(AdsNotifier.new);
