import 'package:flutter/foundation.dart';
import '../../core/helpers/log_helper.dart';
import 'package:isar/isar.dart';
import '../models/task_model.dart';

class TaskRepository {
  final Isar _isar;

  TaskRepository(this._isar) {
    talker.info('📋 TaskRepository initialized');
  }

  /// Create a new task with success result
  Future<bool> addTask(Task task) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.tasks.put(task);
      });
      return true;
    } on IsarError catch (e) {
      talker.error('🔴 Isar Database Error (Add): $e');
      return false;
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Add Task)');
      return false;
    }
  }

  // Read all (limited to 300 to prevent OOM)
  Stream<List<Task>> watchAllTasks({int limit = 300}) async* {
    yield* _isar.tasks
        .where()
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  // Read by ID
  Future<Task?> getTask(Id id) async {
    return await _isar.tasks.get(id);
  }

  /// Get all tasks (Future)
  Future<List<Task>> getAllTasks() async {
    return await _isar.tasks.where().findAll();
  }

  /// Update an existing task with success result
  Future<bool> updateTask(Task task) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.tasks.put(task);
      });
      return true;
    } on IsarError catch (e) {
      talker.error('🔴 Isar Database Error (Update): $e');
      return false;
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Update Task)');
      return false;
    }
  }

  // Delete
  Future<void> deleteTask(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.tasks.delete(id);
    });
  }

  /// Mark a task as cancelled
  Future<void> cancelTask(Task task) async {
    await _isar.writeTxn(() async {
      task.status = TaskStatus.cancelled;
      await _isar.tasks.put(task);
    });
  }

  // Search
  Future<List<Task>> searchTasks(String query) async {
    return await _isar.tasks
        .filter()
        .titleLowerContains(query.toLowerCase())
        .limit(50)
        .findAll();
  }

  // Get by Date (Used for Life OS Harmony integration)
  Future<List<Task>> getTasksForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return await _isar.tasks
        .filter()
        .scheduledAtBetween(startOfDay, endOfDay, includeLower: true, includeUpper: false)
        .findAll();
  }

  /// ✅ Phase 4: Intelligence - Automatic Recurrence Instantiation
  /// This ensures that daily/weekly/monthly tasks appear for 'today' if they don't exist yet.
  Future<void> instantiateRecurringTasks() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    talker.info('♻️ Running Recurrence Engine...');
    
    // 1. Get all tasks that are recurring (Candidates)
    final recurringTemplates = await _isar.tasks
        .filter()
        .not()
        .recurrenceEqualTo(TaskRecurrence.none)
        .findAll();
        
    if (recurringTemplates.isEmpty) return;

    await _isar.writeTxn(() async {
      for (final template in recurringTemplates) {
        // Calculate if it's due today
        bool isDue = false;
        if (template.recurrence == TaskRecurrence.daily) isDue = true;
        if (template.recurrence == TaskRecurrence.weekly) {
          isDue = template.scheduledAt.weekday == now.weekday;
        }
        if (template.recurrence == TaskRecurrence.monthly) {
          isDue = template.scheduledAt.day == now.day;
        }

        if (!isDue) continue;

        // Check if an instance already exists for today with the same title
        final existing = await _isar.tasks
            .filter()
            .titleEqualTo(template.title)
            .scheduledAtBetween(today, today.add(const Duration(days: 1)), includeLower: true, includeUpper: false)
            .findFirst();

        if (existing == null) {
          // Create new instance for today
          final instance = template.copyWith(
            id: Isar.autoIncrement,
            scheduledAt: DateTime(today.year, today.month, today.day, template.scheduledAt.hour, template.scheduledAt.minute),
            scheduledEnd: template.scheduledEnd != null 
                ? DateTime(today.year, today.month, today.day, template.scheduledEnd!.hour, template.scheduledEnd!.minute)
                : null,
            status: TaskStatus.active,
            completedAt: null,
            createdAt: now,
          );
          await _isar.tasks.put(instance);
          talker.info('✨ Instantiated recurring task: ${template.title}');
        }
      }
    });
  }
}
