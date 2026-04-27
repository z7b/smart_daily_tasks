import 'dart:convert';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/job_repository.dart';
import '../../../data/models/work_profile_model.dart';
import '../../../data/models/attendance_log_model.dart';
import '../../../core/helpers/log_helper.dart';
import 'package:smart_daily_tasks/app/core/services/notification_service.dart';
import 'package:smart_daily_tasks/app/core/helpers/number_extension.dart';

import 'package:isar/isar.dart';

enum JobAnalyticsPeriod { weekly, monthly, yearly }

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
  
  final selectedPeriod = JobAnalyticsPeriod.monthly.obs;
  final selectedYear = DateTime.now().year.obs;
  final availableYears = <int>[].obs;
  
  final avgCheckInTime = ''.obs;
  final avgVarianceMinutes = 0.obs;
  final totalWorkMinutes = 0.obs;
  final performanceInsight = ''.obs;
  final totalActiveDays = 0.obs;
  final totalMandatedDays = 0.obs; // ✅ Phase 8 Audit: Official target days from settings
  
  // ✅ Phase 8: Work Governance Metrics
  final expectedCheckOut = ''.obs;
  final workBalanceMinutes = 0.obs; // Surplus or deficit vs official hours
  
  final isLoading = false.obs;

  // Weekly Chart Data (Sorted)
  final weeklyChartData = <AttendanceLog>[].obs;
  final aggregatedChartData = <Map<String, dynamic>>[].obs;

  // Statistical Summaries
  final statsSummary = <AttendanceStatus, int>{}.obs;

  // ✅ Employment State Architecture
  EmploymentStatus get employmentStatus => profile.value.employmentStatus;
  bool get isEmployed => employmentStatus == EmploymentStatus.employed;
  bool get isUnemployed => employmentStatus == EmploymentStatus.unemployed;
  bool get isNotConfigured => employmentStatus == EmploymentStatus.notConfigured;

  @override
  void onInit() {
    super.onInit();
    refreshData();
  }

  Future<void> refreshData() async {
    try {
      isLoading.value = true;
      profile.value = await _repository.getWorkProfile();

      // ✅ Auto-migration: Existing users with job data → upgrade to employed
      if (isNotConfigured && _hasExistingJobData()) {
        final migrated = profile.value.copyWith(employmentStatus: EmploymentStatus.employed);
        await _repository.updateWorkProfile(migrated);
        profile.value = migrated;
        talker.info('🔄 Auto-migrated existing job profile to Employed status');
      }

      // ✅ Guard: Only run calculations for employed users
      if (!isEmployed) {
        _resetAllMetrics();
        return;
      }

      final now = DateTime.now();
      todayLog.value = await _repository.getLogForDate(now);

      availableYears.assignAll(await _repository.getAvailableYears());
      if (!availableYears.contains(selectedYear.value)) {
        selectedYear.value = now.year;
      }

      _calculateSalaryCountdown();
      await _loadAnalytics();
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 JobController Refresh Error');
    } finally {
      isLoading.value = false;
    }
  }

  bool _hasExistingJobData() {
    final p = profile.value;
    return (p.jobTitle != null && p.jobTitle!.isNotEmpty) ||
           (p.companyName != null && p.companyName!.isNotEmpty);
  }

  void _resetAllMetrics() {
    todayLog.value = null;
    weeklyStats.clear();
    monthlyStats.clear();
    yearlyStats.clear();
    weeklyChartData.clear();
    aggregatedChartData.clear();
    statsSummary.clear();
    daysUntilSalary.value = 0;
    salaryProgress.value = 0.0;
    attendanceRate.value = 0.0;
    consistencyRate.value = 0.0;
    avgCheckInTime.value = '--:--';
    avgVarianceMinutes.value = 0;
    totalWorkMinutes.value = 0;
    totalActiveDays.value = 0;
    totalMandatedDays.value = 0;
    workBalanceMinutes.value = 0;
    expectedCheckOut.value = '--:--';
    performanceInsight.value = '';
  }

  /// Transition to Employed state
  Future<void> setEmployed() async {
    final updated = profile.value.copyWith(employmentStatus: EmploymentStatus.employed);
    await _repository.updateWorkProfile(updated);
    profile.value = updated;
    talker.info('✅ Employment status → Employed');
    refreshData();
  }

  /// Transition to Unemployed state
  Future<void> setUnemployed() async {
    final updated = profile.value.copyWith(employmentStatus: EmploymentStatus.unemployed);
    await _repository.updateWorkProfile(updated);
    profile.value = updated;
    _cancelShiftReminders();
    _resetAllMetrics();
    talker.info('⚠️ Employment status → Unemployed');
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

    if (salDay > daysInPrevMonth) {
      prevSalary = DateTime(now.year, now.month, daysInPrevMonth);
    }
    if (salDay > daysInNextMonth) {
      nextSalary = DateTime(now.year, now.month + 1, daysInNextMonth);
    }

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

    // Weekly
    final weekStart = now.subtract(const Duration(days: 6));
    final weekLogs = await _repository.getLogsInRange(weekStart, now);
    weekLogs.sort((a, b) => a.date.compareTo(b.date));
    weeklyStats.assignAll(weekLogs);
    weeklyChartData.assignAll(weekLogs);

    // Monthly
    final monthStart = DateTime(now.year, now.month, 1);
    final monthLogs = await _repository.getLogsInRange(monthStart, now);
    monthlyStats.assignAll(monthLogs);

    // Yearly (Historical or Rolling)
    if (selectedPeriod.value == JobAnalyticsPeriod.yearly) {
      final yearStart = DateTime(selectedYear.value, 1, 1);
      final yearEnd = DateTime(selectedYear.value, 12, 31);
      yearlyStats.assignAll(await _repository.getLogsInRange(yearStart, yearEnd));
    } else {
      // Background rolling year load for global metrics
      final yearStart = DateTime(now.year - 1, now.month, now.day);
      yearlyStats.assignAll(await _repository.getLogsInRange(yearStart, now));
    }

    availableYears.assignAll(await _repository.getAvailableYears());
    _calculatePeriodStats();
  }

  void setPeriod(JobAnalyticsPeriod period) {
    selectedPeriod.value = period;
    _loadAnalytics(); // Reload to handle potential range changes (Yearly Calendar vs Rolling)
  }

  void setYear(int year) {
    selectedYear.value = year;
    if (selectedPeriod.value == JobAnalyticsPeriod.yearly) {
      _loadAnalytics();
    }
  }

  void _calculatePeriodStats() {
    final now = DateTime.now();
    List<AttendanceLog> currentLogs = [];
    DateTime periodStart;
    DateTime periodEnd = now;

    switch (selectedPeriod.value) {
      case JobAnalyticsPeriod.weekly:
        periodStart = now.subtract(const Duration(days: 6));
        currentLogs = weeklyStats;
        _aggregateWeeklyData(currentLogs);
        break;
      case JobAnalyticsPeriod.monthly:
        periodStart = DateTime(now.year, now.month, 1);
        currentLogs = monthlyStats;
        _aggregateMonthlyByWeek(currentLogs, periodStart, now);
        break;
      case JobAnalyticsPeriod.yearly:
        periodStart = DateTime(selectedYear.value, 1, 1);
        periodEnd = selectedYear.value == now.year ? now : DateTime(selectedYear.value, 12, 31);
        currentLogs = yearlyStats;
        _aggregateYearlyData(currentLogs, selectedYear.value);
        break;
    }

    // 1. Metric Summary
    final summary = <AttendanceStatus, int>{};
    for (var log in currentLogs) {
      summary[log.status] = (summary[log.status] ?? 0) + 1;
    }
    statsSummary.assignAll(summary);
    totalActiveDays.value = currentLogs.length;

    // 2. Average Check-in Time
    final checkInLogs = currentLogs.where((l) => l.checkInTime != null).toList();
    if (checkInLogs.isNotEmpty) {
      int totalMinutes = 0;
      for (var log in checkInLogs) {
        totalMinutes += log.checkInTime!.hour * 60 + log.checkInTime!.minute;
      }
      final avgMinutes = totalMinutes ~/ checkInLogs.length;
      avgCheckInTime.value = formatMinutes(avgMinutes);
    } else {
      avgCheckInTime.value = '--:--';
    }

    // 3. Performance & Shift Variance logic
    // ✅ Phase 10 Audit: Calculate expected working days and EXACT expected minutes
    int expectedWorkingDays = 0;
    int expectedPeriodMinutes = 0;
    
    DateTime pStart = DateTime(periodStart.year, periodStart.month, periodStart.day);
    DateTime pEnd = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);

    for (var d = pStart; d.isBefore(pEnd.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
      final dayIndex = d.weekday == 7 ? 0 : d.weekday;
      if (profile.value.workingDays.contains(dayIndex) && !isDayHoliday(dayIndex)) {
        expectedWorkingDays++;
        
        final shifts = getShiftsForDay(dayIndex);
        for (var s in shifts) {
          final start = s['start'] as int;
          final end = s['end'] as int;
          expectedPeriodMinutes += end >= start ? (end - start) : ((24 * 60 - start) + end);
        }
      }
    }
    
    totalMandatedDays.value = expectedWorkingDays;

    _calculateAdvancedMetrics(currentLogs, expectedWorkingDays, expectedPeriodMinutes);

    // 4. Consistency Rate logic
    _updateConsistencyMetrics(expectedWorkingDays, currentLogs);
  }

  void _aggregateWeeklyData(List<AttendanceLog> logs) {
    final List<Map<String, dynamic>> results = [];
    for (var log in logs) {
      results.add({
        'label': DateFormat.E(Get.locale?.languageCode).format(log.date),
        'value': log.status == AttendanceStatus.present ? 1.0 : (log.status == AttendanceStatus.holiday ? 0.8 : 0.2),
        'date': log.date,
      });
    }
    aggregatedChartData.assignAll(results);
  }

  void _aggregateMonthlyByWeek(List<AttendanceLog> logs, DateTime start, DateTime end) {
    final List<Map<String, dynamic>> results = [];
    
    // Bin by 7-day windows
    for (int i = 0; i < 5; i++) {
      final binStart = start.add(Duration(days: i * 7));
      if (binStart.isAfter(end) && i > 0) break;
      
      final binEnd = binStart.add(const Duration(days: 6));
      final binLogs = logs.where((l) => (l.date.isAfter(binStart) || l.date.isAtSameMomentAs(binStart)) && 
                                        (l.date.isBefore(binEnd) || l.date.isAtSameMomentAs(binEnd))).toList();
      
      int presentCount = binLogs.where((l) => l.status == AttendanceStatus.present).length;
      double rate = binLogs.isNotEmpty ? presentCount / binLogs.length : 0.0;

      results.add({
        'label': '${'week'.tr} ${i + 1}',
        'value': rate,
        'date': binStart,
      });
    }
    aggregatedChartData.assignAll(results);
  }

  void _aggregateYearlyData(List<AttendanceLog> logs, int year) {
    // Generate 12 months for the selected year
    final List<Map<String, dynamic>> calendarResults = [];
    
    for (int month = 1; month <= 12; month++) {
      final monthDate = DateTime(year, month, 1);
      final monthLogs = logs.where((l) => l.date.month == month && l.date.year == year).toList();
      
      final presentCount = monthLogs.where((l) => l.status == AttendanceStatus.present).length;
      final rate = monthLogs.isNotEmpty ? presentCount / monthLogs.length : 0.0;
      
      calendarResults.add({
        'label': DateFormat.MMM(Get.locale?.languageCode).format(monthDate),
        'value': rate,
        'date': monthDate,
      });
    }
    
    aggregatedChartData.assignAll(calendarResults);
  }

  void _calculateAdvancedMetrics(List<AttendanceLog> logs, int periodExpectedDays, int expectedPeriodMinutes) {
    int totalVariance = 0;
    int varianceCount = 0;
    int totalDuration = 0;

    for (var log in logs) {
      if (log.status == AttendanceStatus.present && log.checkInTime != null) {
        // Calculate Expected Start for that specific day
        final dayIndex = log.date.weekday == 7 ? 0 : log.date.weekday;
        final expectedStartMin = getStartMinutesForDay(dayIndex);
        final actualStartMin = log.checkInTime!.hour * 60 + log.checkInTime!.minute;
        
        totalVariance += (actualStartMin - expectedStartMin);
        varianceCount++;

        if (log.checkOutTime != null) {
          totalDuration += log.checkOutTime!.difference(log.checkInTime!).inMinutes;
        } else {
          final now = DateTime.now();
          if (log.date.year == now.year && log.date.month == now.month && log.date.day == now.day) {
            totalDuration += now.difference(log.checkInTime!).inMinutes;
          }
        }
      }
    }

    avgVarianceMinutes.value = varianceCount > 0 ? (totalVariance ~/ varianceCount) : 0;
    totalWorkMinutes.value = totalDuration;

    // ✅ Phase 10 Audit: Strict Dynamic Work Balance
    // Benchmark against dynamically accumulated 'expectedPeriodMinutes' to ensure math logic respecs custom UI limits
    workBalanceMinutes.value = totalDuration - expectedPeriodMinutes;

    // ✅ Phase 8: Today's Predictive Exit
    _calculateTodayPredictiveExit();

    // 5. Generate Insight
    _generateInsight(varianceCount);
  }

  void _calculateTodayPredictiveExit() {
    if (todayLog.value != null && todayLog.value!.checkInTime != null) {
      final checkIn = todayLog.value!.checkInTime!;
      final dayIndex = checkIn.weekday == 7 ? 0 : checkIn.weekday;
      
      final shifts = getShiftsForDay(dayIndex);
      int spanMinutes = 8 * 60; // fallback
      if (shifts.isNotEmpty) {
        final firstStart = shifts.first['start'] as int;
        final lastEnd = shifts.last['end'] as int;
        spanMinutes = lastEnd >= firstStart ? (lastEnd - firstStart) : ((24 * 60 - firstStart) + lastEnd);
      }
      
      final expectedExitTime = checkIn.add(Duration(minutes: spanMinutes));
      
      expectedCheckOut.value = DateFormat.jm(Get.locale?.languageCode).format(expectedExitTime).f;
    } else {
      expectedCheckOut.value = '--:--';
    }
  }

  void _generateInsight(int varianceCount) {
    if (attendanceRate.value > 0.9 && avgVarianceMinutes.value <= 5) {
      performanceInsight.value = 'insight_good'.tr;
    } else if (avgVarianceMinutes.value > 15) {
      performanceInsight.value = 'insight_late'.tr;
    } else if (avgVarianceMinutes.value < -5) {
      performanceInsight.value = 'insight_early'.tr;
    } else {
      performanceInsight.value = 'insight_good'.tr;
    }
  }

  void _updateConsistencyMetrics(int expectedWorkingDays, List<AttendanceLog> logs) {
    if (expectedWorkingDays > 0) {
      final presentCount = logs.where((l) => l.status == AttendanceStatus.present).length;
      attendanceRate.value = (presentCount / expectedWorkingDays).clamp(0.0, 1.0);

      final consistentCount = logs.where((l) => 
        l.status == AttendanceStatus.present || l.status == AttendanceStatus.holiday
      ).length;
      consistencyRate.value = (consistentCount / expectedWorkingDays).clamp(0.0, 1.0);
    } else {
      attendanceRate.value = 0.0;
      consistencyRate.value = 0.0;
    }
  }

  Future<void> logAttendance(
    AttendanceStatus status, {
    DateTime? date,
    String? note,
    bool isCheckOut = false,
  }) async {
    // ✅ Employment Guard: Block attendance for non-employed users
    if (!isEmployed) {
      talker.warning('⚠️ Cannot log attendance: User is not employed.');
      return;
    }

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

  Future<void> updateJobSettings({
    EmploymentStatus? employmentStatus,
    String? title,
    String? company,
    String? position,
    int? salDay,
    List<int>? workDays,
    int? startMin,
    int? endMin,
    bool? reminders,
    String? customSchedulesJson,
    double? officialWorkHours,
  }) async {
    final updated = profile.value.copyWith(
      employmentStatus: employmentStatus,
      jobTitle: title,
      companyName: company,
      jobPosition: position,
      salaryDay: salDay,
      workingDays: workDays,
      startMinutes: startMin,
      endMinutes: endMin,
      remindersEnabled: reminders,
      customSchedulesJson: customSchedulesJson,
      officialWorkHours: officialWorkHours,
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
  Map<String, dynamic> getCustomSchedules() {
    if (profile.value.customSchedulesJson == null) return {};
    try {
      return jsonDecode(profile.value.customSchedulesJson!)
          as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  bool isDayHoliday(int dayIndex) {
    final scheds = getCustomSchedules();
    if (scheds.containsKey(dayIndex.toString())) {
      return scheds[dayIndex.toString()]['isHoliday'] ?? false;
    }
    return false;
  }

  List<Map<String, dynamic>> getShiftsForDay(int dayIndex) {
    final scheds = getCustomSchedules();
    if (scheds.containsKey(dayIndex.toString())) {
      final dayData = scheds[dayIndex.toString()];
      if (dayData['shifts'] != null) {
        return List<Map<String, dynamic>>.from(dayData['shifts']);
      }
      if (dayData['start'] != null && dayData['end'] != null) {
        return [{'start': dayData['start'], 'end': dayData['end']}];
      }
    }
    return [{'start': profile.value.startMinutes, 'end': profile.value.endMinutes}];
  }

  void setCustomShifts(int dayIndex, List<Map<String, dynamic>>? shifts, {bool? isHoliday}) {
    final Map<String, dynamic> current =
        profile.value.customSchedulesJson != null
        ? jsonDecode(profile.value.customSchedulesJson!)
        : {};

    if (shifts == null && isHoliday == null) {
      current.remove(dayIndex.toString());
    } else {
      final existingHoliday = isDayHoliday(dayIndex);
      final finalShifts = shifts ?? getShiftsForDay(dayIndex);
      
      current[dayIndex.toString()] = {
        'start': finalShifts.isNotEmpty ? finalShifts.first['start'] : profile.value.startMinutes,
        'end': finalShifts.isNotEmpty ? finalShifts.last['end'] : profile.value.endMinutes,
        'shifts': finalShifts,
        'isHoliday': isHoliday ?? existingHoliday,
      };
    }

    updateJobSettings(customSchedulesJson: jsonEncode(current));
  }

  // Backwards compatibility for UI and variance algorithms
  void setCustomSchedule(int dayIndex, int? start, int? end, {bool? isHoliday}) {
    if (start == null && end == null) {
      setCustomShifts(dayIndex, null, isHoliday: isHoliday);
    } else {
      setCustomShifts(dayIndex, [{'start': start ?? profile.value.startMinutes, 'end': end ?? profile.value.endMinutes}], isHoliday: isHoliday);
    }
  }

  int getStartMinutesForDay(int dayIndex) {
    final shifts = getShiftsForDay(dayIndex);
    if (shifts.isNotEmpty) return (shifts.first['start'] as num).toInt();
    return profile.value.startMinutes;
  }

  int getEndMinutesForDay(int dayIndex) {
    final shifts = getShiftsForDay(dayIndex);
    if (shifts.isNotEmpty) return (shifts.last['end'] as num).toInt();
    return profile.value.endMinutes;
  }

  /// ✅ Phase 11: Future Shift Predictive Engine
  /// Scans the upcoming 7 calendar days to pinpoint the exact time of the next active shift.
  Map<String, dynamic>? getNextShiftDetails() {
    try {
      final now = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final d = now.add(Duration(days: i));
        final dayIndex = d.weekday == 7 ? 0 : d.weekday;
        
        if (!profile.value.workingDays.contains(dayIndex) || isDayHoliday(dayIndex)) {
          continue;
        }

        final shifts = getShiftsForDay(dayIndex);
        if (shifts.isEmpty) continue;

        for (var s in shifts) {
          final startMin = (s['start'] as num?)?.toInt() ?? profile.value.startMinutes;
          final endMin = (s['end'] as num?)?.toInt() ?? profile.value.endMinutes;
          
          final shiftStart = DateTime(d.year, d.month, d.day, startMin ~/ 60, startMin % 60);
          final shiftEnd = DateTime(d.year, d.month, d.day, endMin ~/ 60, endMin % 60);

          if (now.isBefore(shiftEnd)) {
             return {
               'date': d,
               'start': shiftStart,
               'end': shiftEnd,
               'isActive': now.isAfter(shiftStart) && now.isBefore(shiftEnd)
             };
          }
        }
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🟠 Predictive Shift Engine Error');
    }
    return null; 
  }

  Future<void> _scheduleShiftReminders(WorkProfile p) async {
    _cancelShiftReminders(); // Clear old ones first

    final service = Get.find<NotificationService>();

    for (var day in p.workingDays) {
      if (isDayHoliday(day)) continue; // 🛡️ Skip notifications for holidays
      // ✅ Read distinct start minutes for this specific day using custom schedules logic
      final startMinGlobal = getStartMinutesForDay(day);

      // ✅ Suggestion: Notify 15 minutes before the shift begins
      final notifyMinutes = startMinGlobal - 15;
      final scheduleMin = notifyMinutes < 0 ? 0 : notifyMinutes;

      final startHour = scheduleMin ~/ 60;
      final startMin = scheduleMin % 60;

      // Logic: id = SHIFT_OFFSET + day
      await service.scheduleWeeklyNotification(
        id: NotificationService.shiftOffset + day,
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
      service.cancelNotification(NotificationService.shiftOffset + i);
    }
  }

  String formatMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final anchor = DateTime(2000, 1, 1, hours, minutes);
    return DateFormat.jm(Get.locale?.languageCode).format(anchor);
  }
}
