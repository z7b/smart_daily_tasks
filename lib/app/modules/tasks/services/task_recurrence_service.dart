import 'package:isar/isar.dart';
import '../../../data/models/task_model.dart';

class TaskRecurrenceService {
  /// ✅ Phase 2: Generates the next instance of a recurring task
  static Task? generateNextInstance(Task task) {
    if (task.recurrence == TaskRecurrence.none) return null;

    final now = DateTime.now();
    DateTime nextScheduledAt = _calculateNextOccurrence(task.scheduledAt, task.recurrence);
    
    // Fallback logic to prevent past spawning
    if (!nextScheduledAt.isAfter(now)) {
       nextScheduledAt = _calculateNextOccurrence(now, task.recurrence);
    }
    
    // Copy the old task values into a new uncompleted task
    return task.copyWith(
      id: Isar.autoIncrement,
      scheduledAt: nextScheduledAt,
      scheduledEnd: task.scheduledEnd != null 
          ? nextScheduledAt.add(task.scheduledEnd!.difference(task.scheduledAt))
          : null,
      status: TaskStatus.active,
      completedAt: null,
      createdAt: now,
    );
  }

  static DateTime _calculateNextOccurrence(DateTime current, TaskRecurrence recurrence) {
    switch (recurrence) {
      case TaskRecurrence.daily:
        return current.add(const Duration(days: 1));
      case TaskRecurrence.weekly:
        return current.add(const Duration(days: 7));
      case TaskRecurrence.monthly:
        return _addMonths(current, 1);
      default:
        return current;
    }
  }

  /// Calculates precise month boundary rollovers
  static DateTime _addMonths(DateTime date, int months) {
    int newYear = date.year;
    int newMonth = date.month + months;

    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }

    int newDay = date.day;
    final lastDayOfNewMonth = DateTime(newYear, newMonth + 1, 0).day;
    
    if (newDay > lastDayOfNewMonth) {
      newDay = lastDayOfNewMonth;
    }

    return DateTime(
      newYear,
      newMonth,
      newDay,
      date.hour,
      date.minute,
      date.second,
    );
  }
}
