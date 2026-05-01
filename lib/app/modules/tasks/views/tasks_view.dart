import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/helpers/bottom_sheet_helper.dart';
import '../../../data/models/task_model.dart';
import '../controllers/task_list_controller.dart';
import '../controllers/task_form_controller.dart';
import 'widgets/task_tile.dart';
import 'widgets/task_section_header.dart';
import '../../../core/helpers/number_extension.dart';

class TasksView extends GetView<TaskListController> {
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
              expandedHeight: 100.0,
              floating: false,
              pinned: true,
              elevation: 0,
              centerTitle: false,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
                onPressed: () => Get.back(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  'tasks_timeline'.tr,
                  style: TextStyle(
                    color: theme.textTheme.titleLarge?.color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    CupertinoIcons.calendar,
                    color: AppTheme.primary,
                    size: 22,
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: controller.selectedDate.value,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      controller.selectedDate.value = picked;
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(
                    CupertinoIcons.add_circled_solid,
                    color: AppTheme.primary,
                    size: 26,
                  ),
                  onPressed: () => Get.toNamed('/add-task'),
                ),
                const SizedBox(width: 12),
              ],
            ),

            // Search & Date Navigation Strip
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: CupertinoSearchTextField(
                      placeholder: 'search_tasks'.tr,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      onChanged: (val) => controller.searchQuery.value = val,
                    ),
                  ),
                  Obx(() => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(CupertinoIcons.chevron_left_circle, size: 24),
                          onPressed: controller.previousDay,
                          color: AppTheme.primary.withValues(alpha: 0.6),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: controller.resetToToday,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  DateFormat.yMMMMEEEEd(Get.locale?.languageCode).format(controller.selectedDate.value).f,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.titleMedium?.color,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.chevron_right_circle, size: 24),
                          onPressed: controller.nextDay,
                          color: AppTheme.primary.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),

            // Timeline Sections
            Obx(() {
              final active = controller.activeTasks;
              final upcoming = controller.upcomingTasks;
              final overdue = controller.overdueTasks;
              final completed = controller.completedTasks;

              if (active.isEmpty && upcoming.isEmpty && overdue.isEmpty && completed.isEmpty) {
                return _buildEmptyState(theme);
              }

              return SliverMainAxisGroup(
                slivers: [
                  // 🚨 Overdue Section
                  if (overdue.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: TaskSectionHeader(
                        title: 'tasks_overdue'.tr,
                        icon: CupertinoIcons.exclamationmark_triangle_fill,
                        color: const Color(0xFFEF4444),
                        count: overdue.length,
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildTaskTile(context, overdue[index]),
                        childCount: overdue.length,
                      ),
                    ),
                  ],

                  // ⚡ Active Now Section
                  if (active.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: TaskSectionHeader(
                        title: 'tasks_active'.tr,
                        icon: CupertinoIcons.play_circle_fill,
                        color: const Color(0xFF3B82F6),
                        count: active.length,
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildTaskTile(context, active[index]),
                        childCount: active.length,
                      ),
                    ),
                  ],

                  // 📅 Upcoming Section
                  if (upcoming.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: TaskSectionHeader(
                        title: 'tasks_upcoming'.tr,
                        icon: CupertinoIcons.clock_fill,
                        color: const Color(0xFF6B7280),
                        count: upcoming.length,
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildTaskTile(context, upcoming[index]),
                        childCount: upcoming.length,
                      ),
                    ),
                  ],

                  // ✅ Completed Section
                  if (completed.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: TaskSectionHeader(
                        title: 'tasks_completed'.tr,
                        icon: CupertinoIcons.check_mark_circled_solid,
                        color: const Color(0xFF10B981),
                        count: completed.length,
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildTaskTile(context, completed[index]),
                        childCount: completed.length,
                      ),
                    ),
                  ],
                ],
              );
            }),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTile(BuildContext context, Task task) {
    return TaskTile(
      task: task,
      onTap: () => _showTaskDetails(context, task),
      onEdit: () {
        Get.find<TaskFormController>().loadTaskIntoForm(task);
        Get.toNamed('/add-task', arguments: task);
      },
      onCompleted: (val) => controller.markTaskCompleted(task),
      onCancel: () => controller.cancelTask(task),
      onDelete: () => controller.deleteTask(task),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.02);
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(CupertinoIcons.square_list, size: 64, color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            const SizedBox(height: 24),
            Text(
              'no_tasks_today'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color?.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'add_task_hint'.tr,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              ),
            ),
          ],
        ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
      ),
    );
  }

  void _showTaskDetails(BuildContext context, Task task) {
    BottomSheetHelper.showSafeBottomSheet(
      builder: (context, setState) {
        final theme = Theme.of(context);
        final isCompleted = task.status == TaskStatus.completed;
        final isCancelled = task.status == TaskStatus.cancelled;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                task.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  decoration: (isCompleted || isCancelled) ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 16),
              if (task.note?.isNotEmpty ?? false) ...[
                Text(
                  'notes'.tr,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
                const SizedBox(height: 8),
                Text(task.note!, style: const TextStyle(fontSize: 15, height: 1.5)),
                const SizedBox(height: 24),
              ],
              _buildDetailItem(CupertinoIcons.time, 'time'.tr, 
                "${DateFormat.jm(Get.locale?.languageCode).format(task.scheduledAt).f}${task.scheduledEnd != null ? ' - ${DateFormat.jm(Get.locale?.languageCode).format(task.scheduledEnd!).f}' : ''}"),
              const SizedBox(height: 12),
              _buildDetailItem(CupertinoIcons.calendar, 'date'.tr, 
                DateFormat.yMMMMd(Get.locale?.languageCode).format(task.scheduledAt).f),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'complete'.tr, 
                      CupertinoIcons.checkmark_alt, 
                      isCompleted ? Colors.grey : const Color(0xFF10B981),
                      () {
                        controller.markTaskCompleted(task);
                        Get.back();
                      }
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      'edit'.tr, 
                      CupertinoIcons.pencil, 
                      AppTheme.primary,
                      () {
                        Get.back();
                        Get.find<TaskFormController>().loadTaskIntoForm(task);
                        Get.toNamed('/add-task', arguments: task);
                      }
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                'delete'.tr, 
                CupertinoIcons.trash, 
                const Color(0xFFEF4444),
                () {
                  Get.back();
                  controller.deleteTask(task);
                }
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary.withValues(alpha: 0.6)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
