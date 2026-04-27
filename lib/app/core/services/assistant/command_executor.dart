import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:isar/isar.dart';

import '../../../data/models/task_model.dart';
import '../../../data/models/note_model.dart';
import '../../../data/models/journal_model.dart';
import '../../../data/providers/task_repository.dart';
import '../../../data/providers/note_repository.dart';
import '../../../data/providers/medication_repository.dart';
import '../../../core/helpers/ai_command_helper.dart';
import '../../../core/helpers/log_helper.dart';
import '../../../core/extensions/date_time_extensions.dart';
import 'assistant_response.dart';

/// Handles all write operations (add, complete, delete) for the Smart Assistant.
/// Extracted from the old monolithic AssistantController.
class CommandExecutor {
  final TaskRepository _taskRepo;
  final NoteRepository _noteRepo;
  final MedicationRepository _medRepo;
  final Isar _isar;

  CommandExecutor({
    required TaskRepository taskRepo,
    required NoteRepository noteRepo,
    required MedicationRepository medRepo,
    required Isar isar,
  })  : _taskRepo = taskRepo,
        _noteRepo = noteRepo,
        _medRepo = medRepo,
        _isar = isar;

  // ─── Task Commands ─────────────────────────────────

  Future<AssistantResponse> addTask(String rawTitle) async {
    final targetDate = AiCommandHelper.parseDate(rawTitle);
    final priority = AiCommandHelper.parsePriority(rawTitle);

    String cleanTitle = rawTitle
        .replaceAll(
            RegExp(r'(بكرة|بكره|tomorrow|اليوم|today|عالي|high|مهم|عاجل)',
                caseSensitive: false),
            '')
        .trim();
    if (cleanTitle.isEmpty) cleanTitle = rawTitle;

    // Collision Prevention
    final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final existing = await _isar.tasks
        .filter()
        .scheduledAtBetween(startOfDay, endOfDay)
        .findAll();

    final isDuplicate = existing.any((t) =>
        AiCommandHelper.normalizeArabic(t.title) ==
        AiCommandHelper.normalizeArabic(cleanTitle));

    if (isDuplicate) {
      return AssistantResponse.text(
        'task_already_exists'.trParams({'title': cleanTitle}),
      );
    }

    final task = Task(
      title: cleanTitle,
      scheduledAt: targetDate,
      priority: priority,
      createdAt: DateTime.now(),
    );
    await _taskRepo.addTask(task);
    talker.info('🤖 Assistant created task: $cleanTitle');

    return AssistantResponse.text(
      'task_added_success'.trParams({'title': cleanTitle}),
    );
  }

  Future<AssistantResponse> completeTask(String query) async {
    final normalizedQuery = AiCommandHelper.normalizeArabic(query);
    final allTasks = await _taskRepo.getAllTasks();

    final matching = allTasks.where((t) {
      final normTitle = AiCommandHelper.normalizeArabic(t.title);
      return normTitle.contains(normalizedQuery) &&
          t.status != TaskStatus.completed;
    }).toList();

    if (matching.isEmpty) {
      return AssistantResponse.text('no_matching_task'.tr);
    }

    final taskToComplete = matching.first;
    taskToComplete.status = TaskStatus.completed;
    taskToComplete.completedAt = DateTime.now();
    await _taskRepo.updateTask(taskToComplete);
    talker.info('🤖 Assistant completed task: ${taskToComplete.title}');

    return AssistantResponse.text(
      'task_completed_success'.trParams({'title': taskToComplete.title}),
    );
  }

  Future<AssistantResponse> completeAllTasks() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final todayTasks = await _isar.tasks
        .filter()
        .scheduledAtBetween(startOfDay, endOfDay)
        .statusEqualTo(TaskStatus.active)
        .findAll();

    if (todayTasks.isEmpty) {
      return AssistantResponse.text('no_active_tasks_today'.tr);
    }

    await _isar.writeTxn(() async {
      for (var task in todayTasks) {
        task.status = TaskStatus.completed;
        task.completedAt = DateTime.now();
        await _isar.tasks.put(task);
      }
    });
    talker.info('🤖 Assistant completed ${todayTasks.length} tasks');

    return AssistantResponse.text(
      'all_tasks_completed'.trParams({'count': todayTasks.length.toString()}),
    );
  }

  // ─── Note Commands ─────────────────────────────────

  Future<AssistantResponse> addNote(String content) async {
    final note = Note(
      title: 'add_note'.tr,
      content: content,
      createdAt: DateTime.now(),
    );
    await _noteRepo.addNote(note);
    talker.info('🤖 Assistant created note');
    return AssistantResponse.text('note_added_success'.tr);
  }

  // ─── Journal Commands ──────────────────────────────

  Future<AssistantResponse> addJournal(String content) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Upsert: append to existing or create new
    final existing = await _isar.journals
        .filter()
        .dateEqualTo(today)
        .findFirst();

    if (existing != null) {
      existing.note = '${existing.note}\n- (AI): ${content.trim()}';
      await _isar.writeTxn(() async {
        await _isar.journals.put(existing);
      });
      talker.info('🤖 Assistant updated journal entry');
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
      talker.info('🤖 Assistant created new journal entry');
    }

    return AssistantResponse.text('journal_added_success'.tr);
  }

  // ─── Medication Commands ───────────────────────────

  Future<AssistantResponse> logMedication() async {
    final meds = await _medRepo.getAllMedications();
    final active = meds.where((m) => m.isActive).toList();

    if (active.isEmpty) {
      return AssistantResponse.text('no_active_meds'.tr);
    }

    final now = DateTime.now();
    for (var med in active) {
      final todayIntakes = med.intakeHistory
          .where((dt) => dt.isSameDay(now))
          .length;

      if (todayIntakes < med.reminderTimes.length) {
        await _medRepo.logIntake(med.id);
        talker.info('🤖 Assistant logged medication intake: ${med.name}');
        return AssistantResponse.text(
          'med_logged_success'.trParams({'name': med.name}),
        );
      }
    }

    return AssistantResponse.text('all_meds_taken_today'.tr);
  }

  // ─── Goal Commands ─────────────────────────────────

  Future<AssistantResponse> setStepGoal(int goal) async {
    if (goal <= 0) {
      return AssistantResponse.text('error'.tr);
    }
    final storage = GetStorage();
    storage.write('daily_step_goal', goal);
    talker.info('🤖 Assistant updated step goal to $goal');
    return AssistantResponse.text('goal_updated'.tr);
  }
}
