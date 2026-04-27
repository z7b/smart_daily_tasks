import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/task_model.dart';
import '../../../data/providers/task_repository.dart';
import '../../../core/helpers/log_helper.dart';
import '../../../core/services/time_service.dart';
import '../../../core/extensions/date_time_extensions.dart';
import '../../../core/services/task_time_service.dart';
import '../services/task_recurrence_service.dart';

class TaskListController extends GetxController with WidgetsBindingObserver {
  final TaskRepository _repository;
  final TimeService _timeService = Get.find<TimeService>();
  final TaskTimeService _taskTimeService = Get.find<TaskTimeService>();
  
  TaskListController(this._repository);

  final tasks = <Task>[].obs;
  final filteredTasks = <Task>[].obs;
  
  // Timeline Categories
  final activeTasks = <Task>[].obs;
  final upcomingTasks = <Task>[].obs;
  final overdueTasks = <Task>[].obs;
  final completedTasks = <Task>[].obs;

  final selectedDate = DateTime.now().obs;
  final searchQuery = ''.obs;
  
  final isDeleting = false.obs;
  final isCompleting = false.obs;
  final currentTime = DateTime.now().obs;

  StreamSubscription? _tasksSub;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    
    _listenToTasksForSelectedDate();
    
    // ✅ Sprint 1 Fix: Listen for day rotation (Midnight Bug Fix)
    _timeService.dayChangedStream.listen((newToday) {
      talker.info('🌅 TaskList: Day rotated to $newToday. Refreshing selectedDate.');
      selectedDate.value = newToday;
    });

    // Automatically re-subscribe when selectedDate changes
    ever(selectedDate, (_) => _listenToTasksForSelectedDate());

    debounce(searchQuery, (_) => _applySearchFilter(), time: const Duration(milliseconds: 300));
    ever(tasks, (_) => _applySearchFilter());
    
    // Pulse timer for UI updates and re-categorization
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      currentTime.value = _timeService.now;
      _categorizeTasks();
    });

    // Re-categorize whenever filteredTasks or currentTime changes
    everAll([filteredTasks, currentTime], (_) => _categorizeTasks());
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _tasksSub?.cancel();
    _timer?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      currentTime.value = _timeService.now;
    }
  }

  void nextDay() {
    selectedDate.value = selectedDate.value.add(const Duration(days: 1));
  }

  void previousDay() {
    selectedDate.value = selectedDate.value.subtract(const Duration(days: 1));
  }

  void resetToToday() {
    selectedDate.value = _timeService.now.normalized;
  }

  void _listenToTasksForSelectedDate() {
    _tasksSub?.cancel();
    _tasksSub = _repository.watchTimeline(selectedDate.value).listen((data) {
      tasks.value = data;
    });
  }
  void _applySearchFilter() {
    if (searchQuery.value.isEmpty) {
      filteredTasks.assignAll(tasks);
      return;
    }
    final query = searchQuery.value.toLowerCase();
    final filtered = tasks.where((t) => 
      t.title.toLowerCase().contains(query) ||
      (t.note?.toLowerCase().contains(query) ?? false)
    ).toList();
    filteredTasks.assignAll(filtered);
  }

  void _categorizeTasks() {
    final active = <Task>[];
    final upcoming = <Task>[];
    final overdue = <Task>[];
    final completed = <Task>[];

    for (final task in filteredTasks) {
      final status = _taskTimeService.getStatus(task);
      switch (status) {
        case TaskStatusUI.active:
          active.add(task);
          break;
        case TaskStatusUI.upcoming:
          upcoming.add(task);
          break;
        case TaskStatusUI.overdue:
          overdue.add(task);
          break;
        case TaskStatusUI.completed:
          completed.add(task);
          break;
      }
    }

    // Sort within categories
    active.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    upcoming.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    overdue.sort((a, b) => (b.scheduledEnd ?? b.scheduledAt).compareTo(a.scheduledEnd ?? a.scheduledAt));
    completed.sort((a, b) => (b.completedAt ?? DateTime.now()).compareTo(a.completedAt ?? DateTime.now()));

    activeTasks.assignAll(active);
    upcomingTasks.assignAll(upcoming);
    overdueTasks.assignAll(overdue);
    completedTasks.assignAll(completed);
  }

  /// ✅ Phase 5 & 6: Race Condition Guard & Zombie Task Fix
  Future<void> deleteTask(Task task) async {
    if (isDeleting.value) return;
    try {
      isDeleting.value = true;
      final result = await _repository.deleteTaskAndStopRecurrence(task);
      if (result.isSuccess) {
        talker.info('🗑️ Task and its recurrence series deleted: ${task.title}');
        Get.snackbar('success'.tr, 'task_deleted'.tr, snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('error'.tr, result.error ?? 'failed_to_delete'.tr, backgroundColor: Get.theme.colorScheme.errorContainer);
      }
    } finally {
      isDeleting.value = false;
    }
  }

  Future<void> cancelTask(Task task) async {
    if (isDeleting.value) return;
    try {
      isDeleting.value = true;
      await _repository.cancelTask(task);
      talker.info('🚫 Task cancelled: ${task.id}');
    } finally {
      isDeleting.value = false;
    }
  }

  /// ✅ Phase 2 & 5: Atomicity & Race Condition Guards
  Future<void> markTaskCompleted(Task task) async {
    if (isCompleting.value) return;
    if (task.status == TaskStatus.completed) return;

    try {
      isCompleting.value = true;
      
      final updatedTask = task.copyWith(
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
      );

      final isRecurring = task.recurrence != TaskRecurrence.none;
      Task? nextTask;

      if (isRecurring) {
        nextTask = TaskRecurrenceService.generateNextInstance(updatedTask);
      }

      final result = await _repository.completeAndSpawnRecurringTask(updatedTask, nextTask);

      if (result.isSuccess) {
        talker.info('✅ Task completed: ${task.title}');
        if (isRecurring && nextTask != null) {
          talker.info('♻️ Spawned next recurrence for: ${task.title}');
        }
      } else {
        Get.snackbar('error'.tr, result.error ?? 'failed_to_save'.tr, backgroundColor: Get.theme.colorScheme.errorContainer);
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Error marking task completed');
    } finally {
      isCompleting.value = false;
    }
  }
}
