
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
    final lowerText = text.toLowerCase().trim();

    // Arabic Patterns
    if (_matches(lowerText, ['مهامي', 'المهام', 'شو علي اليوم', 'tasks'])) {
      return IntentType.tasks;
    }
    if (_matches(lowerText, ['المهمة القادمة', 'التالي', 'next task'])) {
      return IntentType.nextTask;
    }
    if (_matches(lowerText, ['مواعيد', 'دكتور', 'عيادة', 'appointments'])) {
      return IntentType.appointments;
    }
    if (_matches(lowerText, ['علاج', 'دواء', 'ادوية', 'medication', 'meds'])) {
      return IntentType.medications;
    }
    if (_matches(lowerText, ['ملخص', 'نظرة عامة', 'يومي', 'overview', 'summary'])) {
      return IntentType.overview;
    }
    if (_matches(lowerText, ['أضف مهمة', 'انشئ مهمة', 'سجل مهمة', 'add task', 'create task'])) {
      return IntentType.createTask;
    }

    return IntentType.general;
  }

  static bool _matches(String text, List<String> patterns) {
    return patterns.any((p) => text.contains(p));
  }
}
