import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app_theme.dart';

class ThemeService extends GetxService {
  final _box = GetStorage();
  final _key = 'isDarkMode';
  final _fontSizeKey = 'fontSize';
  final _fontTypeKey = 'fontType';
  final _localeKey = 'locale';
  final _numberFormatKey = 'useArabicNumbers';

  // Reactive state so UI can observe
  final isDarkModeRx = true.obs;
  final fontTypeRx = 'Rubik'.obs;
  final fontSizeRx = 'medium'.obs;
  final useArabicNumbersRx = false.obs;

  bool get isDarkMode => _loadThemeFromBox();
  String get fontType => _box.read(_fontTypeKey) ?? 'Rubik';
  String get fontSize => _box.read(_fontSizeKey) ?? 'medium';

  ThemeMode get theme => isDarkModeRx.value ? ThemeMode.dark : ThemeMode.light;

  /// Master locale map — single source of truth for all 8 supported languages.
  static const Map<String, Locale> supportedLocales = {
    'ar': Locale('ar', 'SA'),
    'en': Locale('en', 'US'),
    'zh_CN': Locale('zh', 'CN'),
    'zh_TW': Locale('zh', 'TW'),
    'hi': Locale('hi', 'IN'),
    'fr': Locale('fr', 'FR'),
    'es': Locale('es', 'ES'),
    'ru': Locale('ru', 'RU'),
  };

  bool _loadThemeFromBox() {
    try {
      return _box.read(_key) ?? true;
    } catch (e) {
      debugPrint('⚠️ Error reading theme from storage: $e');
      return true;
    }
  }

  void switchTheme() {
    try {
      bool isDark = _loadThemeFromBox();
      _saveThemeToBox(!isDark);
      isDarkModeRx.value = !isDark;
      Get.changeThemeMode(!isDark ? ThemeMode.dark : ThemeMode.light);
    } catch (e) {
      debugPrint('⚠️ Error switching theme: $e');
    }
  }

  void switchFont(String fontName) {
    try {
      _box.write(_fontTypeKey, fontName);
      fontTypeRx.value = fontName;
      debugPrint('🎨 Font changed to: $fontName');
      Get.forceAppUpdate(); // ✅ Phase 3: Force rebuild everywhere immediately
    } catch (e) {
      debugPrint('⚠️ Error switching font: $e');
    }
  }

  void switchFontSize(String size) {
    try {
      _box.write(_fontSizeKey, size);
      fontSizeRx.value = size;
      debugPrint('📏 Font size changed to: $size');
      Get.forceAppUpdate(); // ✅ Phase 3: Force rebuild everywhere immediately
    } catch (e) {
      debugPrint('⚠️ Error switching font size: $e');
    }
  }

  void switchNumberFormat(bool useArabic) {
    try {
      _box.write(_numberFormatKey, useArabic);
      useArabicNumbersRx.value = useArabic;
      debugPrint('🔢 Number format changed: ${useArabic ? "Arabic" : "English"}');
      Get.forceAppUpdate(); // ✅ Force immediate global refresh
    } catch (e) {
      debugPrint('⚠️ Error switching number format: $e');
    }
  }

  String replaceDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    
    if (useArabicNumbersRx.value) {
      input = input.replaceAllMapped(
        RegExp(r'[0-9]'),
        (m) => arabic[int.parse(m.group(0)!)],
      );
    } else {
      input = input.replaceAllMapped(
        RegExp('[٠-٩]'),
        (m) => english['٠١٢٣٤٥٦٧٨٩'.indexOf(m.group(0)!)],
      );
    }
    return input;
  }

  // ✅ Reactive Theme Getters for Root Rebuild
  ThemeData get currentTheme => AppTheme.buildTheme(
    isDark: false, 
    fontName: fontTypeRx.value, 
    fontSizeKey: fontSizeRx.value,
  );

  ThemeData get currentDarkTheme => AppTheme.buildTheme(
    isDark: true, 
    fontName: fontTypeRx.value, 
    fontSizeKey: fontSizeRx.value,
  );

  // --- Locale ---
  Locale getLocale() {
    try {
      final savedLocale = _box.read(_localeKey);
      if (savedLocale != null && supportedLocales.containsKey(savedLocale)) {
        return supportedLocales[savedLocale]!;
      }
    } catch (e) {
      debugPrint('⚠️ Error reading locale: $e');
    }
    
    // Auto-detect device locale
    final deviceLocale = Get.deviceLocale;
    if (deviceLocale != null) {
      final langCode = deviceLocale.languageCode;
      // Check for exact match first (e.g. zh_CN, zh_TW)
      final fullCode = '${langCode}_${deviceLocale.countryCode ?? ''}';
      if (supportedLocales.containsKey(fullCode)) {
        return supportedLocales[fullCode]!;
      }
      // Then check language code only
      if (supportedLocales.containsKey(langCode)) {
        return supportedLocales[langCode]!;
      }
      // Special case for Chinese without country code
      if (langCode == 'zh') {
        return supportedLocales['zh_CN']!;
      }
    }
    return const Locale('en', 'US'); // Fallback
  }

  /// Returns the storage key for the current locale (e.g. 'ar', 'en', 'zh_CN')
  String getLocaleKey() {
    final savedLocale = _box.read(_localeKey);
    if (savedLocale != null && supportedLocales.containsKey(savedLocale)) {
      return savedLocale;
    }
    return 'en';
  }

  void saveLocale(String languageKey) {
    try {
      _box.write(_localeKey, languageKey);
    } catch (e) {
      debugPrint('⚠️ Error saving locale: $e');
    }
  }

  void _saveThemeToBox(bool isDarkMode) {
    try {
      _box.write(_key, isDarkMode);
    } catch (e) {
      debugPrint('⚠️ Error saving theme: $e');
    }
  }

  Future<ThemeService> init() async {
    // Note: GetStorage.init() is already called in main.dart
    try {
      isDarkModeRx.value = _loadThemeFromBox();
      fontTypeRx.value = _box.read(_fontTypeKey) ?? 'Rubik';
      fontSizeRx.value = _box.read(_fontSizeKey) ?? 'medium';
      useArabicNumbersRx.value = _box.read(_numberFormatKey) ?? false;
    } catch (e) {
      debugPrint('⚠️ ThemeService init error: $e');
    }
    return this;
  }
}
