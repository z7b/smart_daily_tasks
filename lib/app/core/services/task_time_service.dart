import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/task_model.dart';
import '../../core/helpers/number_extension.dart';
import '../../core/helpers/time_format_helper.dart';

enum TaskStatusUI {
  active,
  upcoming,
  overdue,
  completed,
}

class TaskTimeService extends GetxService {
  /// Determines the UI status of a task based on current time and completion status
  TaskStatusUI getStatus(Task task) {
    if (task.status == TaskStatus.completed) return TaskStatusUI.completed;
    
    final now = DateTime.now();
    
    // Active: now is between scheduledAt and scheduledEnd (if exists)
    if (now.isAfter(task.scheduledAt)) {
      if (task.scheduledEnd != null) {
        if (now.isBefore(task.scheduledEnd!)) {
          return TaskStatusUI.active;
        } else {
          return TaskStatusUI.overdue;
        }
      } else {
        // Principal Architect decision: If no end time, it's overdue after scheduledAt + 30m
        if (now.difference(task.scheduledAt).inMinutes > 30) {
          return TaskStatusUI.overdue;
        }
        return TaskStatusUI.active;
      }
    }
    
    return TaskStatusUI.upcoming;
  }

  /// Returns a smart localized label for the time remaining or passed
  String getTimeLabel(Task task) {
    final status = getStatus(task);
    final now = DateTime.now();

    if (status == TaskStatusUI.completed) {
      if (task.completedAt != null) {
        return 'done_at'.trParams({'time': TimeFormatHelper.formatTime(task.completedAt!)});
      }
      return 'task_completed'.tr;
    }

    if (status == TaskStatusUI.overdue) {
      final deadline = task.scheduledEnd ?? task.scheduledAt;
      final diff = now.difference(deadline);
      if (diff.inDays > 0) {
        return 'overdue_by_x_days'.trParams({'days': diff.inDays.toString().f});
      }
      return 'overdue'.tr;
    }

    if (status == TaskStatusUI.active) {
      if (task.scheduledEnd != null) {
        final diff = task.scheduledEnd!.difference(now);
        if (diff.inHours > 0) {
          return 'ends_in_x_hours'.trParams({'hours': diff.inHours.toString().f});
        }
        return 'ends_in_x_minutes'.trParams({'minutes': diff.inMinutes.toString().f});
      }
      return 'active_now'.tr;
    }

    // Upcoming
    final diff = task.scheduledAt.difference(now);
    if (diff.inDays > 0) {
      if (diff.inDays == 1) return 'tomorrow'.tr;
      return 'in_x_days'.trParams({'days': diff.inDays.toString().f});
    }
    if (diff.inHours > 0) {
      return 'starts_in_x_hours'.trParams({'hours': diff.inHours.toString().f});
    }
    return 'starts_in_x_minutes'.trParams({'minutes': diff.inMinutes.toString().f});
  }

  /// Returns the color associated with a task's UI status
  Color getStatusColor(TaskStatusUI status) {
    switch (status) {
      case TaskStatusUI.active:
        return const Color(0xFF3B82F6); // Blue 500
      case TaskStatusUI.upcoming:
        return const Color(0xFF8B5CF6); // Violet 500 — planned/future
      case TaskStatusUI.overdue:
        return const Color(0xFFEF4444); // Red 500
      case TaskStatusUI.completed:
        return const Color(0xFF10B981); // Green 500
    }
  }
}
