import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';

import '../../../core/services/notification_service.dart';
import 'package:smart_daily_tasks/app/data/models/task_model.dart';
import '../../../data/providers/task_repository.dart';
import '../../../core/helpers/log_helper.dart';
import 'package:intl/intl.dart';
import '../../../core/extensions/date_time_extensions.dart';

class TaskController extends GetxController {
  final TaskRepository _repository;
  TaskController(this._repository);

  final tasks = <Task>[].obs;
  final isLoading = false.obs;
  
  // Search functionality
  final searchQuery = ''.obs;
  final filteredTasks = <Task>[].obs;

  final titleController = TextEditingController();
  final noteController = TextEditingController();

  final titleFocusNode = FocusNode();
  final noteFocusNode = FocusNode();

  // Selection variables for new task
  var selectedDate = DateTime.now().obs;
  var endTime = '9:30 PM'.obs;
  var startTime = '9:30 AM'.obs;
  var selectedColor = 0.obs;
  var isNotificationEnabled = true.obs;
  var recurrence = TaskRecurrence.none.obs;

  @override
  void onInit() {
    super.onInit();
    // ✅ Pro Feature: Listen to arguments for deep linking from Home
    if (Get.arguments != null && Get.arguments is Task) {
      loadTaskIntoForm(Get.arguments as Task);
    } else if (Get.arguments != null && Get.arguments['selectedDate'] != null) {
      selectedDate.value = DateTime.parse(Get.arguments['selectedDate']);
    }
    tasks.bindStream(_repository.watchAllTasks());
    
    // ✅ Optimization: Reactive Search Filter
    // Listen to both list changes and search query changes
    everAll([tasks, searchQuery], (_) => _applySearchFilter());
  }

  void _applySearchFilter() {
    if (searchQuery.value.isEmpty) {
      filteredTasks.assignAll(tasks);
      return;
    }

    final query = searchQuery.value.toLowerCase();
    final filtered = tasks.where((task) {
      return task.title.toLowerCase().contains(query) ||
          (task.note?.toLowerCase().contains(query) ?? false);
    }).toList();
    
    filteredTasks.assignAll(filtered);
  }

  Future<void> addTask() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      FocusManager.instance.primaryFocus?.unfocus();
      await Future.delayed(const Duration(milliseconds: 100));

      final title = titleController.text.trim();
      if (title.isEmpty) {
        _showSnackbar('error'.tr, 'title_required'.tr, isError: true);
        return;
      }

      final now = DateTime.now();
      
      // Professional Time Parsing
      final scheduledAt = _combineDateAndTime(selectedDate.value, startTime.value);
      final scheduledEnd = _combineDateAndTime(selectedDate.value, endTime.value);

      final task = Task(
        note: noteController.text.trim(),
        title: title,
        scheduledAt: scheduledAt,
        scheduledEnd: scheduledEnd,
        color: selectedColor.value,
        status: TaskStatus.active,
        recurrence: recurrence.value,
        isNotificationEnabled: isNotificationEnabled.value,
        createdAt: now,
      );

      final success = await _repository.addTask(task);

      if (success) {
        _scheduleTaskNotificationAsync(task);
        _showSnackbar('success'.tr, 'event_added'.tr);

        await Future.delayed(const Duration(milliseconds: 200));
        if (Get.isDialogOpen ?? false) Get.back();
        Get.back(); // Close the view
        _clearForm();
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Add Task Exception');
      _showSnackbar('error'.tr, 'error'.tr, isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  DateTime _combineDateAndTime(DateTime date, String timeStr) {
    try {
      final format = DateFormat.jm(); // Handle AM/PM
      final time = format.parse(timeStr);
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    } catch (e) {
      // Fallback robust parsing if regional jm() fails
      try {
        final parts = timeStr.split(' ');
        final hm = parts[0].split(':');
        int hour = int.parse(hm[0]);
        int min = int.parse(hm[1]);
        if (parts.length > 1) {
          if (parts[1].toUpperCase() == 'PM' && hour != 12) hour += 12;
          if (parts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;
        }
        return DateTime(date.year, date.month, date.day, hour, min);
      } catch (_) {
         return DateTime(date.year, date.month, date.day, 9, 0);
      }
    }
  }

  /// ✅ New: updateTask method to fix compilation error
  Future<void> updateTask(Task task) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      FocusManager.instance.primaryFocus?.unfocus();
      await Future.delayed(const Duration(milliseconds: 100));

      final title = titleController.text.trim();
      if (title.isEmpty) {
        _showSnackbar('error'.tr, 'title_required'.tr, isError: true);
        return;
      }

      final scheduledAt = _combineDateAndTime(selectedDate.value, startTime.value);
      final scheduledEnd = _combineDateAndTime(selectedDate.value, endTime.value);

      final updatedTask = task.copyWith(
        title: title,
        note: noteController.text.trim(),
        scheduledAt: scheduledAt,
        scheduledEnd: scheduledEnd,
        color: selectedColor.value,
        recurrence: recurrence.value,
        isNotificationEnabled: isNotificationEnabled.value,
      );

      final success = await _repository.updateTask(updatedTask);

      if (success) {
        await NotificationService().cancelNotification(task.id);
        _scheduleTaskNotificationAsync(updatedTask);
        _showSnackbar('success'.tr, 'task_update_success'.tr);

        await Future.delayed(const Duration(milliseconds: 200));
        Get.back(); // Close view
        _clearForm();
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Update Task Exception');
      _showSnackbar('error'.tr, 'error'.tr, isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  void _showSnackbar(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: (isError ? Colors.redAccent : Colors.green).withValues(alpha: 0.1),
      colorText: isError ? Colors.redAccent : Colors.green,
      duration: const Duration(seconds: 2),
    );
  }

  void _scheduleTaskNotificationAsync(Task task) {
    if (task.status != TaskStatus.active || !task.isNotificationEnabled) return;

    Future.microtask(() async {
      try {
        if (task.scheduledAt.isAfter(DateTime.now())) {
          NotificationService().scheduleNotification(
            id: task.id,
            title: '${'tasks'.tr}: ${task.title}',
            body: task.note ?? '',
            scheduledTime: task.scheduledAt,
          );
        }
      } catch (e) {
        talker.error('Error scheduling notification: $e');
      }
    });
  }

  void deleteTask(Task task) async {
    try {
      await NotificationService().cancelNotification(task.id);
      await _repository.deleteTask(task.id);
      _showSnackbar('success'.tr, 'event_deleted'.tr);
    } catch (e) {
      talker.handle(e, null, 'Error deleting task');
      _showSnackbar('error'.tr, 'task_delete_error'.tr, isError: true);
    }
  }

  void markTaskCompleted(Task task) async {
    try {
      // ✅ Doctoral Logic: Strict Temporal Integrity
      if (task.status == TaskStatus.active && task.scheduledAt.isAfter(DateTime.now())) {
        _showSnackbar('security'.tr, 'strict_completion_error'.tr, isError: true);
        HapticFeedback.heavyImpact();
        return;
      }

      final isNowCompleted = task.status != TaskStatus.completed;
      final updatedTask = task.copyWith(
        status: isNowCompleted ? TaskStatus.completed : TaskStatus.active,
        completedAt: isNowCompleted ? DateTime.now() : null,
      );
      
      await _repository.updateTask(updatedTask);
      
      if (isNowCompleted) {
        await NotificationService().cancelNotification(task.id);
        
        // --- Recurrence Engine: Clone-and-Spawn ---
        if (updatedTask.recurrence != TaskRecurrence.none) {
           Duration gap;
           switch(updatedTask.recurrence) {
             case TaskRecurrence.daily: gap = const Duration(days: 1); break;
             case TaskRecurrence.weekly: gap = const Duration(days: 7); break;
             case TaskRecurrence.monthly: gap = const Duration(days: 30); break; // Simplified
             default: gap = Duration.zero;
           }

          final nextScheduledAt = updatedTask.scheduledAt.add(gap);
          final nextScheduledEnd = updatedTask.scheduledEnd?.add(gap);
          
          final nextTask = updatedTask.copyWith(
            id: Isar.autoIncrement, // New Task
            status: TaskStatus.active,
            completedAt: null,
            scheduledAt: nextScheduledAt,
            scheduledEnd: nextScheduledEnd,
            createdAt: DateTime.now(),
          );
          
          final success = await _repository.addTask(nextTask);
          if (success) {
             _scheduleTaskNotificationAsync(nextTask);
             talker.info('🔁 Recurrence spawned: ${nextTask.title} for ${nextTask.scheduledAt}');
          }
        }
      } else {
        _scheduleTaskNotificationAsync(updatedTask);
      }
    } catch (e) {
      talker.handle(e, null, 'Error updating task');
    }
  }

  void cancelTask(Task task) async {
    try {
      final updatedTask = task.copyWith(
        status: TaskStatus.cancelled,
        completedAt: DateTime.now(), // Recorded in history
      );
      
      await _repository.updateTask(updatedTask);
      await NotificationService().cancelNotification(task.id);
      
      _showSnackbar('success'.tr, 'task_cancelled'.tr);
      
      // ✅ Option for Undo
      Get.showSnackbar(GetSnackBar(
        message: 'task_cancelled'.tr,
        mainButton: TextButton(
          onPressed: () {
            final undoTask = updatedTask.copyWith(status: TaskStatus.active, completedAt: null);
            _repository.updateTask(undoTask);
            Get.back();
          },
          child: Text('undo_cancel'.tr, style: const TextStyle(color: Colors.white)),
        ),
        duration: const Duration(seconds: 4),
      ));

    } catch (e) {
      talker.error('Error cancelling task: $e');
    }
  }

  void loadTaskIntoForm(Task task) {
    titleController.text = task.title;
    noteController.text = task.note ?? '';
    selectedDate.value = task.scheduledAt;
    startTime.value = DateFormat.jm().format(task.scheduledAt);
    endTime.value = task.scheduledEnd != null 
        ? DateFormat.jm().format(task.scheduledEnd!) 
        : '9:30 PM';
    selectedColor.value = task.color ?? 0;
    isNotificationEnabled.value = task.isNotificationEnabled;
    recurrence.value = task.recurrence;
  }

  void _clearForm() {
    titleController.clear();
    noteController.clear();
    selectedDate.value = DateTime.now();
    startTime.value = '9:30 AM';
    endTime.value = '9:30 PM';
    selectedColor.value = 0;
    isNotificationEnabled.value = true;
    recurrence.value = TaskRecurrence.none;
  }

  @override
  void onClose() {
    titleController.dispose();
    noteController.dispose();
    titleFocusNode.dispose();
    noteFocusNode.dispose();
    super.onClose();
  }
}
