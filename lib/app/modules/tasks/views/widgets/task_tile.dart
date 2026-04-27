import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/task_time_service.dart';
import '../../../../data/models/task_model.dart';
import '../../../../core/helpers/number_extension.dart';
import '../../controllers/task_list_controller.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final Function(bool?) onCompleted;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  const TaskTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onCompleted,
    required this.onDelete,
    required this.onEdit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final timeService = Get.find<TaskTimeService>();
    final statusUI = timeService.getStatus(task);
    final statusColor = timeService.getStatusColor(statusUI);
    final isCompleted = task.status == TaskStatus.completed;
    final isCancelled = task.status == TaskStatus.cancelled;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withValues(alpha: isCompleted ? 0.05 : 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: isDark ? 0.02 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          onLongPress: () => _showOptions(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Icon + Status Badge + Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
                child: Row(
                  children: [
                    _buildStatusIcon(statusUI, statusColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusBadge(statusUI, statusColor),
                          const SizedBox(height: 2),
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: (isCompleted || isCancelled)
                                  ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)
                                  : theme.textTheme.titleLarge?.color,
                              decoration: (isCompleted || isCancelled) ? TextDecoration.lineThrough : null,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildActionButtons(theme),
                  ],
                ),
              ),

              // Note Preview (if exists)
              if (task.note?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    task.note!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                  ),
                ),

              // Bottom Info Strip (Glassmorphism style)
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.time, size: 14, color: statusColor.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatTimeWithDate(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    Obx(() {
                      // Reactive countdown from controller
                      Get.find<TaskListController>().currentTime.value;
                      return Text(
                        timeService.getTimeLabel(task),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildStatusIcon(TaskStatusUI status, Color color) {
    IconData icon;
    switch (status) {
      case TaskStatusUI.active:
        icon = CupertinoIcons.play_circle_fill;
        break;
      case TaskStatusUI.upcoming:
        icon = CupertinoIcons.clock_fill;
        break;
      case TaskStatusUI.overdue:
        icon = CupertinoIcons.exclamationmark_circle_fill;
        break;
      case TaskStatusUI.completed:
        icon = CupertinoIcons.check_mark_circled_solid;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 22, color: color),
    );
  }

  Widget _buildStatusBadge(TaskStatusUI status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.name.tr.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    final isCompleted = task.status == TaskStatus.completed;
    final isCancelled = task.status == TaskStatus.cancelled;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isCompleted && !isCancelled)
          _buildCircleButton(
            icon: CupertinoIcons.checkmark_alt,
            color: AppTheme.primary,
            onPressed: () {
              HapticFeedback.mediumImpact();
              onCompleted(true);
            },
          ),
        const SizedBox(width: 8),
        _buildCircleButton(
          icon: CupertinoIcons.ellipsis,
          color: theme.dividerColor,
          onPressed: () => _showOptions(Get.context!),
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  String _formatTimeWithDate() {
    final locale = Get.locale?.languageCode ?? 'en';
    final now = DateTime.now();
    final isToday = task.scheduledAt.year == now.year &&
        task.scheduledAt.month == now.month &&
        task.scheduledAt.day == now.day;

    final timePart = _formatTimeRange();
    
    if (isToday) return timePart;

    // Show date if not today
    final datePart = DateFormat.MMMd(locale).format(task.scheduledAt).f;
    return '$datePart • $timePart';
  }

  String _formatTimeRange() {
    final locale = Get.locale?.languageCode ?? 'en';
    final start = DateFormat.jm(locale).format(task.scheduledAt).f;
    if (task.scheduledEnd == null) return start;
    final end = DateFormat.jm(locale).format(task.scheduledEnd!).f;
    return '$start - $end';
  }

  void _showOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          if (task.status == TaskStatus.active)
            CupertinoActionSheetAction(
              onPressed: () {
                Get.back();
                onCancel();
              },
              child: Text('cancel'.tr, style: const TextStyle(color: CupertinoColors.systemOrange)),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              onEdit();
            },
            child: Text('edit'.tr),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Get.back();
              onDelete();
            },
            child: Text('delete'.tr),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Get.back(),
          child: Text('cancel'.tr),
        ),
      ),
    );
  }
}
