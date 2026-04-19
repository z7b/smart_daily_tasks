import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/helpers/bottom_sheet_helper.dart';
import '../../../data/models/task_model.dart';
import '../controllers/task_controller.dart';
import 'widgets/task_tile.dart';
import '../../../core/helpers/number_extension.dart';

class TasksView extends GetView<TaskController> {
  const TasksView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // iOS-Style Large App Bar
            SliverAppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              elevation: 0,
              centerTitle: false,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
                onPressed: () => Get.back(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  'my_daily_tasks'.tr,
                  style: TextStyle(
                    color: theme.textTheme.titleLarge?.color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    CupertinoIcons.add_circled_solid,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                  onPressed: () => Get.toNamed('/add-task'),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: CupertinoSearchTextField(
                  placeholder: 'search_tasks'.tr,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  onChanged: (val) => controller.searchQuery.value = val,
                ),
              ),
            ),

            // Smart Summary Strip
            SliverToBoxAdapter(
              child: Obx(() {
                final total = controller.filteredTasks.length;
                final completed = controller.filteredTasks
                    .where((t) => t.status == TaskStatus.completed)
                    .length;
                final active = controller.filteredTasks
                    .where((t) => t.status == TaskStatus.active)
                    .length;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Date
                      Expanded(
                        child: Text(
                          DateFormat.yMMMMEEEEd(
                            Get.locale?.languageCode,
                          ).format(DateTime.now()).f,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Smart Counters
                      if (total > 0) ...[
                        _buildMiniChip(
                          icon: CupertinoIcons.flame_fill,
                          label: active.f,
                          color: const Color(0xFFFF9500),
                          theme: theme,
                        ),
                        const SizedBox(width: 6),
                        _buildMiniChip(
                          icon: CupertinoIcons.checkmark_alt,
                          label: '${completed.f}/${total.f}',
                          color: const Color(0xFF34C759),
                          theme: theme,
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ),

            // Task List
            Obx(() {
              final tasks = controller.filteredTasks;
              if (tasks.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary.withAlpha(15),
                          ),
                          child: Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            size: 56,
                            color: AppTheme.primary.withAlpha(80),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'no_tasks_today'.tr,
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'add_task'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withAlpha(120),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: const Duration(milliseconds: 400)).slideY(begin: 0.05),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final task = tasks[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    child: TaskTile(
                      task: task,
                      onTap: () => _showTaskDetails(context, task),
                      onEdit: () {
                        controller.loadTaskIntoForm(task);
                        Get.toNamed('/add-task', arguments: task);
                      },
                      onCompleted: (val) =>
                          controller.markTaskCompleted(task),
                      onCancel: () => controller.cancelTask(task),
                      onDelete: () => controller.deleteTask(task),
                    )
                        .animate(key: ValueKey('anim_${task.id}'))
                        .fadeIn(duration: const Duration(milliseconds: 300))
                        .slideX(begin: 0.06),
                  );
                }, childCount: tasks.length),
              );
            }),

            // Bottom Padding
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  /// Mini chip for the smart summary strip
  Widget _buildMiniChip({
    required IconData icon,
    required String label,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskDetails(BuildContext context, Task task) {
    BottomSheetHelper.showSafeBottomSheet(
      builder: (context, setState) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final isCompleted = task.status == TaskStatus.completed;
        final isCancelled = task.status == TaskStatus.cancelled;

        // Priority color mapping
        Color priorityColor;
        String priorityLabel;
        switch (task.priority) {
          case TaskPriority.high:
            priorityColor = const Color(0xFFFF3B30);
            priorityLabel = 'High';
            break;
          case TaskPriority.medium:
            priorityColor = const Color(0xFFFF9500);
            priorityLabel = 'Medium';
            break;
          case TaskPriority.low:
            priorityColor = const Color(0xFF34C759);
            priorityLabel = 'Low';
            break;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Status + Priority Row
              Row(
                children: [
                  // Status pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFF34C759).withAlpha(20)
                          : isCancelled
                              ? Colors.grey.withAlpha(20)
                              : AppTheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isCompleted
                          ? 'task_completed'.tr
                          : isCancelled
                              ? 'cancelled'.tr
                              : 'active'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCompleted
                            ? const Color(0xFF34C759)
                            : isCancelled
                                ? Colors.grey
                                : AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Priority pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: priorityColor.withAlpha(40)),
                    ),
                    child: Text(
                      priorityLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Recurrence indicator
                  if (task.recurrence != TaskRecurrence.none)
                    Icon(CupertinoIcons.repeat,
                        size: 18, color: AppTheme.primary),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                task.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                  decoration: (isCompleted || isCancelled)
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Time Info Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(8)
                      : AppTheme.primary.withAlpha(8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withAlpha(10)
                        : AppTheme.primary.withAlpha(15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.clock_fill,
                      size: 18,
                      color: AppTheme.primary.withAlpha(180),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.scheduledEnd != null
                                ? '${DateFormat.jm().format(task.scheduledAt).f} → ${DateFormat.jm().format(task.scheduledEnd!).f}'
                                : DateFormat.jm().format(task.scheduledAt).f,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat.yMMMMd(Get.locale?.languageCode)
                                .format(task.scheduledAt).f,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Time left badge
                    if (!isCompleted && !isCancelled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          task.timeLeft,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Note Section
              if (task.note != null && task.note!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.dividerColor.withAlpha(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(CupertinoIcons.doc_text,
                              size: 14,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withAlpha(120)),
                          const SizedBox(width: 6),
                          Text(
                            'notes'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withAlpha(120),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.note!,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Tags
              if (task.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: task.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 28),

              // Action Buttons
              Row(
                children: [
                  // Complete Button
                  Expanded(
                    child: _buildDetailButton(
                      label: 'task_completed'.tr,
                      icon: CupertinoIcons.checkmark_alt,
                      color: isCompleted
                          ? Colors.grey
                          : const Color(0xFF34C759),
                      onPressed: () {
                        controller.markTaskCompleted(task);
                        if (Get.isBottomSheetOpen ?? false) Get.back();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Edit Button
                  Expanded(
                    child: _buildDetailButton(
                      label: 'edit'.tr,
                      icon: CupertinoIcons.pencil,
                      color: AppTheme.primary,
                      onPressed: () {
                        if (Get.isBottomSheetOpen ?? false) Get.back();
                        controller.loadTaskIntoForm(task);
                        Get.toNamed('/add-task', arguments: task);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Delete Button
                  Expanded(
                    child: _buildDetailButton(
                      label: 'delete'.tr,
                      icon: CupertinoIcons.trash,
                      color: const Color(0xFFFF3B30),
                      onPressed: () {
                        controller.deleteTask(task);
                        Get.back();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  /// Premium action button
  Widget _buildDetailButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withAlpha(20),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
