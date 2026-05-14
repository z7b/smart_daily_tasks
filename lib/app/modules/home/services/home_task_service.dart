import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/task_model.dart';
import '../../../data/providers/task_repository.dart';
import '../../../core/helpers/number_extension.dart';
import '../../../core/services/time_service.dart';
import '../../../core/extensions/date_time_extensions.dart';

/// Describes the nature of the "featured" task on the home card.
enum NextTaskKind {
  /// A task scheduled in the future (standard upcoming task)
  upcoming,
  /// A task whose time window is right now (active)
  activeNow,
  /// A task whose time has passed but is still incomplete (overdue today)
  overdueToday,
  /// A task from a past day that was never completed (overdue past)
  overduePast,
}

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
  final DateTime? nextScheduledAt;
  final NextTaskKind nextTaskKind;

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
    this.nextScheduledAt,
    this.nextTaskKind = NextTaskKind.upcoming,
  });
}

class HomeTaskService extends GetxService {
  final TaskRepository _repository;
  final TimeService _timeService = Get.find<TimeService>();

  HomeTaskService(this._repository);

  Stream<TaskDailyStats> watchDailyStats(DateTime viewDate) async* {
    final startOfDay = DateTime(viewDate.year, viewDate.month, viewDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // ✅ 1. Yield Initial State Immediately (0ms delay UI update)
    yield await _computeStats(startOfDay, endOfDay, viewDate);

    // ✅ 2. Yield on every database change
    await for (final _ in _repository.watchAllTasks()) {
      yield await _computeStats(startOfDay, endOfDay, viewDate);
    }
  }

  Future<TaskDailyStats> _computeStats(DateTime startOfDay, DateTime endOfDay, DateTime viewDate) async {
    final dayTasks = await _repository.getTasksForDateRange(startOfDay, endOfDay);
    final now = _timeService.now;
    
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
    DateTime? nextTaskDate;
    NextTaskKind nextTaskKind = NextTaskKind.upcoming;

    final locale = Get.locale?.languageCode ?? 'en';
    final isViewingToday = viewDate.isSameDay(now);

    if (isViewingToday || viewDate.isAfter(now)) {
      // ────────────────────────────────────────────────
      // PRIORITY 1: Upcoming tasks (scheduled in the future)
      // ────────────────────────────────────────────────
      Task? featuredTask;

      final upcomingToday = dayTasks
          .where((t) => t.status == TaskStatus.active && t.scheduledAt.isAfter(now))
          .toList();
      
      if (upcomingToday.isNotEmpty) {
        upcomingToday.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        featuredTask = upcomingToday.first;
        nextTaskKind = NextTaskKind.upcoming;
      }

      // ────────────────────────────────────────────────
      // PRIORITY 2: Currently active task (time is now within window)
      // ────────────────────────────────────────────────
      if (featuredTask == null) {
        final activeTasks = dayTasks.where((t) {
          if (t.status != TaskStatus.active) return false;
          // Task is active NOW: scheduledAt <= now < scheduledEnd
          if (t.scheduledEnd != null) {
            return !now.isBefore(t.scheduledAt) && now.isBefore(t.scheduledEnd!);
          }
          // No end time: consider active for 30 min after scheduledAt
          return !now.isBefore(t.scheduledAt) && now.difference(t.scheduledAt).inMinutes <= 30;
        }).toList();

        if (activeTasks.isNotEmpty) {
          // Pick the one ending soonest
          activeTasks.sort((a, b) {
            final aEnd = a.scheduledEnd ?? a.scheduledAt.add(const Duration(minutes: 30));
            final bEnd = b.scheduledEnd ?? b.scheduledAt.add(const Duration(minutes: 30));
            return aEnd.compareTo(bEnd);
          });
          featuredTask = activeTasks.first;
          nextTaskKind = NextTaskKind.activeNow;
        }
      }

      // ────────────────────────────────────────────────
      // PRIORITY 3: Overdue today (time passed, not completed)
      // ────────────────────────────────────────────────
      if (featuredTask == null) {
        final overdueTasks = dayTasks.where((t) {
          if (t.status != TaskStatus.active) return false;
          // Past its start time (and past its end time if it has one)
          if (t.scheduledEnd != null) {
            return now.isAfter(t.scheduledEnd!);
          }
          return now.isAfter(t.scheduledAt) && now.difference(t.scheduledAt).inMinutes > 30;
        }).toList();

        if (overdueTasks.isNotEmpty) {
          // Show the most recently overdue (highest priority first, then most recent)
          overdueTasks.sort((a, b) {
            final priorityCompare = b.priority.index.compareTo(a.priority.index);
            if (priorityCompare != 0) return priorityCompare;
            return b.scheduledAt.compareTo(a.scheduledAt);
          });
          featuredTask = overdueTasks.first;
          nextTaskKind = NextTaskKind.overdueToday;
        }
      }

      // ────────────────────────────────────────────────
      // PRIORITY 4: Next global upcoming task (future days)
      // ────────────────────────────────────────────────
      if (featuredTask == null) {
        final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
        featuredTask = await _repository.getNextActiveTask(endOfToday);
        if (featuredTask != null) {
          nextTaskKind = NextTaskKind.upcoming;
        }
      }
      
      // ── Populate fields from the featured task ──
      if (featuredTask != null) {
        nextTaskDate = featuredTask.scheduledAt;
        nextTitle = featuredTask.title;
        nextTime = DateFormat.jm(locale).format(featuredTask.scheduledAt).f;
        nextEndTime = featuredTask.scheduledEnd != null ? DateFormat.jm(locale).format(featuredTask.scheduledEnd!).f : '';
        nextPriority = featuredTask.priority;
        nextFullDate = '${DateFormat('dd MMMM yyyy', locale).format(featuredTask.scheduledAt).f} • $nextTime';
        
        nextTimeLeft = _computeTimeLeft(featuredTask, now, nextTaskKind, locale);
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
      nextScheduledAt: nextTaskDate,
      nextTaskKind: nextTaskKind,
    );
  }

  /// Computes the smart time-left label based on the task kind.
  String _computeTimeLeft(Task task, DateTime now, NextTaskKind kind, String locale) {
    switch (kind) {
      case NextTaskKind.activeNow:
        // Show time remaining until end using existing translation keys
        if (task.scheduledEnd != null) {
          final diff = task.scheduledEnd!.difference(now);
          if (diff.inHours > 0) {
            return 'ends_in_x_hours'.trParams({'hours': diff.inHours.toString().f});
          }
          return 'ends_in_x_minutes'.trParams({'minutes': diff.inMinutes.toString().f});
        }
        return 'active_now'.tr;

      case NextTaskKind.overdueToday:
        final deadline = task.scheduledEnd ?? task.scheduledAt;
        final diff = now.difference(deadline);
        if (diff.inHours > 0) {
          return '${'overdue'.tr} • ${diff.inHours.f}${'hours_abbr'.tr}';
        }
        return '${'overdue'.tr} • ${diff.inMinutes.f}${'minutes_abbr'.tr}';

      case NextTaskKind.overduePast:
        final diff = now.difference(task.scheduledAt);
        return 'overdue_by_x_days'.trParams({'days': diff.inDays.toString()});

      case NextTaskKind.upcoming:
        final diff = task.scheduledAt.difference(now);
        if (diff.isNegative) {
          return 'overdue'.tr;
        }
        if (diff.inDays >= 1) {
          if (diff.inDays == 1) {
            return 'tomorrow'.tr;
          } else if (diff.inDays < 7) {
            return 'in_x_days'.trParams({'days': diff.inDays.toString()});
          } else {
            return DateFormat('d MMMM', locale).format(task.scheduledAt).f;
          }
        }
        final hours = diff.inHours;
        final minutes = (diff.inMinutes % 60).abs();
        if (hours > 0) {
          return '${hours.f}${'hours_abbr'.tr} ${minutes.f}${'minutes_abbr'.tr}';
        }
        return '${minutes.f}${'minutes_abbr'.tr}';
    }
  }
}
