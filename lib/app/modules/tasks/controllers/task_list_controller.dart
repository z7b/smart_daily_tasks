import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/task_model.dart';
import '../../../data/providers/task_repository.dart';
import '../../../core/helpers/log_helper.dart';
import '../services/task_recurrence_service.dart';

class TaskListController extends GetxController with WidgetsBindingObserver {
  final TaskRepository _repository;
  TaskListController(this._repository);

  final tasks = <Task>[].obs;
  final filteredTasks = <Task>[].obs;
  final selectedDate = DateTime.now().obs;
  final searchQuery = ''.obs;
  
  final isDeleting = false.obs;
  final isCompleting = false.obs;
  final currentTime = DateTime.now().obs;

  StreamSubscription? _tasksSub;
  Timer? _timer;
  DateTime _lastRefreshDay = DateTime.now();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    
    _listenToTasksForSelectedDate();
    
    // Automatically re-subscribe when selectedDate changes
    ever(selectedDate, (_) => _listenToTasksForSelectedDate());

    debounce(searchQuery, (_) => _applySearchFilter(), time: const Duration(milliseconds: 300));
    ever(tasks, (_) => _applySearchFilter());

    // Pulse timer for UI updates (like time-left labels)
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => currentTime.value = DateTime.now());
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _tasksSub?.cancel();
    _timer?.cancel();
    super.onClose();
  }

  /// ✅ Phase 4: Midnight Bug Fix - Detect Day Change on Resume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (now.day != _lastRefreshDay.day || now.month != _lastRefreshDay.month) {
        talker.info('🌙 Midnight transition detected! Refreshing Tasks selectedDate.');
        _lastRefreshDay = now;
        selectedDate.value = now;
      }
    }
  }

  void _listenToTasksForSelectedDate() {
    _tasksSub?.cancel();
    final startOfDay = DateTime(selectedDate.value.year, selectedDate.value.month, selectedDate.value.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    _tasksSub = _repository.watchTasksForDateRange(startOfDay, endOfDay).listen((data) {
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

  /// ✅ Phase 5: Race Condition Guard added
  Future<void> deleteTask(Task task) async {
    if (isDeleting.value) return;
    try {
      isDeleting.value = true;
      await _repository.deleteTask(task.id);
      talker.info('🗑️ Task deleted: ${task.id}');
      Get.snackbar('Success'.tr, 'task_deleted'.tr, snackPosition: SnackPosition.BOTTOM);
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

      final success = await _repository.completeAndSpawnRecurringTask(updatedTask, nextTask);

      if (success) {
        talker.info('✅ Task completed: ${task.title}');
        if (isRecurring && nextTask != null) {
          talker.info('♻️ Spawned next recurrence for: ${task.title}');
        }
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Error marking task completed');
    } finally {
      isCompleting.value = false;
    }
  }
}
