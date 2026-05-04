import 'dart:ui';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/task_model.dart';
import '../../../data/models/medication_model.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/providers/task_repository.dart';
import '../../../data/providers/medication_repository.dart';
import '../../../data/providers/appointment_repository.dart';
import '../../../core/services/task_time_service.dart';
import '../../../core/services/time_service.dart';
import '../../../core/helpers/number_extension.dart';

import 'assistant_response.dart';

/// Centralized data retrieval layer for the Smart Assistant.
/// Answers user queries with precise time calculations.
class QueryEngine {
  final TaskRepository _taskRepo;
  final MedicationRepository _medRepo;
  final AppointmentRepository _appointmentRepo;
  final TaskTimeService _taskTimeService;
  final TimeService _timeService;

  QueryEngine({
    required TaskRepository taskRepo,
    required MedicationRepository medRepo,
    required AppointmentRepository appointmentRepo,
    required TaskTimeService taskTimeService,
    required TimeService timeService,
  })  : _taskRepo = taskRepo,
        _medRepo = medRepo,
        _appointmentRepo = appointmentRepo,
        _taskTimeService = taskTimeService,
        _timeService = timeService;

  String get _locale => Get.locale?.languageCode ?? 'en';

  // ─── Task Queries ──────────────────────────────────

  /// Returns all tasks for today with status and countdown
  Future<AssistantResponse> queryTasks() async {
    final now = _timeService.now;
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final tasks = await _taskRepo.getTasksForDateRange(startOfDay, endOfDay);

    if (tasks.isEmpty) {
      return AssistantResponse.text('no_tasks_today'.tr);
    }

    tasks.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final cards = tasks.map((t) => _taskToCard(t)).toList();
    final active = tasks.where((t) => t.status == TaskStatus.active).length;
    final completed = tasks.where((t) => t.status == TaskStatus.completed).length;

    return AssistantResponse.withCards(
      text: 'assistant_tasks_summary'.trParams({
        'total': tasks.length.toString().f,
        'active': active.toString().f,
        'completed': completed.toString().f,
      }),
      type: ResponseType.listCard,
      cards: cards,
    );
  }

  /// Returns the most urgent upcoming task
  Future<AssistantResponse> queryNextTask() async {
    final now = _timeService.now;
    final task = await _taskRepo.getNextActiveTask(now);

    if (task == null) {
      return AssistantResponse.text('no_upcoming_tasks'.tr);
    }

    return AssistantResponse.withCards(
      text: 'assistant_next_task'.trParams({
        'title': task.title,
        'time': _taskTimeService.getTimeLabel(task),
      }),
      type: ResponseType.taskCard,
      cards: [_taskToCard(task)],
    );
  }

  // ─── Appointment Queries ───────────────────────────

  /// Returns all upcoming appointments
  Future<AssistantResponse> queryAppointments() async {
    final now = _timeService.now;
    final appointments = await _appointmentRepo.getUpcomingAppointments(now);
    
    final upcoming = appointments
        .where((a) => a.scheduledAt.isAfter(now) && a.status == AppointmentStatus.active)
        .toList();

    if (upcoming.isEmpty) {
      return AssistantResponse.text('no_appointments'.tr);
    }

    upcoming.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final cards = upcoming.map((a) => _appointmentToCard(a)).toList();

    return AssistantResponse.withCards(
      text: 'assistant_appointments_summary'.trParams({
        'count': upcoming.length.toString().f,
      }),
      type: ResponseType.listCard,
      cards: cards,
    );
  }

  /// Returns the next upcoming appointment
  Future<AssistantResponse> queryNextAppointment() async {
    final now = _timeService.now;
    final appointments = await _appointmentRepo.getUpcomingAppointments(now);
    
    final upcoming = appointments
        .where((a) => a.scheduledAt.isAfter(now) && a.status == AppointmentStatus.active)
        .toList();

    if (upcoming.isEmpty) {
      return AssistantResponse.text('no_appointments'.tr);
    }

    upcoming.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final next = upcoming.first;

    final diff = next.scheduledAt.difference(now);
    final countdown = _formatDiff(diff);

    return AssistantResponse.withCards(
      text: 'assistant_next_appointment'.trParams({
        'doctor': next.doctorName,
        'countdown': countdown,
      }),
      type: ResponseType.appointmentCard,
      cards: [_appointmentToCard(next)],
    );
  }

  // ─── Medication Queries ────────────────────────────

  /// Returns all active medications with today's compliance
  Future<AssistantResponse> queryMedications() async {
    final meds = await _medRepo.getAllMedications();
    final active = meds.where((m) => m.isActive).toList();

    if (active.isEmpty) {
      return AssistantResponse.text('no_active_meds'.tr);
    }

    final cards = active.map((m) => _medicationToCard(m)).toList();

    return AssistantResponse.withCards(
      text: 'assistant_medications_summary'.trParams({
        'count': active.length.toString().f,
      }),
      type: ResponseType.listCard,
      cards: cards,
    );
  }

  /// Returns the next medication dose
  Future<AssistantResponse> queryNextMedication() async {
    final meds = await _medRepo.getAllMedications();
    final active = meds.where((m) => m.isActive).toList();

    if (active.isEmpty) {
      return AssistantResponse.text('no_active_meds'.tr);
    }

    final now = _timeService.now;
    String? nextMedName;
    String? nextTimeStr;
    Duration? shortestDiff;

    for (final med in active) {
      for (final timeStr in med.reminderTimes) {
        final parts = timeStr.split(':');
        if (parts.length != 2) continue;
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final reminderTime = DateTime(now.year, now.month, now.day, hour, minute);

        if (reminderTime.isAfter(now)) {
          final diff = reminderTime.difference(now);
          if (shortestDiff == null || diff < shortestDiff) {
            shortestDiff = diff;
            nextMedName = med.name;
            nextTimeStr = DateFormat.jm(_locale).format(reminderTime).f;
          }
        }
      }
    }

    if (nextMedName == null || shortestDiff == null) {
      return AssistantResponse.text('all_meds_taken_today'.tr);
    }

    return AssistantResponse.text(
      'assistant_next_medication'.trParams({
        'name': nextMedName,
        'time': nextTimeStr!,
        'countdown': _formatDiff(shortestDiff),
      }),
    );
  }

  // ─── Overview Query ────────────────────────────────

  /// Returns a combined overview of today's tasks, appointments, and medications
  Future<AssistantResponse> queryOverview() async {
    final now = _timeService.now;
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final tasks = await _taskRepo.getTasksForDateRange(startOfDay, endOfDay);
    final activeTasks = tasks.where((t) => t.status == TaskStatus.active).length;
    final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).length;

    final appointments = await _appointmentRepo.getUpcomingAppointments(now);
    final upcomingAppointments = appointments
        .where((a) => a.scheduledAt.isAfter(now) && a.status == AppointmentStatus.active)
        .length;

    final meds = await _medRepo.getAllMedications();
    final activeMeds = meds.where((m) => m.isActive).length;

    final parts = <String>[];
    
    if (tasks.isNotEmpty) {
      parts.add('📝 ${'tasks'.tr}: ${activeTasks.toString().f} ${'active'.tr} / ${completedTasks.toString().f} ${'completed'.tr}');
    }
    if (upcomingAppointments > 0) {
      parts.add('🏥 ${'doctor_appointments'.tr}: ${upcomingAppointments.toString().f}');
    }
    if (activeMeds > 0) {
      parts.add('💊 ${'medications'.tr}: ${activeMeds.toString().f} ${'active'.tr}');
    }

    if (parts.isEmpty) {
      return AssistantResponse.text('assistant_nothing_scheduled'.tr);
    }

    return AssistantResponse.text(
      '${'assistant_overview'.tr}\n\n${parts.join('\n')}',
    );
  }

  // ─── Focus Query ──────────────────────────────────

  /// Returns smart focus: high-priority tasks + next appointment + next medication
  Future<AssistantResponse> queryFocus() async {
    final now = _timeService.now;
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final tasks = await _taskRepo.getTasksForDateRange(startOfDay, endOfDay);
    final activeTasks = tasks
        .where((t) => t.status == TaskStatus.active)
        .toList()
      ..sort((a, b) {
        final priorityOrder = {TaskPriority.high: 0, TaskPriority.medium: 1, TaskPriority.low: 2};
        final pCmp = (priorityOrder[a.priority] ?? 1).compareTo(priorityOrder[b.priority] ?? 1);
        if (pCmp != 0) return pCmp;
        return a.scheduledAt.compareTo(b.scheduledAt);
      });

    final parts = <String>[];

    if (activeTasks.isEmpty) {
      parts.add('✅ ${'no_pending_tasks'.tr}');
    } else {
      final topTasks = activeTasks.take(3);
      for (final task in topTasks) {
        final timeStr = DateFormat.jm(_locale).format(task.scheduledAt).f;
        final priorityIcon = task.priority == TaskPriority.high ? '🔴' 
            : task.priority == TaskPriority.medium ? '🟡' : '🟢';
        parts.add('$priorityIcon ${task.title} — $timeStr');
      }
      if (activeTasks.length > 3) {
        parts.add('   +${(activeTasks.length - 3).toString().f} ${'tasks'.tr}...');
      }
    }

    // Next appointment
    final appointments = await _appointmentRepo.getUpcomingAppointments(now);
    final upcomingAppts = appointments
        .where((a) => a.scheduledAt.isAfter(now) && a.status == AppointmentStatus.active)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    if (upcomingAppts.isNotEmpty) {
      final next = upcomingAppts.first;
      final diff = next.scheduledAt.difference(now);
      parts.add('\n🏥 ${next.doctorName} — ${_formatDiff(diff)}');
    }

    // Next medication
    final meds = await _medRepo.getAllMedications();
    final activeMeds = meds.where((m) => m.isActive).toList();
    Duration? shortestDiff;
    String? nextMedName;

    for (final med in activeMeds) {
      for (final timeStr in med.reminderTimes) {
        final timeParts = timeStr.split(':');
        if (timeParts.length != 2) continue;
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        final reminderTime = DateTime(now.year, now.month, now.day, hour, minute);
        if (reminderTime.isAfter(now)) {
          final diff = reminderTime.difference(now);
          if (shortestDiff == null || diff < shortestDiff) {
            shortestDiff = diff;
            nextMedName = med.name;
          }
        }
      }
    }
    if (nextMedName != null) {
      parts.add('💊 $nextMedName — ${_formatDiff(shortestDiff!)}');
    }

    return AssistantResponse.text(
      '🎯 ${'today_focus'.tr}\n\n${parts.join('\n')}',
    );
  }

  // ─── Health Check Query ───────────────────────────

  /// Returns medication compliance + step activity for the day
  Future<AssistantResponse> queryHealthCheck() async {
    final meds = await _medRepo.getAllMedications();
    final active = meds.where((m) => m.isActive).toList();

    final parts = <String>[];

    if (active.isEmpty) {
      parts.add('✅ ${'no_medications_scheduled'.tr}');
    } else {
      int totalTaken = 0;
      int totalExpected = 0;

      for (final med in active) {
        final taken = med.todayDoseCount;
        final expected = med.reminderTimes.length;
        totalTaken += taken;
        totalExpected += expected;
        
        final icon = taken >= expected ? '✅' : '⏳';
        parts.add('$icon ${med.name}: ${taken.toString().f}/${expected.toString().f}');
      }

      if (totalExpected > 0) {
        final pct = ((totalTaken / totalExpected) * 100).round();
        parts.insert(0, '💊 ${'medications'.tr} — ${pct.toString().f}%\n');
      }
    }

    return AssistantResponse.text(
      '🩺 ${'health_check'.tr}\n\n${parts.join('\n')}',
    );
  }

  // ─── Card Builders ─────────────────────────────────

  ResponseCard _taskToCard(Task task) {
    final status = _taskTimeService.getStatus(task);
    final color = _taskTimeService.getStatusColor(status);
    final timeLabel = _taskTimeService.getTimeLabel(task);
    final timeStr = DateFormat.jm(_locale).format(task.scheduledAt).f;

    return ResponseCard(
      title: task.title,
      subtitle: task.note,
      timeInfo: timeStr,
      countdown: timeLabel,
      statusLabel: status.name.tr,
      statusColor: color,
    );
  }

  ResponseCard _appointmentToCard(Appointment appointment) {
    final timeStr = DateFormat.jm(_locale).format(appointment.scheduledAt).f;
    final dateStr = DateFormat.MMMd(_locale).format(appointment.scheduledAt).f;
    final diff = appointment.scheduledAt.difference(_timeService.now);
    final countdown = diff.isNegative ? 'overdue'.tr : _formatDiff(diff);

    return ResponseCard(
      title: appointment.doctorName,
      subtitle: (appointment.clinicName != null && appointment.clinicName!.isNotEmpty) ? appointment.clinicName : null,
      timeInfo: '$dateStr • $timeStr',
      countdown: countdown,
      statusLabel: diff.isNegative ? 'overdue'.tr : 'upcoming'.tr,
      statusColor: diff.isNegative ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
    );
  }

  ResponseCard _medicationToCard(Medication med) {
    final taken = med.todayDoseCount;
    final total = med.reminderTimes.length;
    final compliance = '${'$taken'.f} / ${'$total'.f}';

    return ResponseCard(
      title: med.name,
      subtitle: med.dosage,
      timeInfo: compliance,
      statusLabel: taken >= total ? 'completed'.tr : 'active'.tr,
      statusColor: taken >= total ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
    );
  }

  // ─── Helpers ───────────────────────────────────────

  String _formatDiff(Duration diff) {
    if (diff.inDays >= 1) {
      if (diff.inDays == 1) return 'tomorrow'.tr;
      return 'in_x_days'.trParams({'days': diff.inDays.toString().f});
    }
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) {
      return '${hours.toString().f}${'hours_abbr'.tr} ${minutes.toString().f}${'minutes_abbr'.tr}';
    }
    return '${minutes.toString().f}${'minutes_abbr'.tr}';
  }
}
