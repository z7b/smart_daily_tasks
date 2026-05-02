import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../data/models/task_model.dart';
import '../../../data/models/note_model.dart';
import '../../../data/models/journal_model.dart';
import '../../../data/providers/task_repository.dart';
import '../../../data/providers/note_repository.dart';
import '../../../data/providers/medication_repository.dart';
import '../../../data/providers/journal_repository.dart';
import '../../../core/helpers/ai_command_helper.dart';
import '../../../core/helpers/log_helper.dart';
import 'assistant_response.dart';

/// Handles database write operations for the Smart Assistant.
/// Refactored to be a "Dumb Executor" — no local parsing, just execution.
class CommandExecutor {
  final TaskRepository _taskRepo;
  final NoteRepository _noteRepo;
  final MedicationRepository _medRepo;
  final JournalRepository _journalRepo;
  CommandExecutor({
    required TaskRepository taskRepo,
    required NoteRepository noteRepo,
    required MedicationRepository medRepo,
    required JournalRepository journalRepo,
  })  : _taskRepo = taskRepo,
        _noteRepo = noteRepo,
        _medRepo = medRepo,
        _journalRepo = journalRepo;

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
    final existing = await _taskRepo.getTasksForDateRange(startOfDay, endOfDay);

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
    if (!result.isSuccess) return AssistantResponse.error('task_delete_error'.tr);
    
    talker.info('🤖 Task deleted: $taskId');
    return AssistantResponse.text('task_deleted'.tr);
  }

  Future<AssistantResponse> executeCompleteTask(int taskId) async {
    final task = await _taskRepo.getTask(taskId);
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
    final result = await _noteRepo.addNote(note);
    if (!result.isSuccess) return AssistantResponse.error('error'.tr);
    
    talker.info('🤖 Note created');
    return AssistantResponse.text('note_added_success'.tr);
  }

  // ─── Journal Operations ────────────────────────────

  Future<AssistantResponse> executeCreateJournal(String content) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final result = await _journalRepo.addOrUpdateJournalForDate(
      today,
      Mood.neutral,
      '- (AI): ${content.trim()}',
    );

    if (!result.isSuccess) return AssistantResponse.error('error'.tr);

    talker.info('🤖 Journal created or updated by AI');
    return AssistantResponse.text('journal_added_success'.tr);
  }

  // ─── Medication Operations ─────────────────────────

  Future<AssistantResponse> executeLogMedication(int medicationId) async {
    final result = await _medRepo.logIntake(medicationId);
    if (!result.isSuccess) return AssistantResponse.error('error'.tr);
    
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
