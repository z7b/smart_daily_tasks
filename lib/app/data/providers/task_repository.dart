import '../../core/helpers/log_helper.dart';
import 'package:isar/isar.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
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

  // ✅ Phase 2: Memory Over-fetching fix
  Stream<List<Task>> watchTasksForDateRange(DateTime start, DateTime end) async* {
    yield* _isar.tasks
        .filter()
        .scheduledAtBetween(start, end, includeLower: true, includeUpper: false)
        .sortByScheduledAt()
        .watch(fireImmediately: true);
  }

  Future<List<Task>> getTasksForDateRange(DateTime start, DateTime end) async {
    return await _isar.tasks
        .filter()
        .scheduledAtBetween(start, end, includeLower: true, includeUpper: false)
        .sortByScheduledAt()
        .findAll();
  }

  // ✅ Used for Home Predictive Engine
  Future<Task?> getNextActiveTask(DateTime afterDate) async {
    return await _isar.tasks
        .filter()
        .statusEqualTo(TaskStatus.active)
        .scheduledAtGreaterThan(afterDate)
        .sortByScheduledAt()
        .findFirst();
  }

  // Read by ID
  Future<Task?> getTask(Id id) async {
    return await _isar.tasks.get(id);
  }

  // ✅ Global Watcher for Dashboard Sync
  Stream<void> watchAllTasks() {
    return _isar.tasks.watchLazy();
  }

  /// Get all tasks (Future) with error handling
  Future<List<Task>> getAllTasks() async {
    try {
      return await _isar.tasks.where().findAll();
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Failed to load tasks from database');
      return [];
    }
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

  /// ✅ Phase 2: Atomicity Failure fix - Completes task and spawns recurrence in one transaction
  Future<bool> completeAndSpawnRecurringTask(Task currentTask, Task? nextTask) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.tasks.put(currentTask);
        if (nextTask != null) {
          await _isar.tasks.put(nextTask);
        }
      });
      return true;
    } on IsarError catch (e) {
      talker.error('🔴 Isar Database Error (Complete & Spawn): $e');
      return false;
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Complete & Spawn)');
      return false;
    }
  }

  // Delete with error handling
  Future<void> deleteTask(Id id) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.tasks.delete(id);
      });
    } on IsarError catch (e) {
      talker.error('🔴 Isar Database Error (Delete): $e');
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Delete Task)');
    }
  }

  /// ✅ Phase 6: Delete task and stop recurrence series (Zombie Fix)
  Future<void> deleteTaskAndStopRecurrence(Task task) async {
    try {
      await _isar.writeTxn(() async {
        // 1. If it's a recurring task, stop the recurrence for all past/future instances
        if (task.recurrence != TaskRecurrence.none) {
          final siblings = await _isar.tasks
              .filter()
              .titleEqualTo(task.title)
              .findAll();
              
          for (var sibling in siblings) {
            sibling.recurrence = TaskRecurrence.none;
            await _isar.tasks.put(sibling);
          }
        }
        
        // 2. Delete the actual instance the user selected
        await _isar.tasks.delete(task.id);
        
        // ✅ Architecture Fix: Deletion Guard
        // Save to GetStorage that this task title was explicitly deleted today
        // to prevent the Recurrence Engine from re-creating it 1 second later.
        if (task.recurrence != TaskRecurrence.none) {
          final storage = GetStorage();
          final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final key = 'deleted_tasks_$todayStr';
          final List deletedTitles = storage.read(key) ?? [];
          if (!deletedTitles.contains(task.title)) {
            deletedTitles.add(task.title);
            storage.write(key, deletedTitles);
          }
        }
      });
    } on IsarError catch (e) {
      talker.error('🔴 Isar Database Error (Delete & Stop Recurrence): $e');
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Delete & Stop Recurrence)');
    }
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
          final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
          final effectiveDay = template.scheduledAt.day.clamp(1, lastDayOfMonth);
          isDue = effectiveDay == now.day;
        }

        if (!isDue) continue;

        // ✅ Architecture Fix: Check Deletion Guard
        final todayStr = DateFormat('yyyy-MM-dd').format(now);
        final List deletedTitles = GetStorage().read('deleted_tasks_$todayStr') ?? [];
        if (deletedTitles.contains(template.title)) {
          // talker.info('🛡️ Recurrence Guard: Skipping re-creation of deleted task "${template.title}"');
          continue;
        }

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
