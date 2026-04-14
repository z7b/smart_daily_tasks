/// Type-safe enums for Settings page — GENERAL section.
///
/// Every enum value carries a [key] that matches the GetX
/// translation key **and** the GetStorage persistence key.
/// This prevents typos while keeping the UI's `.tr` calls intact.

// ─── Language ─────────────────────────────────────────────
enum AppLanguage {
  arabic('ar'),
  english('en');

  const AppLanguage(this.code);

  /// ISO 639-1 language code stored in GetStorage.
  final String code;

  /// Resolve from stored code; defaults to [arabic] if unknown.
  static AppLanguage fromCode(String? code) {
    switch (code) {
      case 'en':
        return AppLanguage.english;
      case 'ar':
      default:
        return AppLanguage.arabic;
    }
  }
}

// ─── Start Screen ─────────────────────────────────────────
enum StartScreen {
  home('home'),
  calendar('calendar'),
  tasks('tasks'),
  notes('notes'),
  journal('journal');

  const StartScreen(this.key);

  /// Translation key **and** storage value (e.g. 'home', 'tasks').
  final String key;

  /// Resolve from stored string; defaults to [home] if unknown.
  static StartScreen fromKey(String? key) {
    for (final screen in StartScreen.values) {
      if (screen.key == key) return screen;
    }
    return StartScreen.home;
  }

  /// Returns the matching GetX route path.
  String get routePath {
    switch (this) {
      case StartScreen.home:
        return '/home';
      case StartScreen.calendar:
        return '/calendar';
      case StartScreen.tasks:
        return '/tasks';
      case StartScreen.notes:
        return '/notes';
      case StartScreen.journal:
        return '/journal';
    }
  }
}

// ─── First Day of Week ────────────────────────────────────
enum DayOfWeek {
  saturday('saturday', DateTime.saturday),
  sunday('sunday', DateTime.sunday),
  monday('monday', DateTime.monday);

  const DayOfWeek(this.key, this.dartWeekday);

  /// Translation key **and** storage value.
  final String key;

  /// Matching [DateTime.weekday] constant (1=Mon … 7=Sun).
  final int dartWeekday;

  /// Resolve from stored string; defaults to [sunday] if unknown.
  static DayOfWeek fromKey(String? key) {
    for (final day in DayOfWeek.values) {
      if (day.key == key) return day;
    }
    return DayOfWeek.sunday;
  }
}
