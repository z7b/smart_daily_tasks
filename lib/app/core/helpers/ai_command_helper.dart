import '../../data/models/task_model.dart';

class AiCommandHelper {
  /// Normalizes Arabic characters for better regex matching.
  static String normalizeArabic(String text) {
    String result = text.trim();
    result = result.replaceAll(RegExp(r'[أإآ]'), 'ا');
    result = result.replaceAll(RegExp(r'[يى]'), 'ي');
    result = result.replaceAll(RegExp(r'[ة]'), 'ه');
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    return result.toLowerCase();
  }
  
  /// Helper to extract numeric values from strings.
  static int? extractNumber(String text) {
    final match = RegExp(r'(\d+)').firstMatch(text);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  /// 📅 Temporal Expert: Parses date offsets from text.
  static DateTime parseDate(String text) {
    final normalized = normalizeArabic(text);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (normalized.contains('بكره') || normalized.contains('tomorrow') || normalized.contains('غدا')) {
      return today.add(const Duration(days: 1));
    }
    if (normalized.contains('بعد بكره') || normalized.contains('بعد غد')) {
      return today.add(const Duration(days: 2));
    }
    
    return today; // Default to today
  }

  /// ⚡ Priority Expert: Maps keywords to TaskPriority.
  static TaskPriority parsePriority(String text) {
    final normalized = normalizeArabic(text);
    
    if (normalized.contains('عالي') || normalized.contains('مهم') || normalized.contains('عاجل') || normalized.contains('high') || normalized.contains('urgent')) {
      return TaskPriority.high;
    }
    if (normalized.contains('متوسط') || normalized.contains('medium')) {
      return TaskPriority.medium;
    }
    if (normalized.contains('منخفض') || normalized.contains('عادي') || normalized.contains('بسيط') || normalized.contains('low') || normalized.contains('trivial')) {
      return TaskPriority.low;
    }
    
    return TaskPriority.medium; // Default
  }
}
