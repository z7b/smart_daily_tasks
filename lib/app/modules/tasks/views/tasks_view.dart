import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:smart_daily_tasks/app/data/models/task_model.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/helpers/bottom_sheet_helper.dart';
import '../controllers/task_controller.dart';
import 'widgets/task_tile.dart';

class TasksView extends GetView<TaskController> {
  const TasksView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // SafeArea to prevent top notch issues
      body: SafeArea(
        bottom: false, // Let list scroll to bottom
        child: CustomScrollView(
          slivers: [
            // iOS Style Large App Bar
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
                  icon: const Icon(CupertinoIcons.add_circled_solid, color: AppTheme.primary, size: 28),
                  onPressed: () => Get.toNamed('/add-task'),
                ),
                const SizedBox(width: 8),
              ],
            ),
            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: CupertinoSearchTextField(
                  placeholder: 'search_tasks'.tr,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  onChanged: (val) => controller.searchQuery.value = val,
                ),
              ),
            ),

            // Today's Date header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      DateFormat.yMMMMEEEEd(Get.locale?.languageCode).format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Task List
            Obx(() {
              final allTasks = controller.filteredTasks;
              if (allTasks.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.checkmark_seal_fill, size: 80, color: theme.dividerColor.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'no_tasks_today'.tr,
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ).animate().fadeIn().scale(delay: 200.ms),
                  ),
                );
              }

              final activeTasks = allTasks.where((t) => t.status == TaskStatus.active).toList();
              final completedTasks = allTasks.where((t) => t.status != TaskStatus.active).toList();

              return SliverMainAxisGroup(
                slivers: [
                  if (activeTasks.isNotEmpty) ...[
                    _buildSectionHeader('active'.tr, activeTasks.length, theme),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = activeTasks[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            child: TaskTile(
                              task: task,
                              onTap: () => _showTaskDetails(context, task),
                              onEdit: () {
                                controller.loadTaskIntoForm(task);
                                Get.toNamed('/add-task', arguments: task);
                              },
                              onCompleted: (val) => controller.markTaskCompleted(task),
                              onDelete: () => controller.deleteTask(task),
                              onCancel: () => controller.cancelTask(task),
                            ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1),
                          );
                        },
                        childCount: activeTasks.length,
                      ),
                    ),
                  ],
                  if (completedTasks.isNotEmpty) ...[
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    _buildSectionHeader('task_completed'.tr, completedTasks.length, theme),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = completedTasks[index];
                          return Opacity(
                            opacity: 0.7,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              child: TaskTile(
                                task: task,
                                onTap: () => _showTaskDetails(context, task),
                                onEdit: () {
                                  controller.loadTaskIntoForm(task);
                                  Get.toNamed('/add-task', arguments: task);
                                },
                                onCompleted: (val) => controller.markTaskCompleted(task),
                                onDelete: () => controller.deleteTask(task),
                                onCancel: () => controller.cancelTask(task),
                              ),
                            ),
                          );
                        },
                        childCount: completedTasks.length,
                      ),
                    ),
                  ],
                ],
              );
            }),
            
            // Bottom Padding Space
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        child: Row(
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDetails(BuildContext context, dynamic task) {
    BottomSheetHelper.showSafeBottomSheet(
      builder: (context, setState) {
        final theme = Theme.of(context);
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
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                task.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(CupertinoIcons.clock, size: 16, color: theme.textTheme.bodyMedium?.color),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat.jm().format(task.scheduledAt)}${task.scheduledEnd != null ? ' - ${DateFormat.jm().format(task.scheduledEnd!)}' : ''}',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
              if (task.note != null && task.note.toString().isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    task.note,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        controller.markTaskCompleted(task);
                        if (Get.isBottomSheetOpen ?? false) Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: task.status != TaskStatus.active ? theme.dividerColor : const Color(0xFF34C759),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        'task_completed'.tr,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (Get.isBottomSheetOpen ?? false) Get.back();
                        controller.loadTaskIntoForm(task);
                        Get.toNamed('/add-task', arguments: task);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        foregroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        'edit'.tr,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        controller.deleteTask(task);
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                        foregroundColor: const Color(0xFFFF3B30),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        'delete_task'.tr,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
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
}
