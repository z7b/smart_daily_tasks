enum IntentType {
  tasks,
  nextTask,
  appointments,
  medications,
  overview,
  focus,
  healthCheck,
  help,
  createTask,
  general,
}

class IntentAnalyzer {
  static IntentType analyze(String text) {
    // Normalize arabic text: remove diacritics, normalize alef, taa marbouta to haa
    final normalizedText = _normalizeArabic(text.toLowerCase().trim());

    // ─── Help Intent ──────────────────────────────────
    if (_matches(normalizedText, [
      r'مساعد[ةه]', r'ساعدني', r'شو اقدر', r'كيف استخدم',
      r'help', r'how.*use', r'what.*can',
      r'帮助', r'怎么用', r'能做什么', r'使用说明',
      r'幫助', r'怎麼用', r'能做什麼',
      r'सहायता', r'मदद', r'कैसे उपयोग',
      r'aide', r'comment.*utiliser',
      r'ayuda', r'cómo.*usar',
      r'помощь', r'как.*использовать',
    ])) {
      return IntentType.help;
    }

    // ─── Focus Intent ─────────────────────────────────
    if (_matches(normalizedText, [
      r'تركيز', r'اولوي', r'اهم شي', r'شو الاهم',
      r'focus', r'priorit', r'what.*important',
      r'专注', r'重点', r'优先', r'最重要',
      r'專注', r'重點', r'優先', r'最重要',
      r'ध्यान', r'प्राथमिकता', r'सबसे.*महत्वपूर्ण',
      r'focus', r'priorité', r'concentr',
      r'enfoque', r'prioridad',
      r'фокус', r'приоритет', r'важн',
    ])) {
      return IntentType.focus;
    }

    // ─── Health Check Intent ──────────────────────────
    if (_matches(normalizedText, [
      r'صح', r'فحص', r'كيف صحتي', r'حالتي الصحي',
      r'health', r'check.*up', r'how.*health',
      r'健康', r'体检', r'身体', r'健康状况',
      r'健康', r'體檢', r'身體', r'健康狀況',
      r'स्वास्थ्य', r'सेहत', r'तबीयत',
      r'santé', r'bilan',
      r'salud', r'chequeo',
      r'здоровье', r'здоров', r'проверк',
    ])) {
      return IntentType.healthCheck;
    }

    // ─── Tasks Intent ─────────────────────────────────
    if (_matches(normalizedText, [
      r'مهام', r'تاسك', r'شو علي', r'المهام', r'شو عندي', r'الاشياء اللي علي',
      r'tasks', r'my tasks', r'what.*do', r'to.*do',
      r'任务', r'待办', r'我的任务', r'今天.*做',
      r'任務', r'待辦', r'我的任務', r'今天.*做',
      r'कार्य', r'मेरे.*कार्य', r'क्या.*करना',
      r'tâches', r'mes tâches',
      r'tareas', r'mis tareas',
      r'задач', r'мои.*задач', r'что.*делать',
    ])) {
      return IntentType.tasks;
    }

    // ─── Next Task Intent ─────────────────────────────
    if (_matches(normalizedText, [
      r'القادم', r'التالي', r'شو بعدين', r'المهمه الجايه', r'الشي الجاي',
      r'next task', r'upcoming', r'what.*next',
      r'下一个', r'接下来', r'下个任务',
      r'下一個', r'接下來', r'下個任務',
      r'अगला.*कार्य', r'आगे.*क्या',
      r'prochaine.*tâche', r'suivant',
      r'siguiente.*tarea', r'próxim',
      r'следующ', r'что.*дальше',
    ])) {
      return IntentType.nextTask;
    }

    // ─── Appointments Intent ──────────────────────────
    if (_matches(normalizedText, [
      r'مواعيد', r'موعد', r'دكتور', r'عياده', r'مستشفى', r'طبيب',
      r'appointment', r'doctor', r'clinic', r'hospital',
      r'预约', r'挂号', r'医生', r'门诊', r'看病',
      r'預約', r'掛號', r'醫生', r'門診', r'看病',
      r'अपॉइंटमेंट', r'डॉक्टर', r'मिलना',
      r'rendez-vous', r'rdv', r'médecin', r'docteur',
      r'cita', r'médico', r'doctor',
      r'прием', r'врач', r'доктор', r'запись', r'визит',
    ])) {
      return IntentType.appointments;
    }

    // ─── Medications Intent ───────────────────────────
    if (_matches(normalizedText, [
      r'علاج', r'دواء', r'ادويه', r'حبة', r'حبات', r'دواي', r'حبوب',
      r'medication', r'meds', r'pills', r'medicine',
      r'药', r'用药', r'吃药', r'药物',
      r'藥', r'用藥', r'吃藥', r'藥物',
      r'दवा', r'दवाई', r'गोली',
      r'médicament', r'pilule', r'comprimé',
      r'medicamento', r'pastilla', r'medicina',
      r'лекарств', r'таблетк', r'препарат',
    ])) {
      return IntentType.medications;
    }

    // ─── Overview Intent ──────────────────────────────
    if (_matches(normalizedText, [
      r'ملخص', r'نظره عامه', r'يومي', r'خلاصه', r'كيف يومي',
      r'overview', r'summary', r'my day', r'how.*day',
      r'概览', r'总结', r'今天', r'摘要', r'日报',
      r'概覽', r'總結', r'今天', r'摘要', r'日報',
      r'सारांश', r'आज', r'दिन.*कैसा',
      r'résumé', r'aperçu', r'ma journée',
      r'resumen', r'mi día',
      r'обзор', r'итог', r'мой день', r'сводк',
    ])) {
      return IntentType.overview;
    }

    // ─── Create Task Intent ───────────────────────────
    if (_matches(normalizedText, [
      r'اضف مهم[هة]', r'انشئ مهم[هة]', r'سجل مهم[هة]', r'ضيف مهم[هة]',
      r'ذكرني ب', r'اضافه', r'جديد',
      r'add task', r'create task', r'new task', r'remind me',
      r'添加.*任务', r'新建.*任务', r'创建.*任务', r'新任务',
      r'添加.*任務', r'新建.*任務', r'創建.*任務', r'新任務',
      r'कार्य.*जोड़', r'नया.*कार्य', r'याद.*दिला',
      r'ajouter.*tâche', r'nouvelle.*tâche', r'rappel',
      r'añadir.*tarea', r'nueva.*tarea', r'recordar',
      r'добавить.*задач', r'новая.*задач', r'напомн',
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
