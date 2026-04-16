import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
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
        _sectionHeader('settings'.tr),
        const SizedBox(height: 8),

        // ─── Appearance Group ─────────────────────────
        _groupTitle('appearance'.tr),
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
          ],
        ),
        const SizedBox(height: 24),

        // ─── General Group ────────────────────────────
        _groupTitle('general'.tr),
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
              valueBuilder: () => controller.currentLanguage.value == 'ar' ? 'arabic'.tr : 'english'.tr,
              onTap: () {
                final newLang = controller.currentLanguage.value == 'ar' ? 'en' : 'ar';
                controller.changeLanguage(newLang);
              },
              isAr: isAr,
            ),
            _divider(context),
            _buildNavigationTile(
              context,
              title: 'start_screen'.tr,
              icon: CupertinoIcons.house_fill,
              iconBgColor: const Color(0xFFFF2D55),
              valueBuilder: () => controller.startScreen.value.tr,
              onTap: () => controller.changeStartScreen(),
              isAr: isAr,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ─── Security Group ───────────────────────────
        _groupTitle('security'.tr),
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
              onChanged: (_) => controller.toggleAppLock(),
            ),
            Obx(() {
              if (controller.appLock.value) {
                return Column(
                  children: [
                    if (controller.isBiometricAvailable.value) ...[
                      _divider(context),
                      _buildSwitchTile(
                        context,
                        title: 'biometric_login'.tr,
                        icon: CupertinoIcons.viewfinder,
                        iconBgColor: const Color(0xFF5856D6),
                        value: controller.isBiometricEnabled,
                        onChanged: (_) => controller.toggleBiometric(),
                      ),
                    ]
                  ],
                );
              }
              return const SizedBox.shrink();
            }),
            _divider(context),
            _buildSwitchTile(
              context,
              title: 'prevent_screenshots'.tr,
              icon: CupertinoIcons.eye_slash_fill,
              iconBgColor: const Color(0xFF8E8E93),
              value: controller.preventScreenshots,
              onChanged: (_) => controller.togglePreventScreenshots(),
            ),
            _divider(context),
            _buildNavigationTile(
              context,
              title: 'notification_stability'.tr,
              icon: CupertinoIcons.battery_100,
              iconBgColor: const Color(0xFF32ADE6),
              onTap: () => controller.requestBatteryOptimization(),
              isAr: isAr,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ─── Data Group ───────────────────────────────
        _groupTitle('data'.tr),
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

        const SizedBox(height: 120),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: -1),
      ),
    );
  }

  Widget _groupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.5),
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

  Widget _buildSwitchTile(BuildContext context, {required String title, required IconData icon, required Color iconBgColor, required RxBool value, required ValueChanged<bool> onChanged}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(width: 32, height: 32, decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.white, size: 18)),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: Obx(() => CupertinoSwitch(value: value.value, activeTrackColor: AppTheme.primary, onChanged: onChanged)),
    );
  }

  Widget _buildNavigationTile(BuildContext context, {required String title, required IconData icon, required Color iconBgColor, RxString? value, String Function()? valueBuilder, required VoidCallback onTap, required bool isAr}) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(width: 32, height: 32, decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.white, size: 18)),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null || valueBuilder != null)
            Obx(() => Text(valueBuilder != null ? valueBuilder() : value!.value, style: TextStyle(fontSize: 15, color: theme.textTheme.bodyMedium?.color?.withAlpha(150)))),
          const SizedBox(width: 4),
          Icon(isAr ? CupertinoIcons.chevron_left : CupertinoIcons.chevron_right, size: 16, color: theme.textTheme.bodyMedium?.color?.withAlpha(80)),
        ],
      ),
    );
  }
}
