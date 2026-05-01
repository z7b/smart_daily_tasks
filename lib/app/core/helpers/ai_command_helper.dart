

/// Helper utilities for AI-related command execution and display.
/// All local NLP and rule-based parsing has been removed to comply with Cloud-Only architecture.
class AiCommandHelper {
  /// Normalizes Arabic characters for better string matching and display.
  static String normalizeArabic(String text) {
    String result = text.trim();
    result = result.replaceAll(RegExp(r'[أإآ]'), 'ا');
    result = result.replaceAll(RegExp(r'[يى]'), 'ي');
    result = result.replaceAll(RegExp(r'[ة]'), 'ه');
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    return result.toLowerCase();
  }
  
  /// Helper to extract numeric values from strings (used for ID matching, not intent parsing).
  static int? extractNumber(String text) {
    final match = RegExp(r'(\d+)').firstMatch(text);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }
}
