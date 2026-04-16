import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'dart:async';

import 'package:smart_daily_tasks/app/core/services/notification_service.dart';
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
  var endTime = const TimeOfDay(hour: 21, minute: 30).obs;
  var startTime = const TimeOfDay(hour: 9, minute: 30).obs;
  var selectedColor = 0.obs;
  var isNotificationEnabled = true.obs;
  var recurrence = TaskRecurrence.none.obs;
  
  // 🕒 Time Governance: Pulse Ticker for Live UI
  final currentTime = DateTime.now().obs;
  Timer? _timer;

  StreamSubscription? _tasksSub;

  @override
  void onInit() {
    super.onInit();
    // ✅ Pro Feature: Listen to arguments for deep linking from Home
    if (Get.arguments != null && Get.arguments is Task) {
      loadTaskIntoForm(Get.arguments as Task);
    } else if (Get.arguments != null && Get.arguments is Map) {
      try {
        final date = Get.arguments['selectedDate'];
        if (date is String) {
          selectedDate.value = DateTime.parse(date);
        }
      } catch (e) {
        talker.error('Invalid date: $e');
      }
    }
    
    _tasksSub = _repository.watchAllTasks()
        .listen((data) => tasks.value = data);
    
    // ✅ Optimization: Reactive Search Filter with Debounce
    debounce(searchQuery, (_) => _applySearchFilter(), time: const Duration(milliseconds: 300));
    ever(tasks, (_) => _applySearchFilter());

    _startTimeTick();
  }

  void _startTimeTick() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      currentTime.value = DateTime.now();
      talker.debug('🕒 Task Ticker: Pulse');
    });
  }

  void _stopTimeTick() {
    _timer?.cancel();
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

      // 🛡️ Governance: Strict Temporal Integrity (Start must be strictly before End)
      if (!scheduledEnd.isAfter(scheduledAt)) {
        _showSnackbar('error'.tr, 'invalid_time_range'.tr, isError: true);
        return;
      }

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

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
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

      // 🛡️ Governance: Strict Temporal Integrity
      if (scheduledEnd.isBefore(scheduledAt)) {
        _showSnackbar('error'.tr, 'invalid_time_range'.tr, isError: true);
        return;
      }

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
        await Get.find<NotificationService>().cancelNotification(task.id);
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
          Get.find<NotificationService>().scheduleNotification(
            id: task.id + 1000000, // Offset to prevent collision with meds
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
      await Get.find<NotificationService>().cancelNotification(task.id);
      await _repository.deleteTask(task.id);
      _showSnackbar('success'.tr, 'event_deleted'.tr);
    } catch (e) {
      talker.handle(e, null, 'Error deleting task');
      _showSnackbar('error'.tr, 'task_delete_error'.tr, isError: true);
    }
  }

  void markTaskCompleted(Task task) async {
    try {
      // Logic: Allow completing tasks at any time, even future ones, for maximum flexibility.
      // Strict restrictions removed per user request.

      final isNowCompleted = task.status != TaskStatus.completed;
      final updatedTask = task.copyWith(
        status: isNowCompleted ? TaskStatus.completed : TaskStatus.active,
        completedAt: isNowCompleted ? DateTime.now() : null,
      );
      
      await _repository.updateTask(updatedTask);
      
      if (isNowCompleted) {
        await Get.find<NotificationService>().cancelNotification(task.id);
        
         // --- Recurrence Engine: Clone-and-Spawn ---
        if (updatedTask.recurrence != TaskRecurrence.none) {
           DateTime nextScheduledAt = updatedTask.scheduledAt;
           DateTime? nextScheduledEnd;
           
           switch(updatedTask.recurrence) {
             case TaskRecurrence.daily:
                nextScheduledAt = updatedTask.scheduledAt.add(const Duration(days: 1));
                nextScheduledEnd = updatedTask.scheduledEnd?.add(const Duration(days: 1));
                break;
             case TaskRecurrence.weekly:
                nextScheduledAt = updatedTask.scheduledAt.add(const Duration(days: 7));
                nextScheduledEnd = updatedTask.scheduledEnd?.add(const Duration(days: 7));
                break;
             case TaskRecurrence.monthly:
                var nMonth = updatedTask.scheduledAt.month + 1;
                var nYear = updatedTask.scheduledAt.year;
                if (nMonth > 12) { nMonth = 1; nYear++; }
                
                var maxDays = DateTime(nYear, nMonth + 1, 0).day;
                var nDay = updatedTask.scheduledAt.day > maxDays ? maxDays : updatedTask.scheduledAt.day;
                
                nextScheduledAt = DateTime(nYear, nMonth, nDay, updatedTask.scheduledAt.hour, updatedTask.scheduledAt.minute);
                
                if (updatedTask.scheduledEnd != null) {
                  var maxDaysEnd = DateTime(nYear, nMonth + 1, 0).day;
                  var eDay = updatedTask.scheduledEnd!.day > maxDaysEnd ? maxDaysEnd : updatedTask.scheduledEnd!.day;
                  nextScheduledEnd = DateTime(nYear, nMonth, eDay, updatedTask.scheduledEnd!.hour, updatedTask.scheduledEnd!.minute);
                }
                break;
             default: break;
           }

          final nextTask = Task(
            id: Isar.autoIncrement, // New Task
            title: updatedTask.title,
            note: updatedTask.note,
            color: updatedTask.color,
            priority: updatedTask.priority,
            tags: updatedTask.tags,
            recurrence: updatedTask.recurrence,
            isNotificationEnabled: updatedTask.isNotificationEnabled,
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
      await Get.find<NotificationService>().cancelNotification(task.id);
      
      _showSnackbar('success'.tr, 'task_cancelled'.tr);
      
      // ✅ Option for Undo
      Get.showSnackbar(GetSnackBar(
        message: 'task_cancelled'.tr,
        mainButton: TextButton(
          onPressed: () async {
            final undoTask = updatedTask.copyWith(status: TaskStatus.active, completedAt: null);
            await _repository.updateTask(undoTask);
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
    startTime.value = TimeOfDay.fromDateTime(task.scheduledAt);
    endTime.value = task.scheduledEnd != null 
        ? TimeOfDay.fromDateTime(task.scheduledEnd!) 
        : const TimeOfDay(hour: 21, minute: 30);
    selectedColor.value = task.color ?? 0;
    isNotificationEnabled.value = task.isNotificationEnabled;
    recurrence.value = task.recurrence;
  }

  void _clearForm() {
    titleController.clear();
    noteController.clear();
    selectedDate.value = DateTime.now();
    startTime.value = const TimeOfDay(hour: 9, minute: 30);
    endTime.value = const TimeOfDay(hour: 21, minute: 30);
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
    _stopTimeTick();
    _tasksSub?.cancel();
    super.onClose();
  }
}
