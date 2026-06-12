import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../helpers/log_helper.dart';
import 'subscription_service.dart';

/// ✅ Production-Ready Rewarded Ad Service
/// 
/// Architecture:
/// - Uses Google AdMob Rewarded Ads for one-time feature unlocks.
/// - Fully integrated with SubscriptionService: PRO users NEVER see ads.
/// - Pre-loads ads for instant display when user taps the video icon.
/// - Manages temporary feature unlocks per session (resets on app restart).
/// - ✨ Auto-switches between test/production ads using kReleaseMode
///
/// Reward: 1 × premium_feature (as configured in AdMob console)
class RewardedAdService extends GetxService {
  // ── Ad Unit ID (Production) ──
  static const String _rewardedAdUnitId = 'ca-app-pub-8074008172106908/2218439573';

  // ── Test Ad Unit ID (for development/debugging) ──
  static String get _testAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/5224354917';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712485313';
    return _rewardedAdUnitId;
  }

  // ── Auto-switch: Debug = test ads, Release = production ads ──
  static String get _adUnitId => kReleaseMode ? _rewardedAdUnitId : _testAdUnitId;

  // ── State ──
  RewardedAd? _rewardedAd;
  final isAdLoaded = false.obs;
  final isAdLoading = false.obs;

  // ── Temporary Feature Unlocks (session-scoped) ──
  final unlockedFeatures = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // ✅ Performance Fix: Defer AdMob video preloading by 3 seconds.
    // This prevents Android's Native MediaCodec from starving the UI thread
    // during cold boot (which causes a massive ~46 skipped frames freeze).
    Future.delayed(const Duration(seconds: 3), () {
      _loadAd();
    });
  }

  /// Check if a specific feature has been temporarily unlocked
  bool isFeatureUnlocked(String featureKey) {
    // PRO users always have access
    if (Get.find<SubscriptionService>().isPremium.value) return true;
    return unlockedFeatures.contains(featureKey);
  }

  /// Pre-load a rewarded ad for instant display
  void _loadAd() {
    if (isAdLoading.value || isAdLoaded.value) return;
    
    // Don't load ads for PRO users
    if (Get.find<SubscriptionService>().isPremium.value) return;

    isAdLoading.value = true;
    talker.info('📺 Loading rewarded ad...');

    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          isAdLoaded.value = true;
          isAdLoading.value = false;
          talker.info('✅ Rewarded ad loaded successfully');

          // Set up fullscreen callbacks
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              talker.info('📺 Rewarded ad dismissed');
              ad.dispose();
              _rewardedAd = null;
              isAdLoaded.value = false;
              // Pre-load next ad
              _loadAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              talker.error('🔴 Rewarded ad failed to show: $error');
              ad.dispose();
              _rewardedAd = null;
              isAdLoaded.value = false;
              _loadAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          isAdLoading.value = false;
          isAdLoaded.value = false;
          talker.error('🔴 Rewarded ad failed to load: ${error.message}');
          // Retry after delay
          Future.delayed(const Duration(seconds: 10), _loadAd);
        },
      ),
    );
  }

  /// Show the rewarded ad and unlock a feature on completion
  /// 
  /// [featureKey] - unique identifier for the feature to unlock
  /// [onRewarded] - callback when user earns the reward
  /// [onFailed] - callback when ad fails to show
  Future<void> showAdToUnlock({
    required String featureKey,
    required Function() onRewarded,
    Function()? onFailed,
  }) async {
    // PRO users skip ads entirely
    if (Get.find<SubscriptionService>().isPremium.value) {
      onRewarded();
      return;
    }

    // Already unlocked this session
    if (unlockedFeatures.contains(featureKey)) {
      onRewarded();
      return;
    }

    if (_rewardedAd == null) {
      talker.warning('⚠️ No rewarded ad available');
      onFailed?.call();
      // Try to load one for next time
      _loadAd();
      return;
    }

    await _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        talker.info('🎁 User earned reward: ${reward.amount} × ${reward.type}');
        unlockedFeatures.add(featureKey);
        onRewarded();
      },
    );
  }

  /// Force reload an ad (e.g. after a failed attempt)
  void retryLoadAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    isAdLoaded.value = false;
    isAdLoading.value = false;
    _loadAd();
  }

  @override
  void onClose() {
    _rewardedAd?.dispose();
    super.onClose();
  }
}
