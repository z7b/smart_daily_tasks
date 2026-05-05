import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/config/settings_enums.dart';
import '../../../core/theme/theme_service.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/security_service.dart';
import '../../../core/services/app_lock_service.dart';
import 'package:smart_daily_tasks/app/core/services/notification_service.dart' as ns;
import '../../../core/config/storage_keys.dart';

class SettingsController extends GetxController {
  late final ThemeService _themeService;
  late final SecurityService _securityService;
  late final AppLockService _appLockService;
  final _box = GetStorage();

  RxBool isDarkMode = true.obs;
  RxString currentLanguage = 'ar'.obs;
  RxString startScreen = 'home'.obs;
  RxString fontType = 'Rubik'.obs;
  RxString fontSize = 'medium'.obs;
  RxString firstDayOfWeek = 'sunday'.obs;
  RxBool preventScreenshots = false.obs;
  RxBool appLock = false.obs;
  RxBool useArabicNumbers = false.obs;

  RxString notificationStatus = 'pending'.obs;

  /// Font options with CJK/Devanagari support
  List<String> get fontOptions {
    final lang = currentLanguage.value;
    final base = ['Rubik', 'Cairo', 'Amiri', 'Tajawal'];
    if (lang == 'zh_CN') return ['Noto Sans SC', ...base];
    if (lang == 'zh_TW') return ['Noto Sans TC', ...base];
    if (lang == 'hi') return ['Noto Sans Devanagari', ...base];
    return base;
  }

  final List<String> fontSizeKeys = ['small', 'medium', 'large'];
  final List<String> startScreenKeys = StartScreen.values.map((e) => e.key).toList();
  final List<String> dayOfWeekKeys = DayOfWeek.values.map((e) => e.key).toList();

  /// All supported language keys for the language picker
  static const List<String> languageKeys = [
    'ar', 'en', 'zh_CN', 'zh_TW', 'hi', 'fr', 'es', 'ru',
  ];

  @override
  void onInit() {
    super.onInit();
    _themeService = Get.find<ThemeService>();
    _securityService = Get.find<SecurityService>();
    _appLockService = Get.find<AppLockService>();
    _loadCurrentSettings();
    Future.delayed(const Duration(seconds: 5), () => checkNotificationStability(silent: true));
  }

  void _loadCurrentSettings() {
    isDarkMode.value = _themeService.isDarkMode;
    currentLanguage.value = _themeService.getLocaleKey();
    fontType.value = _themeService.fontTypeRx.value;
    fontSize.value = _themeService.fontSizeRx.value;
    preventScreenshots.value = _securityService.isScreenshotPrevented.value;
    appLock.value = _appLockService.isAppLockEnabled.value;
    useArabicNumbers.value = _themeService.useArabicNumbersRx.value;
    startScreen.value = _box.read(StorageKeys.startScreen) ?? 'home';
    firstDayOfWeek.value = _box.read('firstDayOfWeek') ?? 'sunday';
  }

  // --- Theme & General Actions ---
  void toggleTheme() {
    _themeService.switchTheme();
    isDarkMode.value = _themeService.isDarkModeRx.value;
  }

  void changeFontType() {
    _showSelectionDialog(title: 'font_type'.tr, options: fontOptions, currentValue: fontType.value, onSelected: (val) {
      fontType.value = val;
      _themeService.switchFont(val);
    });
  }

  void changeFontSize() {
    _showSelectionDialog(title: 'font_size'.tr, options: fontSizeKeys, currentValue: fontSize.value, onSelected: (val) {
      fontSize.value = val;
      _themeService.switchFontSize(val);
    });
  }

  void changeLanguage(String langKey) {
    currentLanguage.value = langKey;
    _themeService.saveLocale(langKey);

    final locale = ThemeService.supportedLocales[langKey];
    if (locale != null) {
      // Auto-switch font for CJK/Devanagari
      if (langKey == 'zh_CN') {
        _themeService.switchFont('Noto Sans SC');
        fontType.value = 'Noto Sans SC';
      } else if (langKey == 'zh_TW') {
        _themeService.switchFont('Noto Sans TC');
        fontType.value = 'Noto Sans TC';
      } else if (langKey == 'hi') {
        _themeService.switchFont('Noto Sans Devanagari');
        fontType.value = 'Noto Sans Devanagari';
      } else if (!['Noto Sans SC', 'Noto Sans TC', 'Noto Sans Devanagari'].contains(fontType.value)) {
        // Keep current font if it's a standard font
      } else {
        // Reset to default when switching away from CJK/Devanagari
        _themeService.switchFont('Rubik');
        fontType.value = 'Rubik';
      }

      Get.updateLocale(locale);
    }
  }

  /// Shows the language picker with all supported languages.
  void showLanguagePicker() {
    _showSelectionDialog(
      title: 'language'.tr,
      options: languageKeys,
      currentValue: currentLanguage.value,
      onSelected: (val) => changeLanguage(val),
    );
  }

  void changeFirstDayOfWeek() {
    _showSelectionDialog(title: 'first_day_of_week'.tr, options: dayOfWeekKeys, currentValue: firstDayOfWeek.value, onSelected: (val) {
      firstDayOfWeek.value = val;
      _box.write('firstDayOfWeek', val);
    });
  }

  void changeStartScreen() {
    _showSelectionDialog(title: 'start_screen'.tr, options: startScreenKeys, currentValue: startScreen.value, onSelected: (val) {
      startScreen.value = val;
      _box.write(StorageKeys.startScreen, val);
    });
  }

  void toggleAppLock([dynamic value]) async {
    await _appLockService.toggleAppLock();
    appLock.value = _appLockService.isAppLockEnabled.value;
  }

  void togglePreventScreenshots([dynamic value]) async {
    await _securityService.toggleScreenshotPrevention();
    preventScreenshots.value = _securityService.isScreenshotPrevented.value;
  }

  void toggleNumberFormat() {
    final newValue = !useArabicNumbers.value;
    useArabicNumbers.value = newValue;
    _themeService.switchNumberFormat(newValue);
  }

  String getSavedStartRoute() {
    final key = _box.read(StorageKeys.startScreen) ?? 'home';
    return '/$key';
  }

  Future<void> checkNotificationStability({bool silent = false}) async {
    final notifService = Get.find<ns.NotificationService>();

    // Step 1: Check current permission state
    var isStable = await notifService.isSystemStable();

    // Step 2: If not stable AND user pressed button (not silent), request missing permissions
    if (!isStable && !silent) {
      await notifService.requestFullPermissions();
      // Re-check after requesting
      isStable = await notifService.isSystemStable();
    }

    notificationStatus.value = isStable ? 'amazing' : 'pending';

    // Step 3: If interactive (not silent), give real feedback
    if (!silent) {
      if (isStable) {
        // Fire a real test notification to prove the pipeline works end-to-end
        await notifService.sendTestNotification();
        _showSnackbar(
          'notification_stability'.tr,
          'diagnostic_signal_body'.tr,
        );
      } else {
        _showSnackbar(
          'notification_stability'.tr,
          'notification_permissions_missing'.tr,
          isError: true,
        );
      }
    }
  }

  Future<void> createBackup() async { await BackupService().createBackup(); _showSnackbar('success'.tr, 'data_exported_successfully'.tr); }
  Future<void> restoreBackup() async { await BackupService().restoreBackup(); Get.offAllNamed('/home'); }

  /// Hardened selection dialog with SafeArea, scroll, and responsive constraints.
  void _showSelectionDialog({required String title, required List<String> options, required String currentValue, required Function(String) onSelected}) {
    Get.bottomSheet(
      SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.65,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Get.theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final opt = options[index];
                      return ListTile(
                        title: Text(opt.tr),
                        trailing: opt == currentValue ? const Icon(Icons.check, color: Colors.blue) : null,
                        onTap: () { onSelected(opt); Get.back(); },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showSnackbar(String title, String message, {bool isError = false}) {
    Get.rawSnackbar(title: title, message: message, backgroundColor: isError ? Colors.red : Colors.green);
  }
}
