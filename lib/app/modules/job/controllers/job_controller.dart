import 'dart:convert';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/job_repository.dart';
import '../../../data/models/work_profile_model.dart';
import '../../../data/models/attendance_log_model.dart';
import '../../../core/helpers/log_helper.dart';
import 'package:smart_daily_tasks/app/core/services/notification_service.dart';
import '../../../core/extensions/date_time_extensions.dart';
import 'package:isar/isar.dart';

class JobController extends GetxController {
  final JobRepository _repository = Get.find<JobRepository>();

  final profile = WorkProfile().obs;
  final todayLog = Rxn<AttendanceLog>();

  // Analytics
  final weeklyStats = <AttendanceLog>[].obs;
  final monthlyStats = <AttendanceLog>[].obs;
  final yearlyStats = <AttendanceLog>[].obs;

  final daysUntilSalary = 0.obs;
  final salaryProgress = 0.0.obs; // ✅ Phase 3: Track cross-month progress
  final attendanceRate = 0.0.obs;
  final consistencyRate = 0.0.obs; // 🚀 New Performance Metric
  final isLoading = false.obs;

  // Weekly Chart Data (Sorted)
  final weeklyChartData = <AttendanceLog>[].obs;

  // Statistical Summaries
  final statsSummary = <AttendanceStatus, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    refreshData();
  }

  Future<void> refreshData() async {
    try {
      isLoading.value = true;
      profile.value = await _repository.getWorkProfile();

      final now = DateTime.now();
      todayLog.value = await _repository.getLogForDate(now);

      _calculateSalaryCountdown();
      await _loadAnalytics();
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 JobController Refresh Error');
    } finally {
      isLoading.value = false;
    }
  }

  void _calculateSalaryCountdown() {
    final now = DateTime.now();
    final salDay = profile.value.salaryDay;

    // ✅ Phase 3: Strict Cross-Month Salary Loop
    var prevSalary = DateTime(now.year, now.month, salDay);
    var nextSalary = DateTime(now.year, now.month + 1, salDay);

    // Validate bounds for current, previous, and next month
    final daysInPrevMonth = DateTime(
      prevSalary.year,
      prevSalary.month + 1,
      0,
    ).day;
    final daysInNextMonth = DateTime(
      nextSalary.year,
      nextSalary.month + 1,
      0,
    ).day;

    if (salDay > daysInPrevMonth)
      prevSalary = DateTime(now.year, now.month, daysInPrevMonth);
    if (salDay > daysInNextMonth)
      nextSalary = DateTime(now.year, now.month + 1, daysInNextMonth);

    if (now.isAfter(prevSalary) || now.isAtSameMomentAs(prevSalary)) {
      // In current cycle looking ahead to next month
    } else {
      // It's the beginning of the month before payday; previous salary was last month
      prevSalary = DateTime(
        now.year,
        now.month - 1,
        salDay > DateTime(now.year, now.month, 0).day
            ? DateTime(now.year, now.month, 0).day
            : salDay,
      );
      nextSalary = DateTime(
        now.year,
        now.month,
        daysInPrevMonth < salDay ? daysInPrevMonth : salDay,
      );
    }

    daysUntilSalary.value = nextSalary.difference(now).inDays;

    final totalDays = nextSalary.difference(prevSalary).inDays;
    final elapsedDays = now.difference(prevSalary).inDays;
    salaryProgress.value = totalDays > 0
        ? (elapsedDays / totalDays).clamp(0.0, 1.0)
        : 0.0;
  }

  Future<void> _loadAnalytics() async {
    final now = DateTime.now();

    // Weekly (Ensure chronological order for charts)
    final weekStart = now.subtract(const Duration(days: 7));
    final weekLogs = await _repository.getLogsInRange(weekStart, now);
    weekLogs.sort((a, b) => a.date.compareTo(b.date));
    weeklyStats.assignAll(weekLogs);
    weeklyChartData.assignAll(weekLogs);

    // Monthly
    final monthStart = DateTime(now.year, now.month, 1);
    final monthLogs = await _repository.getLogsInRange(monthStart, now);
    monthlyStats.assignAll(monthLogs);

    // Yearly (Safe leap year handling: e.g., Feb 29 -> Feb 28 in non-leap years)
    final prevYear = now.year - 1;
    final maxDayInPrevYear = DateTime(prevYear, now.month + 1, 0).day;
    final safeDay = now.day > maxDayInPrevYear ? maxDayInPrevYear : now.day;
    final yearStart = DateTime(prevYear, now.month, safeDay);
    yearlyStats.assignAll(await _repository.getLogsInRange(yearStart, now));

    // Calculate Rate (Monthly Consistency Score)
    if (monthlyStats.isNotEmpty || profile.value.workingDays.isNotEmpty) {
      // ✅ Phase 3: Calculate proper expected working days
      int expectedWorkingDays = 0;
      for (
        var d = monthStart;
        d.isBefore(now.add(const Duration(days: 1)));
        d = d.add(const Duration(days: 1))
      ) {
        final dayIndex = d.weekday == 7 ? 0 : d.weekday;
        if (profile.value.workingDays.contains(dayIndex)) {
          expectedWorkingDays++;
        }
      }

      final presentCount = monthlyStats
          .where((l) => l.status == AttendanceStatus.present)
          .length;
      attendanceRate.value = expectedWorkingDays > 0
          ? (presentCount / expectedWorkingDays).clamp(0.0, 1.0)
          : 0.0;

      // ✅ Phase 3: Consistency Rate should NOT count absence or non-active leaves as positive unless specified. We strict it to present and holidays (paid leave).
      final consistentCount = monthlyStats
          .where(
            (l) =>
                l.status == AttendanceStatus.present ||
                l.status == AttendanceStatus.holiday,
          )
          .length;
      consistencyRate.value = expectedWorkingDays > 0
          ? (consistentCount / expectedWorkingDays).clamp(0.0, 1.0)
          : 0.0;
    } else {
      attendanceRate.value = 0.0;
      consistencyRate.value = 0.0;
    }

    // Comprehensive Summary
    final summary = <AttendanceStatus, int>{};
    for (var log in monthlyStats) {
      summary[log.status] = (summary[log.status] ?? 0) + 1;
    }
    statsSummary.assignAll(summary);
  }

  Future<void> logAttendance(
    AttendanceStatus status, {
    DateTime? date,
    String? note,
    bool isCheckOut = false,
  }) async {
    final targetDate = date ?? DateTime.now();
    final normalizedDate = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    final todayNormalized = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // 🛡️ HR Guard: Prevent future dates
    if (normalizedDate.isAfter(todayNormalized)) {
      talker.warning('⚠️ Cannot log attendance for future dates.');
      return;
    }

    final existing = await _repository.getLogForDate(normalizedDate);

    // 🛡️ HR Logic: Handle Check-In vs Check-Out
    DateTime? checkIn = existing?.checkInTime;
    DateTime? checkOut = existing?.checkOutTime;

    if (status == AttendanceStatus.present) {
      if (isCheckOut) {
        // ✅ Critical Fix: Prevent ghost check-out without check-in
        if (checkIn == null) {
          talker.warning('⚠️ Cannot check out without checking in first.');
          Get.snackbar('error'.tr, 'check_in_required'.tr);
          return;
        }
        checkOut = DateTime.now();
      } else {
        // ✅ Phase 3 Fix: Preserve existing check-in time. If manual retroactive log, keep it null for time accuracy instead of 12:00 AM.
        checkIn ??= (date == null ? DateTime.now() : null);
      }
    } else {
      checkIn = null;
      checkOut = null; // Non-present statuses clear time logs
    }

    final log = AttendanceLog(
      id: existing?.id ?? Isar.autoIncrement,
      date: normalizedDate,
      status: status,
      checkInTime: checkIn,
      checkOutTime: checkOut,
      note: note,
    );

    await _repository.logAttendance(log);

    if (normalizedDate.isAtSameMomentAs(todayNormalized)) {
      todayLog.value = log;
    }

    talker.info('📋 Attendance Logged for $normalizedDate: $status');
    _loadAnalytics();
  }

  Future<void> updateSettings({
    String? title,
    String? company,
    String? position,
    int? salDay,
    List<int>? workDays,
    int? startMin,
    int? endMin,
    bool? reminders,
    String? customSchedulesJson,
  }) async {
    final updated = profile.value.copyWith(
      jobTitle: title,
      companyName: company,
      jobPosition: position,
      salaryDay: salDay,
      workingDays: workDays,
      startMinutes: startMin,
      endMinutes: endMin,
      remindersEnabled: reminders,
      customSchedulesJson: customSchedulesJson,
    );

    try {
      await _repository.updateWorkProfile(updated);
      profile.value = updated;
      _calculateSalaryCountdown();

      if (updated.remindersEnabled) {
        await _scheduleShiftReminders(updated);
      } else {
        _cancelShiftReminders();
      }
      talker.info('⚙️ Job Profile updated successfully');
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Job Settings update failed');
    }
  }

  // Support for custom daily schedules
  Map<int, dynamic> getCustomSchedules() {
    if (profile.value.customSchedulesJson == null) return {};
    try {
      return jsonDecode(profile.value.customSchedulesJson!)
          as Map<int, dynamic>;
    } catch (_) {
      return {};
    }
  }

  void setCustomSchedule(int dayIndex, int? start, int? end) {
    final Map<String, dynamic> current =
        profile.value.customSchedulesJson != null
        ? jsonDecode(profile.value.customSchedulesJson!)
        : {};

    if (start == null && end == null) {
      current.remove(dayIndex.toString());
    } else {
      current[dayIndex.toString()] = {
        'start': start ?? profile.value.startMinutes,
        'end': end ?? profile.value.endMinutes,
      };
    }

    updateSettings(customSchedulesJson: jsonEncode(current));
  }

  int getStartMinutesForDay(int dayIndex) {
    final scheds = getCustomSchedules();
    if (scheds.containsKey(dayIndex.toString())) {
      return scheds[dayIndex.toString()]['start'];
    }
    return profile.value.startMinutes;
  }

  int getEndMinutesForDay(int dayIndex) {
    final scheds = getCustomSchedules();
    if (scheds.containsKey(dayIndex.toString())) {
      return scheds[dayIndex.toString()]['end'];
    }
    return profile.value.endMinutes;
  }

  Future<void> _scheduleShiftReminders(WorkProfile p) async {
    _cancelShiftReminders(); // Clear old ones first

    final service = Get.find<NotificationService>();

    for (var day in p.workingDays) {
      // ✅ Read distinct start minutes for this specific day using custom schedules logic
      final startMinGlobal = getStartMinutesForDay(day);

      // ✅ Suggestion: Notify 15 minutes before the shift begins
      final notifyMinutes = startMinGlobal - 15;
      final scheduleMin = notifyMinutes < 0 ? 0 : notifyMinutes;

      final startHour = scheduleMin ~/ 60;
      final startMin = scheduleMin % 60;

      // Logic: id = SHIFT_OFFSET + day
      await service.scheduleWeeklyNotification(
        id: NotificationService.SHIFT_OFFSET + day,
        title: 'job_reminder_title'.tr, // "Work Duty"
        body: 'job_reminder_msg'.trParams({
          'time': formatMinutes(startMinGlobal),
        }), // Tells actual shift time
        dayOfWeek: day == 0 ? 7 : day,
        hour: startHour,
        minute: startMin,
      );
    }
  }

  void _cancelShiftReminders() {
    final service = Get.find<NotificationService>();
    for (int i = 0; i <= 7; i++) {
      service.cancelNotification(NotificationService.SHIFT_OFFSET + i);
    }
  }

  String formatMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final anchor = DateTime(2000, 1, 1, hours, minutes);
    return DateFormat.jm(Get.locale?.languageCode).format(anchor);
  }
}
