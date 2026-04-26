import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:isar/isar.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/note_model.dart';
import '../../../data/models/journal_model.dart';
import '../../../data/providers/task_repository.dart';
import '../../../data/providers/note_repository.dart';
import '../../../data/providers/medication_repository.dart';
import '../../../data/providers/step_repository.dart';
import '../../../core/helpers/log_helper.dart';
import '../../../core/helpers/ai_command_helper.dart';
import '../../../core/extensions/date_time_extensions.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({required this.text, required this.isUser, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

enum AssistantState {
  idle,
  waitingForTaskTitle,
  waitingForNoteContent,
  waitingForJournalContent,
  waitingForGoal,
}

class AssistantController extends GetxController {
  final messages = <Message>[].obs;
  final isTyping = false.obs;
  final currentState = AssistantState.idle.obs;

  late final TaskRepository _taskRepository;
  late final NoteRepository _noteRepository;
  late final MedicationRepository _medicationRepository;
  late final StepRepository _stepRepository;
  late final Isar _isar;

  @override
  void onInit() {
    super.onInit();
    _taskRepository = Get.find<TaskRepository>();
    _noteRepository = Get.find<NoteRepository>();
    _medicationRepository = Get.find<MedicationRepository>();
    _stepRepository = Get.find<StepRepository>();
    _isar = Get.find<Isar>();
    talker.info('🤖 AssistantController initialized with Governance Sync');
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    // ✅ Doctoral Fix: Using translation key for the whole welcome block
    final greeting = _getGreeting();
    messages.add(Message(text: '$greeting\n${'assistant_welcome'.tr}', isUser: false));
  }

  // 🛡️ Debounce: Prevent duplicate commands from rapid taps
  DateTime? _lastActionTime;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 🛡️ 2-second cooldown to prevent duplicate task creation
    final now = DateTime.now();
    if (_lastActionTime != null &&
        now.difference(_lastActionTime!) < const Duration(seconds: 2)) {
      return;
    }
    _lastActionTime = now;

    messages.add(Message(text: text, isUser: true));
    isTyping.value = true;
    
    // Humanized variability in response time
    final delay = 400 + (text.length * 10).clamp(0, 1000);
    await Future.delayed(Duration(milliseconds: delay));
    
    await _processCommand(text);
    isTyping.value = false;
  }

  void clearChat() {
    messages.clear();
    currentState.value = AssistantState.idle;
    _addWelcomeMessage();
    talker.info('🧹 Assistant chat cleared by user');
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'good_morning'.tr;
    if (hour < 17) return 'good_afternoon'.tr;
    return 'good_evening'.tr;
  }

  Future<void> _processCommand(String text) async {
    final rawText = text.trim();
    final normalized = AiCommandHelper.normalizeArabic(rawText);
    String responseText = '';

    try {
      // 🛡️ Contextual Memory Governance
      if (normalized == 'cancel' || normalized == 'الغاء' || normalized == 'انسى') {
        if (currentState.value != AssistantState.idle) {
          currentState.value = AssistantState.idle;
          responseText = 'command_cancelled'.tr;
          messages.add(Message(text: responseText, isUser: false));
          return;
        }
      }

      // Handle follow-up responses based on state
      if (currentState.value == AssistantState.waitingForTaskTitle) {
        responseText = await _addTask(rawText);
        currentState.value = AssistantState.idle;
      } else if (currentState.value == AssistantState.waitingForNoteContent) {
        await _addNote(rawText);
        responseText = 'note_added_success'.tr;
        currentState.value = AssistantState.idle;
      } else if (currentState.value == AssistantState.waitingForJournalContent) {
        await _addJournal(rawText);
        responseText = 'journal_added_success'.tr;
        currentState.value = AssistantState.idle;
      } else {
        // 🛡️ Governance: Centralized Command Definitions (Expert Logic)
        final taskAddRegex = RegExp(
          r'^(?:add|new|create|make|ضيف|اضف|انشاء|مهمه)\s+(?:task|todo|مهمه|شغل)(?:\s+(.+))?',
        );
        final taskDoneRegex = RegExp(
          r'^(?:done|finish|complete|انجز|تم|خلصت|سويت)\s+(?:task|todo|مهمه|شغل)\s+(.+)',
        );
        final noteRegex = RegExp(
          r'^(?:add|new|write|take|ضيف|اضف|دون|اكتب|ملاحظه)\s+(?:note|memo|ملاحظه)(?:\s+(.+))?',
        );
        final journalRegex = RegExp(
          r'^(?:log|journal|diary|record|سجل|يوميات|مذكره|تدوين|كتبت)(?:\s+(.+))?',
        );
        final stepsRegex = RegExp(
          r'^(?:add|log|record|سجل|مشيت|خطوات|ضيف)\s+(\d+)\s+(?:steps|خطوه)',
        );
        final goalRegex = RegExp(
          r'^(?:set|target|update|هدف|هدفي|تغيير)\s+(?:goal|target|هدف)\s+(\d+)',
        );
        final medRegex = RegExp(
          r'^(?:took|taken|had|log|record|اخذت|شربت|سجل|تم|تناولت|بلعت)\s+(?:med|medication|medicine|pill|dose|tabs|الدواء|العلاج|الحبه|الجرعة|برشام|علاجي)(?:\s+(.+))?',
        );

        final completeAllRegex = RegExp(r'^(?:done|finish|complete|انجز|تم|خلصت|سويت)\s+all');
        final completeAllArRegex = RegExp(r'^(?:خلص|انجز|تم|سويت)\s+كل');

        if (normalized.contains('مرحبا') ||
            normalized.contains('سلام') ||
            normalized.contains('hi') ||
            normalized.contains('hello')) {
          responseText = 'assistant_greeting'.tr;
        }
        // 1. Task Management
        else if (taskAddRegex.hasMatch(normalized)) {
          final match = taskAddRegex.firstMatch(normalized);
          final rawTitle = match?.group(1)?.trim() ?? '';
          if (rawTitle.isNotEmpty) {
            responseText = await _addTask(rawTitle);
          } else {
            currentState.value = AssistantState.waitingForTaskTitle;
            responseText = 'ask_task_title'.tr;
          }
        } else if (completeAllRegex.hasMatch(normalized) || completeAllArRegex.hasMatch(normalized)) {
          responseText = await _completeAllTasks();
        } else if (taskDoneRegex.hasMatch(normalized)) {
          final match = taskDoneRegex.firstMatch(normalized);
          final query = match?.group(1)?.trim() ?? '';
          responseText = await _completeTask(query);
        }
        // 2. Note Taking
        else if (noteRegex.hasMatch(normalized)) {
          final match = noteRegex.firstMatch(normalized);
          final content = match?.group(1)?.trim() ?? '';
          if (content.isNotEmpty) {
            await _addNote(content);
            responseText = 'note_added_success'.tr;
          } else {
            currentState.value = AssistantState.waitingForNoteContent;
            responseText = 'ask_note_content'.tr;
          }
        }
        // 3. Journaling (with Upsert Governance)
        else if (journalRegex.hasMatch(normalized)) {
          final match = journalRegex.firstMatch(normalized);
          final content = match?.group(1)?.trim() ?? '';
          if (content.isNotEmpty) {
            await _addJournal(content);
            responseText = 'journal_added_success'.tr;
          } else {
            currentState.value = AssistantState.waitingForJournalContent;
            responseText = 'ask_journal_content'.tr;
          }
        }
        // 4. Health & Steps
        else if (stepsRegex.hasMatch(normalized)) {
          final match = stepsRegex.firstMatch(normalized);
          final count = int.tryParse(match?.group(1) ?? '0') ?? 0;
          await _recordSteps(count);
          responseText = 'steps_added'.tr;
        } else if (goalRegex.hasMatch(normalized)) {
          final match = goalRegex.firstMatch(normalized);
          final goal = int.tryParse(match?.group(1) ?? '0') ?? 0;
          await _updateStepGoal(goal);
          responseText = 'goal_updated'.tr;
        }
        // 5. Medications
        else if (medRegex.hasMatch(normalized)) {
          responseText = await _recordMedicationIntake();
        }
        // 6. Navigation & Help
        else if (normalized.contains('مساعده') || normalized.contains('help')) {
          responseText = 'assistant_help_cmd'.tr;
        } else if (normalized.contains('تقويم') ||
            normalized.contains('calendar')) {
          Get.toNamed('/calendar');
          responseText = '📅 ${'calendar'.tr}';
        } else {
          // 🛡️ Smart Fallback: Guessing the user's intent if it looks like a title
          final wordCount = rawText.split(' ').length;
          if (wordCount > 0 && wordCount <= 5) {
            currentState.value = AssistantState.waitingForTaskTitle;
            responseText = 'guess_add_task'.trParams({'title': rawText});
          } else {
            responseText = 'not_understood'.tr;
          }
        }
      }

      messages.add(Message(text: responseText, isUser: false));
    } catch (e, stack) {
      talker.handle(e, stack, '🤖 Assistant command processing error');
      messages.add(Message(text: '${'error'.tr}: $e', isUser: false));
    }
  }

  Future<String> _addTask(String rawTitle) async {
    final targetDate = AiCommandHelper.parseDate(rawTitle);
    final priority = AiCommandHelper.parsePriority(rawTitle);
    
    // Clean title from date/priority keywords for aesthetic storage
    String cleanTitle = rawTitle
        .replaceAll(RegExp(r'(بكرة|tomorrow|اليوم|today|عالي|high|مهم|عاجل)', caseSensitive: false), '')
        .trim();
    if (cleanTitle.isEmpty) cleanTitle = rawTitle;

    // 🛡️ Governance: Collision Prevention
    final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final existingTasks = await _isar.tasks
        .filter()
        .scheduledAtBetween(startOfDay, endOfDay)
        .findAll();
    
    final isDuplicate = existingTasks.any((t) => 
        AiCommandHelper.normalizeArabic(t.title) == AiCommandHelper.normalizeArabic(cleanTitle));

    if (isDuplicate) {
      return 'task_already_exists'.trParams({'title': cleanTitle});
    }

    final task = Task(
      title: cleanTitle,
      scheduledAt: targetDate,
      priority: priority,
      createdAt: DateTime.now(),
    );
    await _taskRepository.addTask(task);
    return 'task_added_success'.trParams({'title': cleanTitle});
  }

  Future<String> _completeAllTasks() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final todayTasks = await _isar.tasks
        .filter()
        .scheduledAtBetween(startOfDay, endOfDay)
        .statusEqualTo(TaskStatus.active)
        .findAll();

    if (todayTasks.isEmpty) {
      return 'no_active_tasks_today'.tr;
    }

    await _isar.writeTxn(() async {
      for (var task in todayTasks) {
        task.status = TaskStatus.completed;
        task.completedAt = DateTime.now();
        await _isar.tasks.put(task);
      }
    });

    return 'all_tasks_completed'.trParams({'count': todayTasks.length.toString()});
  }

  Future<void> _addNote(String content) async {
    final note = Note(
      title: 'add_note'.tr,
      content: content,
      createdAt: DateTime.now(),
    );
    await _noteRepository.addNote(note);
  }

  Future<void> _addJournal(String content) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 🛡️ Governance: Upsert Daily Singularity Logic
    final existing = await _isar.journals
        .filter()
        .dateEqualTo(today)
        .findFirst();

    if (existing != null) {
      existing.note = '${existing.note}\n- (AI): ${content.trim()}';
      await _isar.writeTxn(() async {
        await _isar.journals.put(existing);
      });
      talker.info('📝 Journal entry updated by Assistant');
    } else {
      final journal = Journal(
        date: today,
        mood: Mood.neutral,
        note: content.trim(),
        createdAt: now,
      );
      await _isar.writeTxn(() async {
        await _isar.journals.put(journal);
      });
      talker.info('📝 New journal entry created by Assistant');
    }
  }

  Future<String> _completeTask(String query) async {
    final normalizedQuery = AiCommandHelper.normalizeArabic(query);
    final allTasks = await _taskRepository.getAllTasks();

    try {
      // Find tasks where title contains the query (Normalized)
      final matching = allTasks.where((t) {
        final normTitle = AiCommandHelper.normalizeArabic(t.title);
        return normTitle.contains(normalizedQuery) &&
            t.status != TaskStatus.completed;
      }).toList();

      if (matching.isEmpty) {
        return 'no_matching_task'.tr;
      }

      final taskToComplete = matching.first;
      taskToComplete.status = TaskStatus.completed;
      taskToComplete.completedAt = DateTime.now();
      await _taskRepository.updateTask(taskToComplete);

      return 'task_completed_success'.trParams({'title': taskToComplete.title});
    } catch (e) {
      return 'error'.tr;
    }
  }

  Future<void> _recordSteps(int count) async {
    await _stepRepository.updateStepsLocally(
      DateTime.now(),
      count,
      isManual: true,
    );
  }

  Future<void> _updateStepGoal(int goal) async {
    if (goal <= 0) return;
    final storage = Get.find<GetStorage>();
    storage.write('daily_step_goal', goal);
    talker.info('🎯 Assistant updated global step goal to $goal');
  }

  Future<String> _recordMedicationIntake() async {
    try {
      final meds = await _medicationRepository.getAllMedications();
      final activeMeds = meds.where((m) => m.isActive).toList();

      if (activeMeds.isEmpty) {
        return 'no_active_meds'.tr;
      }

      // Doctoral Logic: Find the first medication that hasn't reached its daily dose limit
      final now = DateTime.now();
      for (var med in activeMeds) {
        final todayIntakes = med.intakeHistory
            .where((dt) => dt.isSameDay(now))
            .length;

        if (todayIntakes < med.reminderTimes.length) {
          await _medicationRepository.logIntake(med.id);
          return 'med_logged_success'.trParams({'name': med.name});
        }
      }

      return 'all_meds_taken_today'.tr;
    } catch (e) {
      return '${'error'.tr}: $e';
    }
  }
}
