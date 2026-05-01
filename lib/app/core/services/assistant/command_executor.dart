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
import 'assistant_response.dart';

/// Handles database write operations for the Smart Assistant.
/// Refactored to be a "Dumb Executor" — no local parsing, just execution.
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

  // ─── Task Operations ───────────────────────────────

  Future<AssistantResponse> executeCreateTask({
    required String title,
    DateTime? scheduledAt,
    int? priority,
    String? description,
  }) async {
    final targetDate = scheduledAt ?? DateTime.now();
    final taskPriority = priority == 3 
        ? TaskPriority.high 
        : (priority == 1 ? TaskPriority.low : TaskPriority.medium);

    // Collision Prevention
    final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final existing = await _isar.tasks
        .filter()
        .scheduledAtBetween(startOfDay, endOfDay)
        .findAll();

    final isDuplicate = existing.any((t) =>
        AiCommandHelper.normalizeArabic(t.title) ==
        AiCommandHelper.normalizeArabic(title));

    if (isDuplicate) {
      return AssistantResponse.text(
        'task_already_exists'.trParams({'title': title}),
      );
    }

    final task = Task(
      title: title,
      note: description,
      scheduledAt: targetDate,
      priority: taskPriority,
      createdAt: DateTime.now(),
    );

    final result = await _taskRepo.addTask(task);
    if (!result.isSuccess) {
      talker.error('🔴 CommandExecutor failed to add task: ${result.error}');
      return AssistantResponse.error('error'.tr);
    }

    talker.info('🤖 Task created: $title');
    return AssistantResponse.text(
      'task_added_success'.trParams({'title': title}),
    );
  }

  Future<AssistantResponse> executeDeleteTask(int taskId) async {
    final result = await _taskRepo.deleteTask(taskId);
    if (!result) return AssistantResponse.error('task_delete_error'.tr);
    
    talker.info('🤖 Task deleted: $taskId');
    return AssistantResponse.text('task_deleted'.tr);
  }

  Future<AssistantResponse> executeCompleteTask(int taskId) async {
    final task = await _isar.tasks.get(taskId);
    if (task == null) return AssistantResponse.error('no_matching_task'.tr);

    task.status = TaskStatus.completed;
    task.completedAt = DateTime.now();
    
    final result = await _taskRepo.updateTask(task);
    if (!result.isSuccess) return AssistantResponse.error('error'.tr);
    
    talker.info('🤖 Task completed: ${task.title}');
    return AssistantResponse.text('task_completed_success'.trParams({'title': task.title}));
  }

  // ─── Note Operations ───────────────────────────────

  Future<AssistantResponse> executeCreateNote(String content, {String? title}) async {
    final note = Note(
      title: title ?? 'add_note'.tr,
      content: content,
      createdAt: DateTime.now(),
    );
    await _noteRepo.addNote(note);
    talker.info('🤖 Note created');
    return AssistantResponse.text('note_added_success'.tr);
  }

  // ─── Journal Operations ────────────────────────────

  Future<AssistantResponse> executeCreateJournal(String content) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final existing = await _isar.journals.filter().dateEqualTo(today).findFirst();

    if (existing != null) {
      existing.note = '${existing.note}\n- (AI): ${content.trim()}';
      await _isar.writeTxn(() => _isar.journals.put(existing));
      talker.info('🤖 Journal updated');
    } else {
      final journal = Journal(
        date: today,
        mood: Mood.neutral,
        note: content.trim(),
        createdAt: now,
      );
      await _isar.writeTxn(() => _isar.journals.put(journal));
      talker.info('🤖 Journal created');
    }

    return AssistantResponse.text('journal_added_success'.tr);
  }

  // ─── Medication Operations ─────────────────────────

  Future<AssistantResponse> executeLogMedication(int medicationId) async {
    await _medRepo.logIntake(medicationId);
    talker.info('🤖 Medication intake logged: $medicationId');
    return AssistantResponse.text('med_logged_success'.tr);
  }

  // ─── Goal Operations ───────────────────────────────

  Future<AssistantResponse> executeSetStepGoal(int goal) async {
    if (goal <= 0) return AssistantResponse.error('invalid_goal'.tr);
    GetStorage().write('daily_step_goal', goal);
    talker.info('🤖 Step goal updated to $goal');
    return AssistantResponse.text('goal_updated'.tr);
  }
}
