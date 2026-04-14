import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:isar/isar.dart';

import '../../../data/models/calendar_event_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/medication_model.dart';

import '../../../data/providers/calendar_repository.dart';
import '../../../data/providers/task_repository.dart';
import '../../../data/providers/medication_repository.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/helpers/log_helper.dart';

class CalendarController extends GetxController {
  final CalendarRepository _calendarRepo = Get.find<CalendarRepository>();
  final TaskRepository _taskRepo = Get.find<TaskRepository>();
  final MedicationRepository _medRepo = Get.find<MedicationRepository>();

  final events = <CalendarEvent>[].obs;
  final selectedDay = DateTime.now().obs;
  final focusedDay = DateTime.now().obs;
  final calendarFormat = CalendarFormat.month.obs;
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final titleFocusNode = FocusNode();
  final descriptionFocusNode = FocusNode();

  final selectedDate = DateTime.now().obs;
  final selectedEvents = <dynamic>[].obs; // Changed to dynamic for Harmony Sync
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Bind stream from repository to observable list
    events.bindStream(_calendarRepo.watchAllEvents());
    talker.info('📅 CalendarController initialized');
    
    // Auto-update selected events when the main list or selected day changes
    everAll([events, selectedDay], (_) => _updateSelectedEvents());
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    titleFocusNode.dispose();
    descriptionFocusNode.dispose();
    super.onClose();
  }

  Future<void> _updateSelectedEvents() async {
    isLoading.value = true;
    try {
      final date = selectedDay.value;
      
      // Fetch from all sources in parallel
      final results = await Future.wait([
        _calendarRepo.getEventsForDate(date),
        _taskRepo.getTasksForDate(date),
        _medRepo.getActiveMedicationsForDate(date),
      ]);

      final List<dynamic> combined = [];
      combined.addAll(results[0] as List<CalendarEvent>);
      combined.addAll(results[1] as List<Task>);
      combined.addAll(results[2] as List<Medication>);

      selectedEvents.value = combined;
    } catch (e) {
      talker.error('🔴 Harmony Sync Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<CalendarEvent> getEventsForDay(DateTime day) {
    return events
        .where((e) =>
            e.date.year == day.year &&
            e.date.month == day.month &&
            e.date.day == day.day)
        .toList();
  }

  void onDaySelected(DateTime selected, DateTime focused) {
    if (!isSameDay(selectedDay.value, selected)) {
      selectedDay.value = selected;
      focusedDay.value = focused;
    }
  }

  void onFormatChanged(CalendarFormat format) {
    calendarFormat.value = format;
  }

  Future<void> addCalendarEvent({
    required String title,
    String? description,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      FocusManager.instance.primaryFocus?.unfocus();
      await Future.delayed(const Duration(milliseconds: 100));

      final titleTrimmed = title.trim();
      if (titleTrimmed.isEmpty) {
        _showSnackbar('error'.tr, 'Title is required', isError: true);
        return;
      }

      final date = selectedDay.value;

      final event = CalendarEvent(
        title: titleTrimmed,
        description: description?.trim().isEmpty ?? true ? null : description?.trim(),
        date: date,
        startTime: startTime != null
            ? DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute)
            : null,
        endTime: endTime != null
            ? DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute)
            : null,
        createdAt: DateTime.now(),
      );

      final success = await _calendarRepo.addEvent(event);
      
      if (success) {
        Get.back();
        _showSnackbar('error'.tr, 'event_added'.tr);
      } else {
        _showSnackbar('error'.tr, 'Could not save event', isError: true);
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Event creation exception');
      _showSnackbar('error'.tr, 'An unexpected error occurred', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateEvent(CalendarEvent event) async {
    if (isLoading.value) return;
    
    try {
      isLoading.value = true;
      final success = await _calendarRepo.updateEvent(event);
      if (success) {
        Get.back();
        _showSnackbar('Success'.tr, 'event_added'.tr);
      } else {
        _showSnackbar('Error'.tr, 'Failed to update event', isError: true);
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Event update exception');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteEvent(Id id) async {
    try {
      await _calendarRepo.deleteEvent(id);
      _showSnackbar('Success'.tr, 'event_deleted'.tr);
    } catch (e) {
      _showSnackbar('Error'.tr, 'Failed to delete event', isError: true);
    }
  }

  void _showSnackbar(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: isError ? SnackPosition.BOTTOM : SnackPosition.TOP,
      backgroundColor: (isError ? Colors.redAccent : Colors.green).withValues(alpha: 0.1),
      colorText: isError ? Colors.redAccent : Colors.green,
      duration: const Duration(seconds: 2),
    );
  }
}
