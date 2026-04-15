import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smart_daily_tasks/app/data/models/task_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    final isCancelled = task.status == TaskStatus.cancelled;
    final isCompleted = task.status == TaskStatus.completed;
    final color = isCancelled ? theme.dividerColor : _getTaskColor(task.color ?? 0);

    return Dismissible(
      key: Key(task.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => onDelete(),
      background: Container(
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(CupertinoIcons.trash, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () => _showOptions(context),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor.withValues(alpha: 0.7) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: (isCompleted || isCancelled) ? 0.05 : 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.05 : (isCancelled ? 0 : 0.08)),
                blurRadius: 15,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Top Progress Bar for active tasks
                if (!isCompleted && !isCancelled && task.progress > 0 && task.progress < 1)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 3,
                    child: LinearProgressIndicator(
                      value: task.progress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(color.withValues(alpha: 0.5)),
                    ),
                  ),

                Row(
                  children: [
                    // Left Priority Accent
                    Container(
                      width: 5,
                      height: 100,
                      decoration: BoxDecoration(
                        color: (isCompleted || isCancelled) ? theme.dividerColor : color,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            (isCompleted || isCancelled) ? theme.dividerColor : color,
                            (isCompleted || isCancelled) ? theme.dividerColor.withValues(alpha: 0.5) : color.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                    
                    // Interaction Hub
                    GestureDetector(
                      onTap: isCancelled ? null : () {
                        HapticFeedback.lightImpact();
                        onCompleted(!isCompleted);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.fastOutSlowIn,
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (isCompleted || isCancelled) ? theme.dividerColor : color,
                              width: 2,
                            ),
                            color: isCompleted ? color.withValues(alpha: 0.2) : (isCancelled ? theme.dividerColor.withValues(alpha: 0.1) : Colors.transparent),
                          ),
                          child: isCompleted
                              ? Icon(CupertinoIcons.checkmark_alt, size: 16, color: color)
                              : (isCancelled ? const Icon(CupertinoIcons.xmark, size: 14, color: Colors.grey) : null),
                        ),
                      ),
                    ),

                    // Task Core Body
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: (isCompleted || isCancelled)
                                          ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)
                                          : theme.textTheme.titleLarge?.color,
                                      decoration: (isCompleted || isCancelled) ? TextDecoration.lineThrough : null,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                if (task.recurrence == TaskRecurrence.daily)
                                  Icon(CupertinoIcons.repeat, size: 14, color: theme.dividerColor).animate().rotate(duration: const Duration(seconds: 1)),
                                if (task.isNotificationEnabled)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Icon(CupertinoIcons.bell_fill, size: 12, color: color.withValues(alpha: 0.5)),
                                  ),
                                const SizedBox(width: 8),
                                _buildPriorityBadge(task.priority),
                              ],
                            ),
                            const SizedBox(height: 6),
                            
                            // Context Strip
                            Row(
                              children: [
                                Icon(CupertinoIcons.clock_fill, size: 13, color: color.withValues(alpha: 0.6)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "${DateFormat('dd/MM/yyyy').format(task.scheduledAt)} • ${DateFormat.jm().format(task.scheduledAt)}${task.scheduledEnd != null ? ' - ${DateFormat.jm().format(task.scheduledEnd!)}' : ''}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // The "Intelligence" Part: Time Left
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    task.timeLeft,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: color.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (task.note?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 8),
                              Text(
                                task.note!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority) {
    Color color;
    String label;
    
    switch (priority) {
      case TaskPriority.high:
        color = const Color(0xFFFF3B30); // iOS Red
        label = 'High!!';
        break;
      case TaskPriority.medium:
        color = const Color(0xFFFF9500); // iOS Orange
        label = 'Medium';
        break;
      case TaskPriority.low:
        color = const Color(0xFF34C759); // iOS Green
        label = 'Low';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getTaskColor(int no) {
    switch (no) {
      case 0:
        return const Color(0xFF007AFF); // iOS Blue
      case 1:
        return const Color(0xFFFF2D55); // iOS Pink
      case 2:
        return const Color(0xFFFF9500); // iOS Orange
      default:
        return const Color(0xFF007AFF);
    }
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
