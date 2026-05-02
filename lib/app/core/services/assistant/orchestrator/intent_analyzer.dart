enum IntentType {
  tasks,
  nextTask,
  appointments,
  medications,
  overview,
  createTask,
  general,
}

class IntentAnalyzer {
  static IntentType analyze(String text) {
    // Normalize arabic text: remove diacritics, normalize alef, taa marbouta to haa
    final normalizedText = _normalizeArabic(text.toLowerCase().trim());

    // Tasks Intent
    if (_matches(normalizedText, [
      r'مهام', r'تاسك', r'شو علي', r'المهام', r'شو عندي', r'الاشياء اللي علي',
      r'tasks', r'my tasks', r'what.*do',
    ])) {
      return IntentType.tasks;
    }

    // Next Task Intent
    if (_matches(normalizedText, [
      r'القادم', r'التالي', r'شو بعدين', r'المهمه الجايه', r'الشي الجاي',
      r'next task', r'upcoming', r'what.*next',
    ])) {
      return IntentType.nextTask;
    }

    // Appointments Intent
    if (_matches(normalizedText, [
      r'مواعيد', r'موعد', r'دكتور', r'عياده', r'مستشفى', r'طبيب',
      r'appointments', r'doctor', r'clinic', r'hospital',
    ])) {
      return IntentType.appointments;
    }

    // Medications Intent
    if (_matches(normalizedText, [
      r'علاج', r'دواء', r'ادويه', r'حبة', r'حبات', r'دواي', r'حبوب',
      r'medication', r'meds', r'pills', r'medicine',
    ])) {
      return IntentType.medications;
    }

    // Overview Intent
    if (_matches(normalizedText, [
      r'ملخص', r'نظره عامه', r'يومي', r'خلاصه', r'كيف يومي',
      r'overview', r'summary', r'my day', r'how.*day',
    ])) {
      return IntentType.overview;
    }

    // Create Task Intent
    if (_matches(normalizedText, [
      r'اضف مهم[هة]', r'انشئ مهم[هة]', r'سجل مهم[هة]', r'ضيف مهم[هة]',
      r'ذكرني ب', r'اضافه', r'جديد',
      r'add task', r'create task', r'new task', r'remind me',
    ])) {
      return IntentType.createTask;
    }

    return IntentType.general;
  }

  static bool _matches(String text, List<String> patterns) {
    for (var pattern in patterns) {
      final regExp = RegExp(pattern, caseSensitive: false);
      if (regExp.hasMatch(text)) return true;
    }
    return false;
  }

  static String _normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[أإآ]'), 'ا') // Normalize Alef
        .replaceAll('ة', 'ه') // Normalize Taa Marbouta to Haa
        .replaceAll(RegExp(r'[\u064B-\u065F]'), ''); // Remove diacritics (Tashkeel)
  }
}
