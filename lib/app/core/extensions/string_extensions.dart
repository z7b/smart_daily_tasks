extension StringNormalization on String {
  /// Normalizes Arabic text by removing diacritics and unifying similar characters.
  /// Extremely useful for search precision in Life OS.
  String normalizeArabic() {
    var text = this;
    
    // 1. Remove Harakat (Diacritics)
    final diacritics = RegExp(r'[\u064B-\u0652]');
    text = text.replaceAll(diacritics, '');
    
    // 2. Unify Alif variants
    text = text.replaceAll(RegExp(r'[أإآ]'), 'ا');
    
    // 3. Unify Yaa / Alif Maqsura
    text = text.replaceAll('ى', 'ي');
    
    // 4. Unify Taa Marbuta / Ha
    text = text.replaceAll('ة', 'ه');
    
    return text.trim();
  }

  /// Combined search normalization (Lowercase + Arabic Normalization)
  String get searchNormalized => this.toLowerCase().normalizeArabic();
}
