import 'dart:convert';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/job_repository.dart';
import '../../../data/models/work_profile_model.dart';
import '../../../data/models/attendance_log_model.dart';
import '../../../core/helpers/log_helper.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/extensions/date_time_extensions.dart';

class JobController extends GetxController {
  final JobRepository _repository = Get.find<JobRepository>();

  final profile = WorkProfile().obs;
  final todayLog = Rxn<AttendanceLog>();
  
  // Analytics
  final weeklyStats = <AttendanceLog>[].obs;
  final monthlyStats = <AttendanceLog>[].obs;
  final yearlyStats = <AttendanceLog>[].obs;
  
  final daysUntilSalary = 0.obs;
  final attendanceRate = 0.0.obs;
  final isLoading = false.obs;
  
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
    
    final nextSalary = now.nextOccurrenceOfMonthDay(salDay);
    
    daysUntilSalary.value = nextSalary.difference(now.normalized).inDays;
  }

  Future<void> _loadAnalytics() async {
    final now = DateTime.now();
    
    // Weekly
    final weekStart = now.subtract(const Duration(days: 7));
    weeklyStats.assignAll(await _repository.getLogsInRange(weekStart, now));

    // Monthly
    final monthStart = DateTime(now.year, now.month, 1);
    monthlyStats.assignAll(await _repository.getLogsInRange(monthStart, now));

    // Yearly
    final yearStart = DateTime(now.year - 1, now.month, now.day);
    yearlyStats.assignAll(await _repository.getLogsInRange(yearStart, now));

    // Calculate Rate (Monthly)
    if (monthlyStats.isNotEmpty) {
      final presentCount = monthlyStats.where((l) => l.status == AttendanceStatus.present).length;
      attendanceRate.value = (presentCount / monthlyStats.length).clamp(0.0, 1.0);
    } else {
      attendanceRate.value = 0.0;
    }

    // Comprehensive Summary
    final summary = <AttendanceStatus, int>{};
    for (var log in monthlyStats) {
      summary[log.status] = (summary[log.status] ?? 0) + 1;
    }
    statsSummary.assignAll(summary);
  }

  Future<void> logAttendance(AttendanceStatus status, {DateTime? date, String? note, bool isCheckOut = false}) async {
    final targetDate = date ?? DateTime.now();
    final normalizedDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final todayNormalized = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    
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
        checkIn ??= DateTime.now();
        checkOut = DateTime.now();
      } else {
        checkIn = date != null ? targetDate : DateTime.now(); // Retain precise time if selected manually, otherwise now
      }
    } else {
      checkIn = null;
      checkOut = null; // Non-present statuses clear time logs
    }
    
    final log = AttendanceLog(
      id: existing?.id ?? 0,
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
      return jsonDecode(profile.value.customSchedulesJson!) as Map<int, dynamic>;
    } catch (_) {
      return {};
    }
  }

  void setCustomSchedule(int dayIndex, int? start, int? end) {
    final Map<String, dynamic> current = profile.value.customSchedulesJson != null 
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
    
    final service = NotificationService();
    
    for (var day in p.workingDays) {
      // ✅ Read distinct start minutes for this specific day using custom schedules logic
      final startMinGlobal = getStartMinutesForDay(day);
      
      // ✅ Suggestion: Notify 15 minutes before the shift begins
      final notifyMinutes = startMinGlobal - 15;
      final scheduleMin = notifyMinutes < 0 ? 0 : notifyMinutes;
      
      final startHour = scheduleMin ~/ 60;
      final startMin = scheduleMin % 60;
      
      // Logic: id = 1000 + day
      await service.scheduleWeeklyNotification( 
        id: 1000 + day,
        title: 'job_reminder_title'.tr, // "Work Duty"
        body: 'job_reminder_msg'.trParams({'time': formatMinutes(startMinGlobal)}), // Tells actual shift time
        dayOfWeek: day == 0 ? 7 : day, 
        hour: startHour,
        minute: startMin,
      );
    }
  }

  void _cancelShiftReminders() {
    final service = NotificationService();
    for (int i = 0; i <= 7; i++) {
       service.cancelNotification(1000 + i);
    }
  }

  String formatMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}
