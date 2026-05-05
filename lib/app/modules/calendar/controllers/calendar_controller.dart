import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:isar/isar.dart';

import '../../../data/models/calendar_event_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/medication_model.dart';

import '../../../data/models/appointment_model.dart';

import '../../../data/providers/calendar_repository.dart';
import '../../../data/providers/task_repository.dart';
import '../../../data/providers/medication_repository.dart';
import '../../../data/providers/appointment_repository.dart';


import '../../../core/helpers/log_helper.dart';
import '../../../core/extensions/date_time_extensions.dart';
import 'dart:async';

class CalendarController extends GetxController {
  final CalendarRepository _calendarRepo = Get.find<CalendarRepository>();
  final TaskRepository _taskRepo = Get.find<TaskRepository>();
  final MedicationRepository _medRepo = Get.find<MedicationRepository>();
  final AppointmentRepository _appointmentRepo = Get.find<AppointmentRepository>();

  final events = <CalendarEvent>[].obs;
  final tasks = <Task>[].obs;
  final recurringTemplates = <Task>[].obs;
  final appointments = <Appointment>[].obs;

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
  
  final List<StreamSubscription> _subs = [];

  @override
  void onInit() {
    super.onInit();
    
    // Subscribe to all sources reactively
    _subs.add(_calendarRepo.watchAllEvents().listen((data) => events.value = data));
    _subs.add(_taskRepo.watchAllTasksData().listen((data) => tasks.value = data));
    _subs.add(_taskRepo.watchRecurringTemplates().listen((data) => recurringTemplates.value = data));
    _subs.add(_appointmentRepo.listenToAppointments().listen((data) => appointments.value = data));

    talker.info('📅 CalendarController initialized with Harmony Sync');
    
    // Auto-update selected events when the main list or selected day changes
    everAll([events, tasks, recurringTemplates, appointments, selectedDay], (_) => _updateSelectedEvents());
  }

  @override
  void onClose() {
    for (var sub in _subs) {
      sub.cancel();
    }
    titleController.dispose();
    descriptionController.dispose();
    titleFocusNode.dispose();
    descriptionFocusNode.dispose();
    super.onClose();
  }

  Future<void> _updateSelectedEvents() async {
    isLoading.value = true;
    try {
      final date = DateTime(selectedDay.value.year, selectedDay.value.month, selectedDay.value.day);
      
      // Fetch from all sources in parallel
      final results = await Future.wait([
        _calendarRepo.getEventsForDate(date),
        _taskRepo.getTasksForDate(date),
        _medRepo.getActiveMedicationsForDate(date),
        _appointmentRepo.getAppointmentsForDay(date),
      ]);

      final List<dynamic> combined = [];
      combined.addAll(results[0] as List<CalendarEvent>);
      combined.addAll(results[1] as List<Task>);
      combined.addAll(results[2] as List<Medication>);
      combined.addAll(results[3] as List<Appointment>);

      selectedEvents.value = combined;
    } catch (e) {
      talker.error('🔴 Harmony Sync Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<dynamic> getEventsForDay(DateTime day) {
    final List<dynamic> markers = [];
    final normalizedDay = DateTime(day.year, day.month, day.day);

    // 1. Regular Events
    markers.addAll(events.where((e) =>
        e.date.year == day.year &&
        e.date.month == day.month &&
        e.date.day == day.day));

    // 2. Physical Tasks
    markers.addAll(tasks.where((t) =>
        t.scheduledAt.year == day.year &&
        t.scheduledAt.month == day.month &&
        t.scheduledAt.day == day.day));

    // 3. Virtual Recurring Tasks (for future dates)
    for (var template in recurringTemplates) {
      // Only show virtual if physical doesn't exist for this series on this day
      final hasPhysical = tasks.any((t) => 
        t.seriesId == template.seriesId && 
        t.scheduledAt.year == day.year &&
        t.scheduledAt.month == day.month &&
        t.scheduledAt.day == day.day
      );

      if (!hasPhysical && _shouldRunOnDay(template, normalizedDay)) {
        markers.add(template);
      }
    }

    // 4. Appointments
    markers.addAll(appointments.where((a) =>
        a.scheduledAt.year == day.year &&
        a.scheduledAt.month == day.month &&
        a.scheduledAt.day == day.day));

    return markers;
  }

  bool _shouldRunOnDay(Task template, DateTime day) {
    // Don't show before start date
    if (day.isBefore(template.scheduledAt.normalized)) return false;

    switch (template.recurrence) {
      case TaskRecurrence.daily:
        return true;
      case TaskRecurrence.weekly:
        return template.scheduledAt.weekday == day.weekday;
      case TaskRecurrence.monthly:
        final lastDayOfMonth = DateTime(day.year, day.month + 1, 0).day;
        final targetDay = template.scheduledAt.day;
        return (day.day == targetDay) || (targetDay > lastDayOfMonth && day.day == lastDayOfMonth);
      default:
        return false;
    }
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
        _showSnackbar('error'.tr, 'title_required'.tr, isError: true);
        return;
      }

      final date = selectedDay.value;

      // ✅ Phase 4: Conflict detection
      if (startTime != null && endTime != null) {
        final startDt = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
        final endDt = DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute);
        
        final conflict = _hasConflict(startDt, endDt);
        if (conflict) {
          _showSnackbar('warning'.tr, 'conflict_warning'.tr, isError: false);
          // We allow saving (UX preference) but warn as per plan
        }
      }


      if (startTime != null && endTime != null) {
        final startDt = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
        final endDt = DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute);
        if (endDt.isBefore(startDt) || endDt.isAtSameMomentAs(startDt)) {
          _showSnackbar('error'.tr, 'invalid_time_range'.tr, isError: true);
          return;
        }
      }

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
        _showSnackbar('success'.tr, 'event_added'.tr);
      } else {
        _showSnackbar('error'.tr, 'save_event_error'.tr, isError: true);
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Event creation exception');
      _showSnackbar('error'.tr, 'unexpected_error_occurred'.tr, isError: true);
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
        _showSnackbar('success'.tr, 'event_added'.tr); // Reusing event_added for consistency
      } else {
        _showSnackbar('error'.tr, 'failed_to_update_event'.tr, isError: true);
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

  // ✅ Phase 4: Conflict detection logic
  bool _hasConflict(DateTime start, DateTime end) {
    return events.any((e) {
      if (e.startTime == null || e.endTime == null) return false;
      // Standard intersection: (StartA < EndB) && (EndA > StartB)
      return start.isBefore(e.endTime!) && end.isAfter(e.startTime!);
    });
  }
}
