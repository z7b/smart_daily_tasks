import '../../core/helpers/log_helper.dart';
import 'package:isar/isar.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../../core/helpers/result.dart';
import '../../core/extensions/date_time_extensions.dart';

class TaskRepository {
  final Isar _isar;
  final _storage = GetStorage();

  TaskRepository(this._isar) {
    talker.info('📋 TaskRepository initialized');
  }

  /// Create a new task with success result
  Future<Result<int>> addTask(Task task) async {
    try {
      final id = await _isar.writeTxn(() async {
        return await _isar.tasks.put(task);
      });
      return Result.success(id);
    } on IsarError catch (e) {
      talker.error('🔴 Isar Database Error (Add): $e');
      return Result.failure(e.toString());
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Add Task)');
      return Result.failure(e.toString());
    }
  }

  // ✅ Used for Tasks Module Timeline
  Stream<List<Task>> watchTimeline(DateTime viewDate) {
    final startOfDay = DateTime(viewDate.year, viewDate.month, viewDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _isar.tasks
        .filter()
        .statusEqualTo(TaskStatus.active) // Fetch all uncompleted (Overdue, Now, Future)
        .or()
        .group((q) => q
            .scheduledAtBetween(startOfDay, endOfDay, includeLower: true, includeUpper: false)
            .and()
            .group((q2) => q2
                .statusEqualTo(TaskStatus.completed)
                .or()
                .statusEqualTo(TaskStatus.cancelled)))
        .sortByScheduledAt()
        .watch(fireImmediately: true);
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

  /// ✅ Reactive stream of all tasks for calendar markers
  Stream<List<Task>> watchAllTasksData() {
    return _isar.tasks.where().watch(fireImmediately: true);
  }

  /// ✅ Reactive stream of recurring templates for "Virtual" calendar display
  Stream<List<Task>> watchRecurringTemplates() {
    return _isar.tasks
        .filter()
        .not()
        .recurrenceEqualTo(TaskRecurrence.none)
        .watch(fireImmediately: true);
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
  Future<Result<void>> updateTask(Task task) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.tasks.put(task);
      });
      return Result.successVoid();
    } on IsarError catch (e) {
      talker.error('🔴 Isar Database Error (Update): $e');
      return Result.failure(e.toString());
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Update Task)');
      return Result.failure(e.toString());
    }
  }

  /// ✅ Phase 2: Atomicity Failure fix - Completes task and spawns recurrence in one transaction
  Future<Result<void>> completeAndSpawnRecurringTask(Task currentTask, Task? nextTask) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.tasks.put(currentTask);
        if (nextTask != null) {
          await _isar.tasks.put(nextTask);
        }
      });
      return Result.successVoid();
    } on IsarError catch (e) {
      talker.error('🔴 Isar Database Error (Complete & Spawn): $e');
      return Result.failure(e.toString());
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Complete & Spawn)');
      return Result.failure(e.toString());
    }
  }

  // Delete with error handling
  Future<bool> deleteTask(Id id) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.tasks.delete(id);
      });
      return true;
    } on IsarError catch (e) {
      talker.error('🔴 Isar Database Error (Delete): $e');
      return false;
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Delete Task)');
      return false;
    }
  }

  /// ✅ Phase 6: Delete task and stop recurrence series (Zombie Fix)
  /// Sprint 1 Fix: Now uses seriesId instead of title
  Future<Result<void>> deleteTaskAndStopRecurrence(Task task) async {
    try {
      await _isar.writeTxn(() async {
        // 1. If it's a recurring task, stop the recurrence for all past/future instances in this series
        if (task.seriesId != null) {
          final allTasks = await _isar.tasks.where().findAll();
          final siblings = allTasks.where((t) => t.seriesId == task.seriesId).toList();
              
          for (var sibling in siblings) {
            sibling.recurrence = TaskRecurrence.none;
            await _isar.tasks.put(sibling);
          }
        }
        
        // 2. Delete the actual instance the user selected
        await _isar.tasks.delete(task.id);
        
        // ✅ Architecture Fix: Deletion Guard (Now uses seriesId)
        if (task.seriesId != null) {
          final storage = GetStorage();
          final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final key = 'deleted_series_$todayStr';
          final List deletedSeries = storage.read(key) ?? [];
          if (!deletedSeries.contains(task.seriesId)) {
            deletedSeries.add(task.seriesId);
            storage.write(key, deletedSeries);
          }
        }
      });
      return Result.successVoid();
    } on IsarError catch (e) {
      talker.error('🔴 Isar Database Error (Delete & Stop Recurrence): $e');
      return Result.failure(e.toString());
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Delete & Stop Recurrence)');
      return Result.failure(e.toString());
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
  /// Sprint 1 Fix: Now uses seriesId/templateId for robust deduplication
  Future<void> instantiateRecurringTasks() async {
    talker.info('♻️ Running Recurrence Engine...');
    
    try {
      talker.info('[TRACE: 0] Entering function');
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      talker.info('[TRACE: 1] Querying recurring templates');
      // Principal Architect: Fetch all tasks that are templates (have recurrence)
      final recurringTemplates = await _isar.tasks
          .filter()
          .not()
          .recurrenceEqualTo(TaskRecurrence.none)
          .findAll();
      
      talker.info('[TRACE: 2] Found ${recurringTemplates.length} templates');

      if (recurringTemplates.isEmpty) {
        talker.info('[TRACE: 2.1] No templates to process');
        return;
      }

      for (int i = 0; i < recurringTemplates.length; i++) {
        final template = recurringTemplates[i];
        talker.info('[TRACE: 3.$i] Processing template ID: ${template.id} Title: ${template.title}');
        
        // 1. Ensure seriesId exists (SSOT linkage)
        if (template.seriesId == null || template.seriesId!.isEmpty) {
          final timestamp = template.createdAt.millisecondsSinceEpoch;
          template.seriesId = 'series_${template.id}_$timestamp';
          talker.info('[TRACE: 4.$i] Generated seriesId: ${template.seriesId}');
          await _isar.writeTxn(() async {
            await _isar.tasks.put(template);
          });
        }

        final String sId = template.seriesId!;

        // 2. Check if should run today based on recurrence type
        final today = DateTime(now.year, now.month, now.day);
        final templateDateOnly = template.scheduledAt.normalized;

        // Boundary Check: Don't spawn instances BEFORE the start date
        if (today.isBefore(templateDateOnly)) {
          talker.info('[TRACE: 4.1.$i] Template scheduled for future (${template.scheduledAt}). Skipping.');
          continue;
        }

        bool shouldRunToday = false;
        talker.info('[TRACE: 5.$i] Checking recurrence: ${template.recurrence}');
        switch (template.recurrence) {
          case TaskRecurrence.daily:
            shouldRunToday = true;
            break;
          case TaskRecurrence.weekly:
            shouldRunToday = template.scheduledAt.weekday == today.weekday;
            break;
          case TaskRecurrence.monthly:
            final lastDayOfMonth = DateTime(today.year, today.month + 1, 0).day;
            final targetDay = template.scheduledAt.day;
            shouldRunToday = (today.day == targetDay) || (targetDay > lastDayOfMonth && today.day == lastDayOfMonth);
            break;
          case TaskRecurrence.none:
            shouldRunToday = false;
            break;
        }

        talker.info('[TRACE: 6.$i] Should run today: $shouldRunToday');
        if (!shouldRunToday) continue;

        // 3. Security Guard: Prevent "Zombie Tasks" (Don't recreate if deleted today)
        final deletedSeries = _storage.read<List>('deleted_series_$todayStr') ?? [];
        talker.info('[TRACE: 7.$i] Deleted series today count: ${deletedSeries.length}');
        if (deletedSeries.contains(sId)) {
          talker.info('[TRACE: 8.$i] Series $sId was deleted today. Skipping.');
          continue;
        }

        // 4. Instance Check: Don't duplicate if already exists
        talker.info('[TRACE: 9.$i] Querying for existing instances today');
        // Note: seriesIdEqualTo might show error if .g.dart is stale. Run build_runner!
        final instancesToday = await _isar.tasks
            .filter()
            .seriesIdEqualTo(sId)
            .scheduledAtBetween(today, today.add(const Duration(days: 1)), includeUpper: false)
            .findAll();
        
        talker.info('[TRACE: 10.$i] Found ${instancesToday.length} instances today');

        if (instancesToday.isEmpty) {
          talker.info('[TRACE: 11.$i] Creating new instance');
          final instance = template.copyWith(
            id: Isar.autoIncrement,
            status: TaskStatus.active,
            scheduledAt: DateTime(today.year, today.month, today.day, template.scheduledAt.hour, template.scheduledAt.minute),
            scheduledEnd: template.scheduledEnd != null 
                ? DateTime(today.year, today.month, today.day, template.scheduledEnd!.hour, template.scheduledEnd!.minute)
                : null,
            createdAt: now,
            // Recurrence on the instance is None to avoid it becoming a template itself
            recurrence: TaskRecurrence.none, 
            templateId: template.id,
          );

          await _isar.writeTxn(() async {
            await _isar.tasks.put(instance);
          });
          talker.info('[TRACE: 12.$i] Instance created: ${instance.title}');
        }
      }
      talker.info('[TRACE: 13] All templates processed');
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 CRITICAL: Recurrence Engine Failed');
      rethrow; 
    }
  }
}
