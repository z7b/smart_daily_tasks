import '../theme/theme_service.dart';
import 'package:get/get.dart';

/// 🔢 Universal Number Translation Extension
/// 
/// This extension allows any Object (String, int, double) to be instantly
/// translated to the user's preferred digit format (Arabic ١٢٣ vs Western 123).
/// 
/// Usage:
/// - '${count}.f'
/// - '2024'.f
/// - 42.f

// 🚀 Performance: Cache ThemeService reference to avoid Get.find() on every call.
// In grid views with many numbers, this prevents hundreds of map lookups per frame.
ThemeService? _cachedThemeService;

extension NumberLocalization on Object {
  /// The magic formatter that honors the global 'Number Format' setting.
  String get f {
    try {
      _cachedThemeService ??= Get.find<ThemeService>();
      return _cachedThemeService!.replaceDigits(toString());
    } catch (_) {
      return toString(); // Graceful fallback if ThemeService isn't ready yet
    }
  }
}
