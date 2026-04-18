import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/storage_keys.dart';

class AppTheme {
  // iOS/Apple Style Aesthetics
  static const Color backgroundLight = Color(0xFFF2F2F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color primary = Color(0xFF007AFF);
  static const Color secondary = Color(0xFFFF2D55);
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0xFF8E8E93);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFEBEBF5);

  static double fontSizeScale(String sizeKey) {
    switch (sizeKey.toLowerCase()) {
      case 'small': return 0.85;  // 📏 Expert Scaling for high visibility
      case 'medium': return 1.0;
      case 'large': return 1.25;  // 🚀 Balanced "Wowed" scaling
      default: return 1.0;
    }
  }

  static double _fontSizeScale(String sizeKey) => fontSizeScale(sizeKey);

  static TextTheme _resolveBaseTextTheme(String fontName) {
    // Ensuring Arabic fonts have proper height for visibility
    final double height = (fontName == 'Amiri' || fontName == 'Cairo') ? 1.4 : 1.2;
    
    try {
      switch (fontName) {
        case 'Cairo': return GoogleFonts.cairoTextTheme().apply(bodyColor: Colors.black, displayColor: Colors.black);
        case 'Amiri': return GoogleFonts.amiriTextTheme().apply(bodyColor: Colors.black, displayColor: Colors.black);
        case 'Tajawal': return GoogleFonts.tajawalTextTheme().apply(bodyColor: Colors.black, displayColor: Colors.black);
        case 'Rubik': default: return GoogleFonts.rubikTextTheme().apply(bodyColor: Colors.black, displayColor: Colors.black);
      }
    } catch (_) {
      return GoogleFonts.rubikTextTheme();
    }
  }

  /// ✅ Pro Fix: Scaling ALL 15 Material 3 text styles
  static TextTheme _buildCompleteTextTheme({
    required String fontName,
    required double scale,
    required Color primaryColor,
  }) {
    final base = _resolveBaseTextTheme(fontName);
    
    // Helper to scale a single TextStyle
    TextStyle? scaleStyle(TextStyle? style, {bool isBold = false}) {
      if (style == null) return null;
      return style.copyWith(
        fontSize: (style.fontSize ?? 14) * scale,
        color: primaryColor,
        fontWeight: isBold ? FontWeight.bold : style.fontWeight,
        height: (fontName == 'Amiri') ? 1.5 : null, // Amiri needs more line height
      );
    }

    return TextTheme(
      displayLarge: scaleStyle(base.displayLarge, isBold: true),
      displayMedium: scaleStyle(base.displayMedium, isBold: true),
      displaySmall: scaleStyle(base.displaySmall, isBold: true),
      headlineLarge: scaleStyle(base.headlineLarge, isBold: true),
      headlineMedium: scaleStyle(base.headlineMedium, isBold: true),
      headlineSmall: scaleStyle(base.headlineSmall, isBold: true),
      titleLarge: scaleStyle(base.titleLarge, isBold: true),
      titleMedium: scaleStyle(base.titleMedium, isBold: true),
      titleSmall: scaleStyle(base.titleSmall, isBold: true),
      bodyLarge: scaleStyle(base.bodyLarge),
      bodyMedium: scaleStyle(base.bodyMedium),
      bodySmall: scaleStyle(base.bodySmall),
      labelLarge: scaleStyle(base.labelLarge),
      labelMedium: scaleStyle(base.labelMedium),
      labelSmall: scaleStyle(base.labelSmall),
    );
  }

  static (String, double) _readFontPrefs() {
    try {
      final box = GetStorage();
      final String fontName = box.read('fontType') ?? 'Rubik';
      final String sizeKey  = box.read('fontSize') ?? 'medium';
      return (fontName, _fontSizeScale(sizeKey));
    } catch (_) {
      return ('Rubik', 1.0);
    }
  }

  static ThemeData buildTheme({
    required bool isDark,
    required String fontName,
    required String fontSizeKey,
  }) {
    final scale = _fontSizeScale(fontSizeKey);
    final bg = isDark ? backgroundDark : backgroundLight;
    final surface = isDark ? surfaceDark : surfaceLight;
    final textPrimary = isDark ? textPrimaryDark : textPrimaryLight;
    final brightness = isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primary,
      scaffoldBackgroundColor: bg,
      cardColor: surface,
      textTheme: _buildCompleteTextTheme(
        fontName: fontName,
        scale: scale,
        primaryColor: textPrimary,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        surface: surface,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        centerTitle: true
      ),
    );
  }

  // Deprecated getters - maintained for backward compatibility if needed, 
  // but buildTheme is preferred for reactive logic.
  static ThemeData get lightTheme => buildTheme(isDark: false, fontName: 'Rubik', fontSizeKey: 'medium');
  static ThemeData get darkTheme => buildTheme(isDark: true, fontName: 'Rubik', fontSizeKey: 'medium');
}
