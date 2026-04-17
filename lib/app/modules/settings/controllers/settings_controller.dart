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
  }

  void _loadCurrentSettings() {
    try {
      isDarkMode.value = _themeService.isDarkMode;
      currentLanguage.value = _themeService.getLocale().languageCode;
      
      fontType.value = _themeService.fontTypeRx.value;
      fontSize.value = _themeService.fontSizeRx.value;
      
      preventScreenshots.value = _securityService.isScreenshotPrevented.value;
      appLock.value = _appLockService.isAppLockEnabled.value;
      
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


  void toggleBiometric() {
    _appLockService.toggleBiometric();
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

  void requestBatteryOptimization() {
    _themeService.init().then((_) {
       Get.find<ns.NotificationService>().requestBatteryExemption();
    });
  }

  // --- Helpers with Pro Translation Logic ---

  void _showOptionsSheet({required List<String> options, required RxString current, required void Function(String) onSelected}) {
    BottomSheetHelper.showSafeBottomSheet(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Wrap(
            children: options.map((option) {
              return Obx(() => ListTile(
                // ✅ Doctoral Fix: Ensuring .tr is applied to every option string
                title: Text(option.tr, style: TextStyle(fontWeight: current.value == option ? FontWeight.bold : FontWeight.normal)),
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
      Get.snackbar(
        'success'.tr, 
        'data_exported_successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withAlpha(50),
        colorText: Colors.white,
      );
    } catch (e) {
      talker.error('Error creating backup: $e');
      Get.snackbar(
        'error'.tr, 
        'failed_to_export_data'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withAlpha(50),
        colorText: Colors.white,
      );
    }
  }

  Future<void> restoreBackup() async {
    try {
      await BackupService().restoreBackup();
      Get.snackbar(
        'success'.tr, 
        'data_imported_successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withAlpha(50),
        colorText: Colors.white,
      );
      // ✅ Phase 3: Force Re-initialization of core data so UI reflects backup changes instantly
      talker.info('🔄 Restarting UI Stack to reflect restored Backup...');
      await Future.delayed(const Duration(milliseconds: 800));
      Get.offAllNamed('/home'); // Routing to home wipes the nav stack and forces fresh OnInit logic
    } catch (e) {
      talker.error('Error restoring backup: $e');
      Get.snackbar(
        'error'.tr, 
        'failed_to_import_data'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withAlpha(50),
        colorText: Colors.white,
      );
    }
  }
}
