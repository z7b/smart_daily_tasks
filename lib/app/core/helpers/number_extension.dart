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
extension NumberLocalization on Object {
  /// The magic formatter that honors the global 'Number Format' setting.
  String get f {
    final themeService = Get.find<ThemeService>();
    return themeService.replaceDigits(toString());
  }
}
