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

class _AdBannerWidgetState extends State<AdBannerWidget> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
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
  bool _isDisposed = false;
  bool _isAdLoadInitiated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isAdLoadInitiated && !_isDisposed) {
      _isAdLoadInitiated = true;
      final width = MediaQuery.sizeOf(context).width;

      // Delay ad loading by 500ms.
      // Now that the Chromium Engine is pre-warmed during the splash screen, 
      // we only need a small 500ms delay to allow normal page transition 
      // animations to finish smoothly before rendering the Platform View.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_isDisposed) {
          _loadBannerAd(width);
        }
      });
    }
  }

  void _loadBannerAd(double screenWidth) {
    // Don't load ads for PRO users
    final sub = Get.find<SubscriptionService>();
    if (sub.isPremium.value) return;

    // Get adaptive banner size based on screen width
    final adWidth = screenWidth.truncate();
    if (adWidth <= 0) return; // Safely prevent Google Mobile Ads crash on 0 width

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
            if (mounted && !_isDisposed) {
              try {
                _loadBannerAd(MediaQuery.sizeOf(context).width);
              } catch (_) {}
            }
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
    _isDisposed = true;
    final adToDispose = _bannerAd;
    _bannerAd = null;
    
    if (adToDispose != null) {
      // Delay disposal to prevent ANR (Signal 3) during native SDK race conditions
      // like firing onAdImpression right as the widget is unmounted.
      Future.delayed(const Duration(milliseconds: 1500), () {
        try {
          adToDispose.dispose();
        } catch (_) {}
      });
    }
    _isAdLoaded.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final sub = Get.find<SubscriptionService>();

    return Obx(() {
      // PRO users: completely hidden, no space taken
      if (sub.isPremium.value) return const SizedBox.shrink();

      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      final bool showAd = _isAdLoaded.value && _bannerAd != null;

      return Padding(
        padding: widget.padding,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: showAd
              ? Center(
                  child: AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        border: Border(
                          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08), width: 0.5),
                          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08), width: 0.5),
                        ),
                      ),
                      child: SizedBox(
                        width: _bannerAd!.size.width.toDouble(),
                        height: _bannerAd!.size.height.toDouble(),
                        child: AdWidget(ad: _bannerAd!),
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0), // 0 height placeholder that smoothly expands
        ),
      );

    });
  }
}
