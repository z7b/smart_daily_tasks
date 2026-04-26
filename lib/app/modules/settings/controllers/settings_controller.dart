import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/config/settings_enums.dart';
import '../../../core/theme/theme_service.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/security_service.dart';
import '../../../core/services/app_lock_service.dart';
import 'package:smart_daily_tasks/app/core/services/notification_service.dart' as ns;
import '../../../core/helpers/bottom_sheet_helper.dart';
import '../../../core/helpers/log_helper.dart';
import '../../../core/config/storage_keys.dart';
import '../../../core/theme/app_theme.dart';

class SettingsController extends GetxController {
  late final ThemeService _themeService;
  late final SecurityService _securityService;
  late final AppLockService _appLockService;
  final _box = GetStorage();

  RxBool isDarkMode = true.obs;
  RxString currentLanguage = 'ar'.obs;

  // Settings Observables
  RxString startScreen = 'home'.obs;
  RxString fontType = 'Rubik'.obs;
  RxString fontSize = 'medium'.obs;
  RxString firstDayOfWeek = 'sunday'.obs;
  RxBool preventScreenshots = false.obs;
   RxBool appLock = false.obs;
  RxBool useArabicNumbers = false.obs;
  
  // ✅ Notification Stability Governance
  RxString notificationStatus = 'pending'.obs; // pending, amazing, error
  
  // Biometrics Governance
  RxBool get isBiometricAvailable => _appLockService.isBiometricAvailable;
  RxBool get isBiometricEnabled => _appLockService.isBiometricEnabled;

  final List<String> fontOptions = ['Rubik', 'Cairo', 'Amiri', 'Tajawal'];
  final List<String> fontSizeKeys = ['small', 'medium', 'large'];
  final List<String> startScreenKeys = StartScreen.values.map((e) => e.key).toList();
  final List<String> dayOfWeekKeys = DayOfWeek.values.map((e) => e.key).toList();

  @override
  void onInit() {
    super.onInit();
    _themeService = Get.find<ThemeService>();
    _securityService = Get.find<SecurityService>();
    _appLockService = Get.find<AppLockService>();

    talker.info('⚙️ SettingsController initialized');
    _loadCurrentSettings();
    checkNotificationStability(silent: true); // Initial background check
  }

  void _loadCurrentSettings() {
    try {
      isDarkMode.value = _themeService.isDarkMode;
      currentLanguage.value = _themeService.getLocale().languageCode;
      
      fontType.value = _themeService.fontTypeRx.value;
      fontSize.value = _themeService.fontSizeRx.value;
      
      preventScreenshots.value = _securityService.isScreenshotPrevented.value;
      appLock.value = _appLockService.isAppLockEnabled.value;
      useArabicNumbers.value = _themeService.useArabicNumbersRx.value;
      
      startScreen.value = _box.read(StorageKeys.startScreen) ?? 'home';
      firstDayOfWeek.value = _box.read('firstDayOfWeek') ?? 'sunday';
    } catch (e) {
      talker.error('⚠️ Settings Load Error: $e');
    }
  }

  static String getSavedStartRoute() {
    try {
      final box = GetStorage();
      final String? key = box.read(StorageKeys.startScreen);
      return StartScreen.fromKey(key).routePath;
    } catch (e) {
      return StartScreen.home.routePath;
    }
  }

  void toggleTheme() {
    _themeService.switchTheme();
    isDarkMode.value = _themeService.isDarkMode;
  }

  void changeLanguage(String languageCode) {
    currentLanguage.value = languageCode;
    _themeService.saveLocale(languageCode);
    Get.updateLocale(Locale(languageCode));
    talker.info('🌐 Language UI Updated: $languageCode');
  }

  void changeFontSize() {
    _showOptionsSheet(
      options: fontSizeKeys,
      current: fontSize,
      // ✅ Expert Preview Logic: Scaling text in the sheet to match the actual size
      textStyleBuilder: (option) => TextStyle(
        fontSize: 16 * AppTheme.fontSizeScale(option),
      ),
      onSelected: (value) {
        fontSize.value = value;
        _themeService.switchFontSize(value);
      },
    );
  }

  void changeFontType() {
    _showFontSheet();
  }

  Future<void> togglePreventScreenshots() async {
    await _securityService.toggleScreenshotPrevention();
    preventScreenshots.value = _securityService.isScreenshotPrevented.value;
    
    Get.snackbar(
      'security'.tr, // ✅ Fixed: Showing "الأمان"
      preventScreenshots.value ? 'screenshots_enabled'.tr : 'screenshots_disabled'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> toggleAppLock() async {
    await _appLockService.toggleAppLock();
    appLock.value = _appLockService.isAppLockEnabled.value;
  }

  void toggleNumberFormat() {
    bool newValue = !useArabicNumbers.value;
    useArabicNumbers.value = newValue;
    _themeService.switchNumberFormat(newValue);
  }


  void toggleBiometric() {
    // Removed as per expert design request: System handles fallback automatically
  }

  void changeStartScreen() {
    _showOptionsSheet(
      options: startScreenKeys,
      current: startScreen,
      onSelected: (value) {
        startScreen.value = value;
        _box.write(StorageKeys.startScreen, value);
      },
    );
  }

  void changeFirstDayOfWeek() {
    _showOptionsSheet(
      options: dayOfWeekKeys,
      current: firstDayOfWeek,
      onSelected: (value) {
        firstDayOfWeek.value = value;
        _box.write('firstDayOfWeek', value);
      },
    );
  }

  /// ✅ Notification Stability Check: Verifies and requests necessary background permissions
  Future<void> checkNotificationStability({bool silent = false}) async {
    if (GetPlatform.isAndroid) {
      final ns.NotificationService notificationService = Get.find<ns.NotificationService>();
      
      if (!silent) {
        _showSnackbar('security'.tr, 'system_auth_required'.tr); // Changed to system_auth_required for professional feel
      }

      // 1. Request/Verify Permissions
      await notificationService.requestBatteryExemption();
      await notificationService.checkExactAlarmPermission();
      final isStable = await notificationService.isSystemStable();

      // 2. Update Status Reactive UI
      notificationStatus.value = isStable ? 'amazing' : 'pending';

      if (!silent) {
        if (isStable) {
          _showSnackbar('success'.tr, '${'notification_stability'.tr}: ${'amazing'.tr}');
          // 3. Fire Test Signal to prove it works
          await Future.delayed(const Duration(milliseconds: 500));
          await notificationService.sendTestNotification();
        } else {
          _showSnackbar('warning'.tr, '${'notification_stability'.tr}: ${'pending'.tr}');
        }
      }
    } else {
      if (!silent) {
        _showSnackbar('security'.tr, 'system_auth_required'.tr);
      }
    }
  }

  // --- Helpers with Pro Translation Logic ---

  void _showOptionsSheet({
    required List<String> options, 
    required RxString current, 
    required void Function(String) onSelected,
    TextStyle Function(String)? textStyleBuilder, // ✅ Added for dynamic previews
  }) {
    BottomSheetHelper.showSafeBottomSheet(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Wrap(
            children: options.map((option) {
              return Obx(() => ListTile(
                title: Text(
                  option.tr, 
                  style: (textStyleBuilder?.call(option) ?? const TextStyle(fontSize: 16)).copyWith(
                    fontWeight: current.value == option ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: current.value == option ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                onTap: () {
                  onSelected(option);
                  Get.back();
                },
              ));
            }).toList(),
          ),
        );
      },
    );
  }

  void _showFontSheet() {
    BottomSheetHelper.showSafeBottomSheet(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Wrap(
            children: fontOptions.map((font) {
              return Obx(() => ListTile(
                title: Text(
                  font, 
                  style: GoogleFonts.getFont(
                    font, 
                    fontWeight: fontType.value == font ? FontWeight.bold : FontWeight.normal
                  ),
                ),
                trailing: fontType.value == font ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                onTap: () {
                  fontType.value = font;
                  _themeService.switchFont(font);
                  Get.back();
                },
              ));
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> createBackup() async {
    try {
      await BackupService().createBackup();
      _showSnackbar('success'.tr, 'data_exported_successfully'.tr);
    } catch (e) {
      talker.error('Error creating backup: $e');
      _showSnackbar('error'.tr, 'failed_to_export_data'.tr, isError: true);
    }
  }

  Future<void> restoreBackup() async {
    try {
      await BackupService().restoreBackup();
      _showSnackbar('success'.tr, 'data_imported_successfully'.tr);
      // ✅ Phase 3: Force Re-initialization of core data so UI reflects backup changes instantly
      talker.info('🔄 Restarting UI Stack to reflect restored Backup...');
      await Future.delayed(const Duration(milliseconds: 800));
      Get.offAllNamed('/home'); // Routing to home wipes the nav stack and forces fresh OnInit logic
    } catch (e) {
      talker.error('Error restoring backup: $e');
      _showSnackbar('error'.tr, 'failed_to_import_data'.tr, isError: true);
    }
  }

  void _showSnackbar(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: isError ? SnackPosition.BOTTOM : SnackPosition.TOP,
      backgroundColor: (isError ? Colors.redAccent : Colors.green).withValues(alpha: 0.1),
      colorText: isError ? Colors.redAccent : Colors.green,
      duration: const Duration(seconds: 2),
    );
  }
}
