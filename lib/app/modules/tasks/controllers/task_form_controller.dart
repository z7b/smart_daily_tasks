import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../../../data/models/task_model.dart';
import '../../../data/providers/task_repository.dart';
import '../../../core/helpers/log_helper.dart';

class TaskFormController extends GetxController {
  final TaskRepository _repository;
  TaskFormController(this._repository);

  final titleController = TextEditingController();
  final noteController = TextEditingController();
  final titleFocusNode = FocusNode();
  final noteFocusNode = FocusNode();

  final selectedDate = DateTime.now().obs;
  final startTime = TimeOfDay.now().obs;
  final endTime = TimeOfDay.now().obs;
  final selectedColor = 0.obs;
  final recurrence = TaskRecurrence.none.obs;
  final isNotificationEnabled = false.obs;

  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final now = TimeOfDay.now();
    startTime.value = now;
    endTime.value = TimeOfDay(hour: (now.hour + 1) % 24, minute: now.minute);
  }

  @override
  void onClose() {
    titleController.dispose();
    noteController.dispose();
    titleFocusNode.dispose();
    noteFocusNode.dispose();
    super.onClose();
  }

  void loadTaskIntoForm(Task task) {
    titleController.text = task.title;
    noteController.text = task.note ?? '';
    selectedDate.value = task.scheduledAt;
    startTime.value = TimeOfDay.fromDateTime(task.scheduledAt);
    if (task.scheduledEnd != null) {
      endTime.value = TimeOfDay.fromDateTime(task.scheduledEnd!);
    }
    selectedColor.value = task.color ?? 0;
    recurrence.value = task.recurrence;
    isNotificationEnabled.value = task.isNotificationEnabled;
  }

  void resetForm() {
    titleController.clear();
    noteController.clear();
    selectedDate.value = DateTime.now();
    final now = TimeOfDay.now();
    startTime.value = now;
    endTime.value = TimeOfDay(hour: (now.hour + 1) % 24, minute: now.minute);
    selectedColor.value = 0;
    recurrence.value = TaskRecurrence.none;
    isNotificationEnabled.value = false;
  }

  Future<void> addTask() async {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'title_required'.tr, backgroundColor: Get.theme.colorScheme.errorContainer);
      return;
    }
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      final startDateTime = DateTime(
        selectedDate.value.year,
        selectedDate.value.month,
        selectedDate.value.day,
        startTime.value.hour,
        startTime.value.minute,
      );

      var endDateTime = DateTime(
        selectedDate.value.year,
        selectedDate.value.month,
        selectedDate.value.day,
        endTime.value.hour,
        endTime.value.minute,
      );

      // ✅ Fix: Handle overnight tasks crossing midnight
      if (endDateTime.isBefore(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }

      // ✅ Bug Fix: Duplicate Task Check (UX Governance)
      final existingTasks = await _repository.getTasksForDate(startDateTime);
      final isDuplicate = existingTasks.any((t) => 
        t.title.toLowerCase() == titleController.text.trim().toLowerCase() && 
        t.scheduledAt.hour == startDateTime.hour &&
        t.scheduledAt.minute == startDateTime.minute
      );

      if (isDuplicate) {
        Get.snackbar('error'.tr, 'task_already_exists'.trParams({'title': titleController.text.trim()}), backgroundColor: Get.theme.colorScheme.errorContainer);
        isLoading.value = false;
        return;
      }

      final task = Task(
        id: Isar.autoIncrement,
        title: titleController.text.trim(),
        note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
        scheduledAt: startDateTime,
        scheduledEnd: endDateTime,
        color: selectedColor.value,
        status: TaskStatus.active,
        createdAt: DateTime.now(),
        recurrence: recurrence.value,
        isNotificationEnabled: isNotificationEnabled.value,
      );

      final result = await _repository.addTask(task);
      
      if (result.isSuccess) {
        talker.info('📝 Task created: ${task.title}');
        Get.back(); // close modal
        resetForm();
      } else {
        Get.snackbar('error'.tr, result.error ?? 'failed_to_save'.tr, backgroundColor: Get.theme.colorScheme.errorContainer);
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Failed to create task');
      Get.snackbar('error'.tr, 'failed_to_save'.tr, backgroundColor: Get.theme.colorScheme.errorContainer);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateTask(Task existingTask) async {
    if (titleController.text.trim().isEmpty) return;
    if (isLoading.value) return;
    if (existingTask.status == TaskStatus.completed) {
      talker.warning('🛡️ Blocked edit on completed task: ${existingTask.title}');
      return;
    }

    try {
      isLoading.value = true;
      final startDateTime = DateTime(
        selectedDate.value.year,
        selectedDate.value.month,
        selectedDate.value.day,
        startTime.value.hour,
        startTime.value.minute,
      );

      var endDateTime = DateTime(
        selectedDate.value.year,
        selectedDate.value.month,
        selectedDate.value.day,
        endTime.value.hour,
        endTime.value.minute,
      );

      // ✅ Fix: Handle overnight tasks crossing midnight
      if (endDateTime.isBefore(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }

      final updatedTask = existingTask.copyWith(
        title: titleController.text.trim(),
        note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
        scheduledAt: startDateTime,
        scheduledEnd: endDateTime,
        color: selectedColor.value,
        recurrence: recurrence.value,
        isNotificationEnabled: isNotificationEnabled.value,
      );

      final result = await _repository.updateTask(updatedTask);
      
      if (result.isSuccess) {
        talker.info('📝 Task updated: ${updatedTask.title}');
        Get.back();
        resetForm();
      } else {
        Get.snackbar('error'.tr, result.error ?? 'failed_to_save'.tr, backgroundColor: Get.theme.colorScheme.errorContainer);
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Failed to update task');
    } finally {
      isLoading.value = false;
    }
  }
}
