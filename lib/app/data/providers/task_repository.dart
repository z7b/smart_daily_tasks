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
}
