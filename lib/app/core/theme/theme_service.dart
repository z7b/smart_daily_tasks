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

  // Reactive state so UI can observe
  final isDarkModeRx = true.obs;
  final fontTypeRx = 'Rubik'.obs;
  final fontSizeRx = 'Large'.obs;

  bool get isDarkMode => _loadThemeFromBox();
  String get fontType => _box.read(_fontTypeKey) ?? 'Rubik';
  String get fontSize => _box.read(_fontSizeKey) ?? 'Large';

  ThemeMode get theme => _loadThemeFromBox() ? ThemeMode.dark : ThemeMode.light;

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
      _rebuildTheme();
    } catch (e) {
      debugPrint('⚠️ Error switching font: $e');
    }
  }

  void switchFontSize(String size) {
    try {
      _box.write(_fontSizeKey, size);
      fontSizeRx.value = size;
      debugPrint('📏 Font size changed to: $size');
      _rebuildTheme();
    } catch (e) {
      debugPrint('⚠️ Error switching font size: $e');
    }
  }

  /// Rebuild theme by applying new ThemeData built from updated storage values.
  /// Uses Get.changeTheme for instant, flicker-free rebuild.
  void _rebuildTheme() {
    try {
      // Import AppTheme dynamically to avoid circular deps at compile time;
      // since it's a static getter, it will re-read GetStorage on each call.
      final bool isDark = _loadThemeFromBox();
      if (isDark) {
        Get.changeTheme(ThemeData.dark()); // temporary
        Future.delayed(const Duration(milliseconds: 50), () {
          Get.changeTheme(
            _buildDarkTheme(),
          );
          Get.changeThemeMode(ThemeMode.dark);
        });
      } else {
        Get.changeTheme(ThemeData.light()); // temporary
        Future.delayed(const Duration(milliseconds: 50), () {
          Get.changeTheme(
            _buildLightTheme(),
          );
          Get.changeThemeMode(ThemeMode.light);
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error rebuilding theme: $e');
    }
  }

  /// Wrapper that imports AppTheme lazily to build light theme.
  ThemeData _buildLightTheme() {
    // ignore: avoid_dynamic_calls
    try {
      // We call the static getter which reads from GetStorage each time.
      return AppTheme.lightTheme;
    } catch (e) {
      debugPrint('⚠️ Fallback light theme used: $e');
      return ThemeData.light();
    }
  }

  /// Wrapper that imports AppTheme lazily to build dark theme.
  ThemeData _buildDarkTheme() {
    try {
      return AppTheme.darkTheme;
    } catch (e) {
      debugPrint('⚠️ Fallback dark theme used: $e');
      return ThemeData.dark();
    }
  }

  // --- Locale ---
  Locale getLocale() {
    try {
      final savedLocale = _box.read(_localeKey);
      if (savedLocale != null) {
        return savedLocale == 'ar'
            ? const Locale('ar', 'SA')
            : const Locale('en', 'US');
      }
    } catch (e) {
      debugPrint('⚠️ Error reading locale: $e');
    }
    
    // Auto-detect device locale
    final deviceLocale = Get.deviceLocale;
    if (deviceLocale != null && deviceLocale.languageCode == 'ar') {
      return const Locale('ar', 'SA');
    }
    return const Locale('en', 'US');
  }

  void saveLocale(String languageCode) {
    try {
      _box.write(_localeKey, languageCode);
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
      fontSizeRx.value = _box.read(_fontSizeKey) ?? 'Large';
    } catch (e) {
      debugPrint('⚠️ ThemeService init error: $e');
    }
    return this;
  }
}
