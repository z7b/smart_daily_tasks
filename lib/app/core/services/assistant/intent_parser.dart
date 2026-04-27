import '../../../core/helpers/ai_command_helper.dart';

/// All possible user intents the assistant can handle
enum IntentType {
  // Commands (Write)
  addTask,
  completeTask,
  completeAllTasks,
  addNote,
  addJournal,
  logMedication,
  setGoal,
  // Queries (Read)
  queryTasks,
  queryNextTask,
  queryAppointments,
  queryNextAppointment,
  queryMedications,
  queryNextMedication,
  queryOverview,
  // Navigation
  openCalendar,
  openTasks,
  openAppointments,
  openMedications,
  openSettings,
  // Social
  greeting,
  help,
  cancel,
  // Fallback
  unknown,
}

/// Result of intent parsing with extracted parameters
class ParsedIntent {
  final IntentType type;
  final Map<String, String> params;
  final double confidence;

  const ParsedIntent({
    required this.type,
    this.params = const {},
    this.confidence = 1.0,
  });
}

/// Keyword definition for intent matching
class _IntentDef {
  final IntentType type;
  final List<String> triggerWords;
  final List<String>? requiredContext; // Must also contain one of these
  final bool extractsPayload;

  const _IntentDef({
    required this.type,
    required this.triggerWords,
    this.requiredContext,
    this.extractsPayload = false,
  });
}

/// Bilingual intent parser using weighted keyword matching.
/// Replaces the flat regex approach with a structured, extensible system.
class IntentParser {
  // ─── Intent Definitions ─────────────────────────────
  // Order matters: more specific intents should come first
  static final List<_IntentDef> _definitions = [
    // ─ Cancel (highest priority) ─
    const _IntentDef(
      type: IntentType.cancel,
      triggerWords: ['cancel', 'الغاء', 'الغ', 'انسى', 'لا', 'stop'],
    ),

    // ─ Greetings ─
    const _IntentDef(
      type: IntentType.greeting,
      triggerWords: ['مرحبا', 'سلام', 'اهلا', 'hi', 'hello', 'hey', 'السلام عليكم'],
    ),

    // ─ Help ─
    const _IntentDef(
      type: IntentType.help,
      triggerWords: ['مساعده', 'مساعدة', 'help', 'كيف', 'ممكن', 'اوامر', 'شو اسوي'],
    ),

    // ─ Complete All Tasks ─
    const _IntentDef(
      type: IntentType.completeAllTasks,
      triggerWords: ['done all', 'finish all', 'complete all', 'خلص كل', 'انجز كل', 'تم كل', 'سويت كل'],
    ),

    // ─ Complete Task ─
    const _IntentDef(
      type: IntentType.completeTask,
      triggerWords: ['done', 'finish', 'complete', 'انجز', 'تم', 'خلصت', 'سويت', 'انهيت'],
      requiredContext: ['task', 'todo', 'مهمه', 'مهمة', 'شغل'],
      extractsPayload: true,
    ),

    // ─ Add Task ─
    const _IntentDef(
      type: IntentType.addTask,
      triggerWords: ['add', 'new', 'create', 'make', 'ضيف', 'اضف', 'انشاء', 'انشئ', 'سوي'],
      requiredContext: ['task', 'todo', 'مهمه', 'مهمة', 'شغل'],
      extractsPayload: true,
    ),

    // ─ Add Note ─
    const _IntentDef(
      type: IntentType.addNote,
      triggerWords: ['add', 'new', 'write', 'take', 'ضيف', 'اضف', 'دون', 'اكتب'],
      requiredContext: ['note', 'memo', 'ملاحظه', 'ملاحظة'],
      extractsPayload: true,
    ),

    // ─ Journal ─
    const _IntentDef(
      type: IntentType.addJournal,
      triggerWords: ['log', 'journal', 'diary', 'record', 'سجل', 'يوميات', 'مذكره', 'مذكرة', 'تدوين', 'كتبت'],
      extractsPayload: true,
    ),

    // ─ Log Medication ─
    const _IntentDef(
      type: IntentType.logMedication,
      triggerWords: ['took', 'taken', 'had', 'اخذت', 'شربت', 'تناولت', 'بلعت'],
      requiredContext: ['med', 'medication', 'medicine', 'pill', 'dose', 'الدواء', 'العلاج', 'الحبه', 'الحبة', 'الجرعه', 'الجرعة', 'برشام', 'علاجي'],
    ),

    // ─ Set Goal ─
    const _IntentDef(
      type: IntentType.setGoal,
      triggerWords: ['set', 'target', 'update', 'هدف', 'هدفي', 'تغيير'],
      requiredContext: ['goal', 'target', 'هدف', 'خطوه', 'خطوة'],
    ),

    // ─── QUERIES ───────────────────────────────────────

    // ─ Query Next Task ─
    const _IntentDef(
      type: IntentType.queryNextTask,
      triggerWords: ['next task', 'المهمه القادمه', 'المهمة القادمة', 'المهمه الجايه', 'كم باقي على المهمه', 'كم باقي على المهمة'],
    ),

    // ─ Query Tasks ─
    const _IntentDef(
      type: IntentType.queryTasks,
      triggerWords: ['my tasks', 'مهامي', 'مهام اليوم', 'ما هي مهامي', 'عرض مهام', 'اعرض مهام', 'ايش مهامي', 'وش مهامي', 'شو مهامي', 'tasks today', "what are my tasks"],
    ),

    // ─ Query Next Appointment ─
    const _IntentDef(
      type: IntentType.queryNextAppointment,
      triggerWords: ['next appointment', 'الموعد القادم', 'موعدي القادم', 'كم باقي على الموعد', 'كم باقي على موعد الدكتور', 'متى موعد الدكتور', 'موعد الدكتور'],
    ),

    // ─ Query Appointments ─
    const _IntentDef(
      type: IntentType.queryAppointments,
      triggerWords: ['my appointments', 'مواعيدي', 'اعرض مواعيدي', 'عرض المواعيد', 'جميع مواعيدي', 'كل المواعيد'],
    ),

    // ─ Query Next Medication ─
    const _IntentDef(
      type: IntentType.queryNextMedication,
      triggerWords: ['next medication', 'next dose', 'الجرعه القادمه', 'الجرعة القادمة', 'متى الجرعه', 'متى الجرعة', 'هل عندي علاج', 'هل لدي علاج'],
    ),

    // ─ Query Medications ─
    const _IntentDef(
      type: IntentType.queryMedications,
      triggerWords: ['my medications', 'my meds', 'ادويتي', 'أدويتي', 'علاجاتي', 'اعرض ادويتي'],
    ),

    // ─ Overview ─
    const _IntentDef(
      type: IntentType.queryOverview,
      triggerWords: ['overview', 'summary', 'ملخص', 'نظره عامه', 'نظرة عامة', 'هل عندي شي', 'هل عندي شيء', 'ايش عندي', 'وش عندي اليوم', 'شو عندي'],
    ),

    // ─── NAVIGATION ────────────────────────────────────

    const _IntentDef(
      type: IntentType.openCalendar,
      triggerWords: ['open calendar', 'افتح التقويم', 'تقويم', 'calendar'],
    ),
    const _IntentDef(
      type: IntentType.openTasks,
      triggerWords: ['open tasks', 'افتح المهام', 'صفحه المهام', 'صفحة المهام'],
    ),
    const _IntentDef(
      type: IntentType.openAppointments,
      triggerWords: ['open appointments', 'افتح المواعيد', 'صفحه المواعيد', 'صفحة المواعيد'],
    ),
    const _IntentDef(
      type: IntentType.openMedications,
      triggerWords: ['open medications', 'افتح الادويه', 'افتح الأدوية', 'صفحه الادويه'],
    ),
    const _IntentDef(
      type: IntentType.openSettings,
      triggerWords: ['open settings', 'افتح الاعدادات', 'افتح الإعدادات', 'اعدادات', 'settings'],
    ),
  ];

  /// Parse user input into a structured intent
  ParsedIntent parse(String rawText) {
    final normalized = AiCommandHelper.normalizeArabic(rawText);

    // 1. Try exact phrase match first (highest confidence)
    for (final def in _definitions) {
      for (final trigger in def.triggerWords) {
        final normalizedTrigger = AiCommandHelper.normalizeArabic(trigger);
        if (normalized == normalizedTrigger || normalized.startsWith('$normalizedTrigger ')) {
          if (def.requiredContext != null) {
            final hasContext = def.requiredContext!.any(
              (ctx) => normalized.contains(AiCommandHelper.normalizeArabic(ctx)),
            );
            if (!hasContext) continue;
          }
          return ParsedIntent(
            type: def.type,
            params: _extractParams(rawText, def),
            confidence: 1.0,
          );
        }
      }
    }

    // 2. Try contains match (medium confidence)
    for (final def in _definitions) {
      for (final trigger in def.triggerWords) {
        final normalizedTrigger = AiCommandHelper.normalizeArabic(trigger);
        if (normalized.contains(normalizedTrigger)) {
          if (def.requiredContext != null) {
            final hasContext = def.requiredContext!.any(
              (ctx) => normalized.contains(AiCommandHelper.normalizeArabic(ctx)),
            );
            if (!hasContext) continue;
          }
          return ParsedIntent(
            type: def.type,
            params: _extractParams(rawText, def),
            confidence: 0.8,
          );
        }
      }
    }

    // 3. Fallback: if it looks like a short title, guess "add task"
    final wordCount = rawText.trim().split(' ').length;
    if (wordCount > 0 && wordCount <= 5) {
      return ParsedIntent(
        type: IntentType.unknown,
        params: {'guessTitle': rawText.trim()},
        confidence: 0.3,
      );
    }

    return const ParsedIntent(type: IntentType.unknown, confidence: 0.0);
  }

  /// Extract payload from the user message after removing trigger/context words
  Map<String, String> _extractParams(String rawText, _IntentDef def) {
    if (!def.extractsPayload) return {};

    String payload = rawText.trim();
    final normalized = AiCommandHelper.normalizeArabic(payload);

    // Remove trigger words
    for (final trigger in def.triggerWords) {
      final nt = AiCommandHelper.normalizeArabic(trigger);
      if (normalized.contains(nt)) {
        payload = payload.replaceFirst(RegExp(RegExp.escape(trigger), caseSensitive: false), '').trim();
      }
    }

    // Remove context words
    if (def.requiredContext != null) {
      for (final ctx in def.requiredContext!) {
        payload = payload.replaceFirst(RegExp(RegExp.escape(ctx), caseSensitive: false), '').trim();
      }
    }

    if (payload.isNotEmpty) {
      return {'payload': payload};
    }
    return {};
  }

  /// Extract a number from text (for goal setting)
  int? extractNumber(String text) => AiCommandHelper.extractNumber(text);
}
