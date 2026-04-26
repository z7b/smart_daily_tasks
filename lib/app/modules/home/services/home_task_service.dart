import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/task_model.dart';
import '../../../data/providers/task_repository.dart';
import '../../../core/helpers/number_extension.dart';

class TaskDailyStats {
  final int total;
  final int pending;
  final int completed;
  final int cancelled;
  final String nextTitle;
  final String nextTime;
  final String nextEndTime;
  final String nextTimeLeft;
  final String nextFullDate;
  final TaskPriority nextPriority;

  TaskDailyStats({
    required this.total,
    required this.pending,
    required this.completed,
    required this.cancelled,
    required this.nextTitle,
    required this.nextTime,
    required this.nextEndTime,
    required this.nextTimeLeft,
    required this.nextFullDate,
    required this.nextPriority,
  });
}

class HomeTaskService extends GetxService {
  final TaskRepository _repository;
  HomeTaskService(this._repository);

  Stream<TaskDailyStats> watchDailyStats(DateTime viewDate) async* {
    // 1. Emit Initial Value
    yield await getDailyStats(viewDate);

    // 2. Listen to GLOBAL task changes
    // This ensures that if the "Next Task" (which might be tomorrow) is deleted,
    // the Home Page reacts immediately.
    yield* _repository.watchAllTasks().asyncMap((_) => getDailyStats(viewDate));
  }

  Future<TaskDailyStats> getDailyStats(DateTime viewDate) async {
    // Keep for one-time fetches if needed, but watchDailyStats is preferred for dashboard
    final startOfDay = DateTime(viewDate.year, viewDate.month, viewDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final now = DateTime.now();

    final dayTasks = await _repository.getTasksForDateRange(startOfDay, endOfDay);
    
    final int total = dayTasks.length;
    final int completed = dayTasks.where((t) => t.status == TaskStatus.completed).length;
    final int cancelled = dayTasks.where((t) => t.status == TaskStatus.cancelled).length;
    final int pending = dayTasks.where((t) => t.status == TaskStatus.active).length;

    String nextTitle = '';
    String nextTime = '';
    String nextEndTime = '';
    String nextTimeLeft = '';
    String nextFullDate = '';
    TaskPriority nextPriority = TaskPriority.medium;

    if (viewDate.isSameDay(now) || viewDate.isAfter(now)) {
      final locale = Get.locale?.languageCode ?? 'en';
      Task? predictiveTask;

      // 1. Next actionable task for TODAY
      final upcomingToday = dayTasks
          .where((t) => t.status == TaskStatus.active && t.scheduledAt.isAfter(now))
          .toList();
      
      if (upcomingToday.isNotEmpty) {
        upcomingToday.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        predictiveTask = upcomingToday.first;
      }

      // 2. If no tasks left today, find the absolute next global task
      if (predictiveTask == null) {
        final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
        predictiveTask = await _repository.getNextActiveTask(endOfToday);
      }
      
      if (predictiveTask != null) {
        nextTitle = predictiveTask.title;
        nextTime = DateFormat.jm(locale).format(predictiveTask.scheduledAt).f;
        nextEndTime = predictiveTask.scheduledEnd != null ? DateFormat.jm(locale).format(predictiveTask.scheduledEnd!).f : '';
        nextPriority = predictiveTask.priority;
        nextFullDate = '${DateFormat('dd MMMM yyyy', locale).format(predictiveTask.scheduledAt).f} • $nextTime';
        
        final diff = predictiveTask.scheduledAt.difference(now);
        if (diff.isNegative) {
          nextTimeLeft = 'overdue'.tr;
        } else {
          if (diff.inDays >= 1) {
            if (diff.inDays == 1) {
              nextTimeLeft = 'tomorrow'.tr;
            } else if (diff.inDays < 7) {
              nextTimeLeft = 'in_x_days'.trParams({'days': diff.inDays.toString()});
            } else {
              nextTimeLeft = DateFormat('d MMMM', locale).format(predictiveTask.scheduledAt).f;
            }
          } else {
            final hours = diff.inHours;
            final minutes = (diff.inMinutes % 60).abs();
            if (hours > 0) {
              nextTimeLeft = '${hours.f}${'hours_abbr'.tr} ${minutes.f}${'minutes_abbr'.tr}';
            } else {
              nextTimeLeft = '${minutes.f}${'minutes_abbr'.tr}';
            }
          }
        }
      }
    }

    return TaskDailyStats(
      total: total,
      pending: pending,
      completed: completed,
      cancelled: cancelled,
      nextTitle: nextTitle,
      nextTime: nextTime,
      nextEndTime: nextEndTime,
      nextTimeLeft: nextTimeLeft,
      nextFullDate: nextFullDate,
      nextPriority: nextPriority,
    );
  }
}

extension DateTimeSameDay on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
