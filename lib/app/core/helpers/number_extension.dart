import '../theme/theme_service.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
  /// ✅ Expert Fix: Added thousands separators (e.g. 10,000) for highest standards.
  /// ✅ Precision Fix: Now supports up to 2 decimals if they exist (e.g. 1.25).
  String get f {
    try {
      _cachedThemeService ??= Get.find<ThemeService>();
      
      String input = toString();
      
      // If the object is a number, apply thousands separator and optional decimals
      if (this is num) {
        input = NumberFormat('#,##0.##', Get.locale?.languageCode).format(this);
      } else {
        // Try parsing string to number if possible to apply separator
        final asNum = num.tryParse(toString().replaceAll(',', ''));
        if (asNum != null) {
          input = NumberFormat('#,##0.##', Get.locale?.languageCode).format(asNum);
        }
      }
      
      return _cachedThemeService!.replaceDigits(input);
    } catch (_) {
      return toString();
    }
  }

  /// High-precision formatter with fixed decimal places.
  /// Useful for distance (e.g. 1.25 km) or currency.
  String fd(int fractionalDigits) {
    try {
      _cachedThemeService ??= Get.find<ThemeService>();
      
      num value = 0;
      if (this is num) {
        value = this as num;
      } else {
        value = num.tryParse(toString().replaceAll(',', '')) ?? 0;
      }
      
      String pattern = '#,##0.${'0' * fractionalDigits}';
      String input = NumberFormat(pattern, Get.locale?.languageCode).format(value);
      
      return _cachedThemeService!.replaceDigits(input);
    } catch (_) {
      return toString();
    }
  }
}
