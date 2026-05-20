import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/services/subscription_service.dart';
import '../core/helpers/log_helper.dart';

/// ✅ Reusable AdMob Banner Widget
///
/// Features:
/// - Auto-hides for PRO subscribers (no ads, no space)
/// - Auto-refreshes based on AdMob's built-in refresh cycle
/// - Adaptive banner size (fills screen width automatically)
/// - Glassmorphic container that matches app design
/// - Handles load failures gracefully (shows nothing)
/// - ✨ Auto-switches between test/production ads using kReleaseMode
///
/// Usage:
/// ```dart
/// const AdBannerWidget()           // default bottom padding
/// const AdBannerWidget(padding: EdgeInsets.only(top: 16))
/// ```
class AdBannerWidget extends StatefulWidget {
  final EdgeInsetsGeometry padding;

  const AdBannerWidget({
    super.key,
    this.padding = const EdgeInsets.only(top: 16, bottom: 8),
  });

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  // ── Production Ad Unit ID ──
  static const String _bannerAdUnitId = 'ca-app-pub-8074008172106908/1237741843';

  // ── Test Ad Unit IDs (official Google test IDs) ──
  static String get _testAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2435281174';
    return _bannerAdUnitId;
  }

  // ── Auto-switch: Debug = test ads, Release = production ads ──
  static String get _adUnitId => kReleaseMode ? _bannerAdUnitId : _testAdUnitId;

  BannerAd? _bannerAd;
  // Use GetX reactive variable so Obx rebuilds when ad loads
  final RxBool _isAdLoaded = false.obs;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    // Don't load ads for PRO users
    final sub = Get.find<SubscriptionService>();
    if (sub.isPremium.value) return;

    // Get adaptive banner size based on screen width
    final screenWidth = Get.width;
    final adWidth = screenWidth.truncate();

    talker.info('📐 Banner: Loading adaptive banner with width=$adWidth');

    final adSize = AdSize(width: adWidth, height: 60);

    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          talker.info('✅ Banner ad loaded successfully (${(ad as BannerAd).size.width}x${ad.size.height})');
          _isAdLoaded.value = true;
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
          talker.error('🔴 Banner ad failed to load: ${error.message}');
          // Retry after 30 seconds
          Future.delayed(const Duration(seconds: 30), () {
            if (mounted) _loadBannerAd();
          });
        },
        onAdOpened: (ad) => talker.info('📺 Banner ad opened'),
        onAdClosed: (ad) => talker.info('📺 Banner ad closed'),
        onAdImpression: (ad) => talker.info('📊 Banner ad impression recorded'),
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _isAdLoaded.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sub = Get.find<SubscriptionService>();

    return Obx(() {
      // PRO users: completely hidden, no space taken
      if (sub.isPremium.value) return const SizedBox.shrink();

      // Ad not loaded yet: show nothing
      if (!_isAdLoaded.value || _bannerAd == null) return const SizedBox.shrink();

      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      return Padding(
        padding: widget.padding,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
          ),
        ),
      );
    });
  }
}
