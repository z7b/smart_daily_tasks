import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/services/rewarded_ad_service.dart';
import '../../subscription/views/premium_view.dart';
import '../../../widgets/ad_banner_widget.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Get.locale?.languageCode == 'ar';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Section Header
        _sectionHeader(context, 'settings'.tr),
        const SizedBox(height: 8),

        // ─── Appearance Group ─────────────────────────
        _groupTitle(context, 'appearance'.tr),
        const SizedBox(height: 8),
        _buildGroupedContainer(
          context,
          children: [
            _buildSwitchTile(
              context,
              title: 'theme_mode'.tr,
              icon: CupertinoIcons.moon_fill,
              iconBgColor: const Color(0xFF5E5CE6),
              value: controller.isDarkMode,
              onChanged: (_) => controller.toggleTheme(),
            ),
            _divider(context),
            _buildNavigationTile(
              context,
              title: 'font_type'.tr,
              icon: CupertinoIcons.textformat,
              iconBgColor: const Color(0xFF007AFF),
              value: controller.fontType,
              onTap: () => controller.changeFontType(),
              isAr: isAr,
            ),
            _divider(context),
            _buildNavigationTile(
              context,
              title: 'font_size'.tr,
              icon: CupertinoIcons.textformat_size,
              iconBgColor: const Color(0xFF34C759),
              valueBuilder: () => controller.fontSize.value.tr,
              onTap: () => controller.changeFontSize(),
              isAr: isAr,
            ),
            _divider(context),
            _buildNumberFormatTile(context),
          ],
        ),
        const SizedBox(height: 24),

        // ─── General Group ────────────────────────────
        _groupTitle(context, 'general'.tr),
        const SizedBox(height: 8),
        _buildGroupedContainer(
          context,
          children: [
            _buildNavigationTile(
              context,
              title: 'first_day_of_week'.tr,
              icon: CupertinoIcons.calendar_today,
              iconBgColor: const Color(0xFFFF9500),
              valueBuilder: () => controller.firstDayOfWeek.value.tr,
              onTap: () => controller.changeFirstDayOfWeek(),
              isAr: isAr,
            ),
            _divider(context),
            _buildNavigationTile(
              context,
              title: 'language'.tr,
              icon: CupertinoIcons.globe,
              iconBgColor: const Color(0xFF007AFF),
              valueBuilder: () => controller.currentLanguage.value.tr,
              onTap: () => controller.showLanguagePicker(),
              isAr: isAr,
            ),
            _divider(context),
            _buildStartScreenTile(context, isAr),
          ],
        ),
        const SizedBox(height: 16),

        // ─── Banner Ad (above Security) ──────────────
        const AdBannerWidget(
          padding: EdgeInsets.symmetric(vertical: 8),
        ),

        const SizedBox(height: 16),

        // ─── Security Group ───────────────────────────
        _groupTitle(context, 'security'.tr),
        const SizedBox(height: 8),
        _buildGroupedContainer(
          context,
          children: [
            _buildSwitchTile(
              context,
              title: 'app_lock'.tr,
              icon: CupertinoIcons.lock_fill,
              iconBgColor: const Color(0xFFFF3B30),
              value: controller.appLock,
              onChanged: (val) => controller.toggleAppLock(val),
              onTap: () => controller.toggleAppLock(),
            ),
            _divider(context),
            _buildScreenshotTile(context),
            _divider(context),
            Obx(() {
              final isStable = controller.notificationStatus.value == 'amazing';
              return _buildNavigationTile(
                context,
                title: 'notification_stability'.tr,
                icon: isStable ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.battery_100,
                iconBgColor: isStable ? const Color(0xFF34C759) : const Color(0xFF32ADE6),
                valueBuilder: () => controller.notificationStatus.value.tr,
                onTap: () => controller.checkNotificationStability(),
                isAr: isAr,
              );
            }),
          ],
        ),
        const SizedBox(height: 24),

        // ─── Data Group ───────────────────────────────
        _groupTitle(context, 'data'.tr),
        const SizedBox(height: 8),
        _buildGroupedContainer(
          context,
          children: [
            _buildNavigationTile(
              context,
              title: 'export_data'.tr,
              icon: CupertinoIcons.share,
              iconBgColor: const Color(0xFF34C759),
              onTap: () => controller.createBackup(),
              isAr: isAr,
            ),
            _divider(context),
            _buildNavigationTile(
              context,
              title: 'import_data'.tr,
              icon: CupertinoIcons.tray_arrow_down_fill,
              iconBgColor: const Color(0xFF007AFF),
              onTap: () => controller.restoreBackup(),
              isAr: isAr,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ─── Smart Assistant Group ──────────────────────
        _groupTitle(context, 'smart_assistant'.tr),
        const SizedBox(height: 8),
        _buildGroupedContainer(
          context,
          children: [
            _buildNavigationTile(
              context,
              title: 'assistant'.tr,
              icon: CupertinoIcons.sparkles,
              iconBgColor: const Color(0xFFAF52DE),
              onTap: () => Get.toNamed('/assistant'),
              isAr: isAr,
            ),
          ],
        ),

        const SizedBox(height: 120),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
      ),
    );
  }

  Widget _groupTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  Widget _buildGroupedContainer(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor.withAlpha(20));
  }

  Widget _buildSwitchTile(BuildContext context, {required String title, required IconData icon, required Color iconBgColor, required RxBool value, required ValueChanged<bool> onChanged, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(width: 32, height: 32, decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.white, size: 18)),
      title: Text(
        title, 
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      trailing: Obx(() => CupertinoSwitch(value: value.value, activeTrackColor: AppTheme.primary, onChanged: onChanged)),
    );
  }

  Widget _buildNavigationTile(BuildContext context, {required String title, required IconData icon, required Color iconBgColor, RxString? value, String Function()? valueBuilder, required VoidCallback onTap, required bool isAr}) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(width: 32, height: 32, decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.white, size: 18)),
      title: Text(
        title, 
        style: theme.textTheme.bodyLarge,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null || valueBuilder != null)
            Obx(() => Text(
              valueBuilder != null ? valueBuilder() : value!.value, 
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withAlpha(150),
              ),
            )),
          const SizedBox(width: 4),
          Icon(isAr ? CupertinoIcons.chevron_left : CupertinoIcons.chevron_right, size: 16, color: theme.textTheme.bodyMedium?.color?.withAlpha(80)),
        ],
      ),
    );
  }

  Widget _buildNumberFormatTile(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32, 
        height: 32, 
        decoration: BoxDecoration(
          color: const Color(0xFF5856D6), 
          borderRadius: BorderRadius.circular(8)
        ), 
        child: const Icon(CupertinoIcons.number, color: Colors.white, size: 18)
      ),
      title: Text(
        'number_format'.tr, 
        style: theme.textTheme.bodyLarge,
      ),
      trailing: _buildGlassNumberSelector(context),
    );
  }

  Widget _buildGlassNumberSelector(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final useArabic = controller.useArabicNumbers.value;

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 36,
            width: 100,
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.08) 
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
            child: Stack(
              children: [
                // Animated Highlight Capsule
                AnimatedAlign(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutBack,
                  alignment: useArabic ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 48,
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Labels & Tap Logic
                Row(
                  children: [
                    _segmentItem(
                      label: '123',
                      isSelected: !useArabic,
                      onTap: () {
                        if (useArabic) {
                          HapticFeedback.mediumImpact();
                          controller.toggleNumberFormat();
                        }
                      },
                      theme: theme,
                    ),
                    _segmentItem(
                      label: '١٢٣',
                      isSelected: useArabic,
                      onTap: () {
                        if (!useArabic) {
                          HapticFeedback.mediumImpact();
                          controller.toggleNumberFormat();
                        }
                      },
                      theme: theme,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _segmentItem({
    required String label, 
    required bool isSelected, 
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: isSelected 
                  ? Colors.white 
                  : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  /// Subscription-gated prevent-screenshots tile
  Widget _buildScreenshotTile(BuildContext context) {
    final sub = Get.find<SubscriptionService>();
    final adService = Get.find<RewardedAdService>();
    final theme = Theme.of(context);

    return Obx(() {
      final isProUser = sub.isPremium.value;
      final isAdUnlocked = adService.isFeatureUnlocked('prevent_screenshots');
      final isPro = isProUser || isAdUnlocked;

      return ListTile(
        onTap: () {
          if (isPro) {
            controller.togglePreventScreenshots();
          } else {
            HapticFeedback.lightImpact();
            Get.to(() => const PremiumView());
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isPro ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93).withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(CupertinoIcons.eye_slash_fill, color: Colors.white.withValues(alpha: isPro ? 1.0 : 0.7), size: 18),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                'prevent_screenshots'.tr,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isPro
                      ? theme.textTheme.bodyLarge?.color
                      : theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.45),
                ),
              ),
            ),
            if (!isProUser && !isAdUnlocked) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _buildAdUnlockIcon(
                context: context,
                featureKey: 'prevent_screenshots',
              ),
            ],
          ],
        ),
        trailing: isPro
            ? CupertinoSwitch(
                value: controller.preventScreenshots.value,
                activeTrackColor: AppTheme.primary,
                onChanged: (val) => controller.togglePreventScreenshots(val),
              )
            : Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
              ),
      );
    });
  }

  /// Subscription-gated start-screen tile
  Widget _buildStartScreenTile(BuildContext context, bool isAr) {
    final sub = Get.find<SubscriptionService>();
    final adService = Get.find<RewardedAdService>();
    final theme = Theme.of(context);

    return Obx(() {
      final isProUser = sub.isPremium.value;
      final isAdUnlocked = adService.isFeatureUnlocked('start_screen');
      final isPro = isProUser || isAdUnlocked;

      return ListTile(
        onTap: () {
          if (isPro) {
            controller.changeStartScreen();
          } else {
            HapticFeedback.lightImpact();
            Get.to(() => const PremiumView());
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isPro ? const Color(0xFFFF2D55) : const Color(0xFFFF2D55).withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(CupertinoIcons.house_fill, color: Colors.white.withValues(alpha: isPro ? 1.0 : 0.7), size: 18),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                'start_screen'.tr,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isPro
                      ? theme.textTheme.bodyLarge?.color
                      : theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.45),
                ),
              ),
            ),
            if (!isProUser && !isAdUnlocked) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _buildAdUnlockIcon(
                context: context,
                featureKey: 'start_screen',
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPro)
              Obx(() => Text(
                controller.startScreen.value.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withAlpha(150),
                ),
              )),
            const SizedBox(width: 4),
            Icon(
              isAr ? CupertinoIcons.chevron_left : CupertinoIcons.chevron_right,
              size: 16,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: isPro ? 0.5 : 0.3),
            ),
          ],
        ),
      );
    });
  }

  /// Glassmorphic video ad unlock icon — appears next to PRO badge
  Widget _buildAdUnlockIcon({required BuildContext context, required String featureKey}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adService = Get.find<RewardedAdService>();

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        adService.showAdToUnlock(
          featureKey: featureKey,
          onRewarded: () {
            Get.rawSnackbar(
              title: 'success'.tr,
              message: 'watch_ad_unlocked'.tr,
              backgroundColor: const Color(0xFF34C759),
              duration: const Duration(seconds: 3),
            );
          },
          onFailed: () {
            Get.rawSnackbar(
              title: 'error'.tr,
              message: 'watch_ad_not_ready'.tr,
              backgroundColor: const Color(0xFFFF3B30),
              duration: const Duration(seconds: 2),
            );
          },
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Obx(() {
            final isLoaded = adService.isAdLoaded.value;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLoaded
                      ? [const Color(0xFF007AFF).withValues(alpha: 0.25), const Color(0xFF5856D6).withValues(alpha: 0.25)]
                      : [Colors.grey.withValues(alpha: 0.15), Colors.grey.withValues(alpha: 0.15)],
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: isLoaded ? 0.25 : 0.1)
                      : Colors.black.withValues(alpha: isLoaded ? 0.15 : 0.06),
                  width: 0.5,
                ),
                boxShadow: isLoaded
                    ? [
                        BoxShadow(
                          color: const Color(0xFF007AFF).withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.play_rectangle_fill,
                    size: 11,
                    color: isLoaded
                        ? (isDark ? const Color(0xFF64D2FF) : const Color(0xFF007AFF))
                        : Colors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'beta_badge'.tr,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isLoaded
                          ? (isDark ? const Color(0xFF64D2FF) : const Color(0xFF007AFF))
                          : Colors.grey.withValues(alpha: 0.5),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
