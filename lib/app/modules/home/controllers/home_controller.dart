import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:smart_daily_tasks/app/core/helpers/log_helper.dart';
import 'package:smart_daily_tasks/app/core/extensions/date_time_extensions.dart';
import 'package:smart_daily_tasks/app/core/services/app_lock_observer.dart';

import 'package:smart_daily_tasks/app/data/models/task_model.dart';
import 'package:smart_daily_tasks/app/data/models/note_model.dart';
import 'package:smart_daily_tasks/app/data/models/journal_model.dart';
import 'package:smart_daily_tasks/app/data/models/bookmark_model.dart';
import 'package:smart_daily_tasks/app/data/models/calendar_event_model.dart';
import 'package:smart_daily_tasks/app/data/models/book_model.dart';
import 'package:smart_daily_tasks/app/data/models/medication_model.dart';
import 'package:smart_daily_tasks/app/data/models/step_log_model.dart';
import 'package:smart_daily_tasks/app/data/models/work_profile_model.dart';
import 'package:smart_daily_tasks/app/data/models/attendance_log_model.dart';
import 'package:smart_daily_tasks/app/data/services/health_service.dart';
import 'package:smart_daily_tasks/app/routes/app_pages.dart';

class HomeController extends GetxController {
  final _isar = Get.find<Isar>();
  final _healthService = Get.find<HealthService>();
  
  StreamSubscription? _taskSub;
  StreamSubscription? _journalSub;
  StreamSubscription? _bookmarkSub;
  StreamSubscription? _bookSub;
  StreamSubscription? _stepLogSub;
  StreamSubscription? _attendanceSub;
  Timer? _pulseTimer;

  // UI State
  final greetingKey = 'greet_morning'.obs;
  final greetingMsg = 'msg_morning'.obs;
  final currentIndex = 0.obs;
  final selectedDate = DateTime.now().obs;

  // Real-time Database Counts
  final taskCount = 0.obs;
  final noteCount = 0.obs;
  final journalCount = 0.obs;
  final bookmarkCount = 0.obs;
  final medicationCount = 0.obs;
  final calendarEventCount = 0.obs;
  final bookCount = 0.obs;
  
  // Progress Pillars (Doctoral Logic: Symmetry & Balance)
  final mindProgress = 0.0.obs;
  final bodyProgress = 0.0.obs;
  final spiritProgress = 0.0.obs;
  final progressPercentage = 0.0.obs;
  final tasksLeftCount = 0.obs;

  // Mood Analysis Stats
  final weeklyMoodTrend = 'neutral'.obs;
  final moodEmoji = '😐'.obs;

  // Reading Progress Data
  final weeklyReadingData = <double>[0, 0, 0, 0, 0, 0, 0].obs;
  final currentBookTitle = 'No active book'.obs;
  final currentBookProgress = 0.0.obs;

  // Activity & Stats
  final completedDays = <DateTime>{}.obs;
  final weeklyData = <int>[0, 0, 0, 0, 0, 0, 0].obs;
  
  // Job & Salary
  final daysUntilSalary = 0.obs;
  final workCompany = ''.obs;
  final workPosition = ''.obs;

  // Health Stats
  final stepsCount = 0.obs;
  final stepsGoal = 10000.obs;
  final stepsProgress = 0.0.obs;

  final medTakenDoses = 0.obs;
  final medExpectedDoses = 0.obs;
  final nextMedicationTime = ''.obs;
  final nextMedicationName = ''.obs;
  final nextMedicationTimeLeft = ''.obs;
  
  // Next Task Stats
  final nextTaskTitle = ''.obs;
  final nextTaskTime = ''.obs;
  final nextTaskEndTime = ''.obs;
  final nextTaskTimeLeft = ''.obs;
  final nextTaskFullDate = ''.obs;
  final nextTaskPriority = TaskPriority.medium.obs;

  final weeklyLabels = <String>[].obs;

  void refreshDashboard() {
    _healthService.fetchAndPersistSteps(); // Sync health data on manual refresh
    _loadRealData();
  }
  
  void connectHealth() async {
    final success = await _healthService.requestPermissions();
    if (success) {
      _loadRealData();
    }
  }

  @override
  void onInit() {
    super.onInit();
    _updateGreeting();
    _setupRealtimeListeners();
    // ✅ Defer heavy DB work to the next frame to avoid ANR on startup
    Future.delayed(const Duration(milliseconds: 100), () => _loadRealData());
  }

  @override
  void onReady() {
    super.onReady();
    
    // 🛡️ Enforce Cold Boot Security Locks
    if (Get.isRegistered<AppLockObserver>()) {
      Get.find<AppLockObserver>().enforceColdBootLock();
    }

    // ✅ Doctoral Logic: Navigation Governance
    // Push the user-configured Start Screen *over* HomeView.
    // This allows the Back button to gracefully return to the underlying Dashboard.
    final startRoute = AppPages.savedStartRoute;
    if (startRoute != null) {
      Get.toNamed(startRoute);
    }
  }

  @override
  void onClose() {
    _taskSub?.cancel();
    _journalSub?.cancel();
    _bookmarkSub?.cancel();
    _bookSub?.cancel();
    _stepLogSub?.cancel();
    _attendanceSub?.cancel();
    _pulseTimer?.cancel();
    super.onClose();
  }

  void _setupRealtimeListeners() {
    // ✅ Debounce DB listeners to prevent rapid UI rebuilds during batch ops
    _taskSub = _isar.tasks.watchLazy()
        .debounceTime(const Duration(milliseconds: 500))
        .listen((_) => _loadRealData());
    
    // ✅ Step 2: Set the Pulse (Life OS Heartbeat)
    // Refreshes the dashboard stats and greetings automatically
    _pulseTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateGreeting();
      _loadRealData();
    });
        
    _journalSub = _isar.journals.watchLazy()
        .debounceTime(const Duration(milliseconds: 500))
        .listen((_) => _loadRealData());
        
    _bookmarkSub = _isar.bookmarks.watchLazy()
        .debounceTime(const Duration(milliseconds: 500))
        .listen((_) => _loadRealData());
        
    _bookSub = _isar.books.watchLazy()
        .debounceTime(const Duration(milliseconds: 500))
        .listen((_) => _loadRealData());

    _isar.medications.watchLazy()
        .debounceTime(const Duration(milliseconds: 500))
        .listen((_) => _loadRealData());

    _stepLogSub = _isar.stepLogs.watchLazy()
        .debounceTime(const Duration(milliseconds: 500))
        .listen((_) => _loadRealData());

    _attendanceSub = _isar.attendanceLogs.watchLazy()
        .debounceTime(const Duration(milliseconds: 500))
        .listen((_) => _loadRealData());
  }

  /// ✅ Doctoral Logic: Dynamic Greeting Engine based on Time & Spirit
  void _updateGreeting() {
    final hour = DateTime.now().hour;
    final random = Random();
    
    if (hour >= 3 && hour < 6) {
      greetingKey.value = 'greet_dawn';
      greetingMsg.value = 'msg_dawn';
    } else if (hour >= 6 && hour < 12) {
      greetingKey.value = 'greet_morning';
      greetingMsg.value = random.nextBool() ? 'msg_morning' : 'msg_smile';
    } else if (hour >= 12 && hour < 16) {
      greetingKey.value = 'greet_afternoon';
      greetingMsg.value = 'msg_afternoon';
    } else if (hour >= 16 && hour < 20) {
      greetingKey.value = 'greet_evening';
      greetingMsg.value = random.nextBool() ? 'msg_evening' : 'msg_dhikr';
    } else {
      greetingKey.value = 'greet_night';
      greetingMsg.value = 'msg_night';
    }

    // ✅ Doctoral Integration: Contextual Praise based on real progress
    _applyAchievementContext();
  }

  void _applyAchievementContext() {
    // If progress is very high, give standard high-performance praise
    if (progressPercentage.value >= 0.9) {
      greetingMsg.value = 'msg_high_performance';
    } 
    // Medical excellence check: if meds are done (and there were any)
    else if (medicationCount.value > 0 && progressPercentage.value > 0.5) {
       // We can add more specific keys here if needed
    }
  }

  Future<void> _loadRealData() async {
    try {
      // Logic: Only load from Isar here. 
      // Health syncing is handled by the initial pulse and manual refresh to avoid infinite loops.
      taskCount.value = await _isar.tasks.count();
      noteCount.value = await _isar.notes.count();
      journalCount.value = await _isar.journals.count();
      bookmarkCount.value = await _isar.bookmarks.count();
      medicationCount.value = await _isar.medications.count();
      calendarEventCount.value = await _isar.calendarEvents.count();
      bookCount.value = await _isar.books.count();

      final date = selectedDate.value;
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // 1. Task Progress (50%)
      final dayTasks = await _isar.tasks
          .filter()
          .scheduledAtBetween(startOfDay, endOfDay, includeLower: true, includeUpper: false)
          .findAll();
      final int total = dayTasks.length;
      final int completed = dayTasks.where((t) => t.status == TaskStatus.completed).length;
      final double taskProgress = total > 0 ? (completed / total) : 1.0; // 1.0 if no tasks
      
      // 2. Health Progress (30%) - Medication Adherence
      final allMeds = await _isar.medications.filter().isActiveEqualTo(true).findAll();
      int expected = 0;
      int taken = 0;
      final viewDate = selectedDate.value;
      final isToday = viewDate.isSameDay(DateTime.now());

      for (var med in allMeds) {
        // Check if med was active on the selected date
        if (viewDate.isAfter(med.startDate.subtract(const Duration(days: 1))) && 
           (med.endDate == null || viewDate.isBefore(med.endDate!.add(const Duration(days: 1))))) {
          
          expected += med.reminderTimes.length;
          for (var intake in med.intakeHistory) {
             if (intake.isSameDay(viewDate)) {
               taken++;
             }
          }
        }
      }
      medTakenDoses.value = taken;
      medExpectedDoses.value = expected;

      // Calculate Next Dose Time (Only relevant for today or future)
      nextMedicationTime.value = '';
      nextMedicationName.value = '';
      nextMedicationTimeLeft.value = '';
      
      if (viewDate.isSameDay(DateTime.now()) || viewDate.isAfter(DateTime.now())) {
        DateTime? nextDoseDateTime;
        String nextDoseName = '';
        String nextDoseTimeStr = '';
        final now = DateTime.now();

        for (var med in allMeds) {
          if (viewDate.isAfter(med.startDate.subtract(const Duration(days: 1))) && 
             (med.endDate == null || viewDate.isBefore(med.endDate!.add(const Duration(days: 1))))) {
            
            for (var timeStr in med.reminderTimes) {
              try {
                 final time = _parseRobustTime(timeStr);
                 var scheduledDate = DateTime(viewDate.year, viewDate.month, viewDate.day, time.hour, time.minute);
                 
                 // if viewing today and time already passed, its next occurrence is tomorrow
                 // if viewing future, we just take the time.
                 if (isToday && scheduledDate.isBefore(now)) {
                   continue; // Skip past doses today
                 }
                 
                 // Find the closest upcoming dose
                 if (nextDoseDateTime == null || scheduledDate.isBefore(nextDoseDateTime)) {
                   nextDoseDateTime = scheduledDate;
                   nextDoseName = med.name;
                   nextDoseTimeStr = timeStr;
                 }
              } catch (e) {
                 // ignore parsing errors
              }
            }
          }
        }
        
        if (nextDoseDateTime != null) {
          nextMedicationTime.value = nextDoseTimeStr;
          nextMedicationName.value = nextDoseName;
          
          final diff = nextDoseDateTime.difference(now);
          final hours = diff.inHours;
          final minutes = diff.inMinutes % 60;
          
          if (hours > 0 || diff.inDays > 0) {
            nextMedicationTimeLeft.value = '${hours}h ${minutes}m';
          } else {
            nextMedicationTimeLeft.value = '${minutes}m';
          }
        }
      }

      // --- Doctoral Logic: Task Next Item Tracking ---
      nextTaskTitle.value = '';
      nextTaskTime.value = '';
      nextTaskTimeLeft.value = '';

      if (viewDate.isSameDay(DateTime.now()) || viewDate.isAfter(DateTime.now())) {
        final now = DateTime.now();
        final upcomingTasks = dayTasks
            .where((t) => t.status == TaskStatus.active)
            .toList();
        
        if (upcomingTasks.isNotEmpty) {
          upcomingTasks.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
          final nextTask = upcomingTasks.first;
          
          nextTaskTitle.value = nextTask.title;
          nextTaskTime.value = DateFormat.jm().format(nextTask.scheduledAt);
          nextTaskEndTime.value = nextTask.scheduledEnd != null ? DateFormat.jm().format(nextTask.scheduledEnd!) : '';
          nextTaskPriority.value = nextTask.priority;
          nextTaskFullDate.value = DateFormat('dd MMMM yyyy').format(nextTask.scheduledAt) + ' • ' + nextTaskTime.value;
          
          final diff = nextTask.scheduledAt.difference(now);
          if (diff.isNegative) {
            final hours = diff.inHours.abs();
            final minutes = diff.inMinutes.abs() % 60;
            // Negative time denotes overdue/debt time
            nextTaskTimeLeft.value = '-${hours > 0 ? '${hours}h ' : ''}${minutes}m';
          } else {
            final hours = diff.inHours;
            final minutes = diff.inMinutes % 60;
            
            if (hours > 0 || diff.inDays > 0) {
               nextTaskTimeLeft.value = '${hours}h ${minutes}m';
            } else {
               nextTaskTimeLeft.value = '${minutes}m';
            }
          }
        }
      }

      final double medProgress = expected > 0 ? (taken / expected).clamp(0.0, 1.0) : 1.0;

      // 3. Mind Progress (15%) - Journaling
      final journalToday = await _isar.journals.filter()
          .dateBetween(startOfDay, endOfDay, includeLower: true, includeUpper: false)
          .count();
      final double journalProgress = journalToday > 0 ? 1.0 : 0.0;

      // 4. Activity Progress (15%) - Steps
      final stepLog = await _isar.stepLogs.filter().dateEqualTo(startOfDay).findFirst();
      stepsCount.value = stepLog?.steps ?? 0;
      stepsGoal.value = stepLog?.goal ?? 10000;
      stepsProgress.value = stepLog?.progress ?? 0.0;
      final double stepProgress = stepsProgress.value;

      // 5. Work Progress (20%) - Attendance (Only if working day)
      final profile = await _isar.workProfiles.get(0) ?? WorkProfile();
      workCompany.value = profile.companyName ?? '';
      workPosition.value = profile.jobPosition ?? '';
      final isWorkDay = profile.workingDays.contains(startOfDay.weekday % 7);
      
      final attendanceLog = await _isar.attendanceLogs.filter().dateEqualTo(startOfDay).findFirst();
      final double workProgress = attendanceLog?.status == AttendanceStatus.present ? 1.0 : 0.0;
      
      // Calculate Salary Countdown for Bento
      _updateSalaryCountdown(profile);

      // --- Unified Life OS Governance: Tri-Pillar Calculation ---
      tasksLeftCount.value = total - completed;
      
      // 1. Mind Pillar (Tasks & Intellectual Growth)
      final taskScore = total > 0 ? (completed / total) : 1.0;
      final bookScore = currentBookProgress.value;
      mindProgress.value = (taskScore * 0.7 + bookScore * 0.3).clamp(0.0, 1.0);

      // 2. Body Pillar (Physical Health & Vitality)
      final stepScore = stepsProgress.value;
      final medScore = medProgress;
      bodyProgress.value = (stepScore * 0.5 + medScore * 0.5).clamp(0.0, 1.0);

      // 3. Spirit Pillar (Mindfulness & Reflection)
      final moodMap = {
        'happy': 1.0,
        'relaxed': 0.8,
        'neutral': 0.6,
        'stressed': 0.4,
        'sad': 0.2,
      };
      final moodScore = moodMap[weeklyMoodTrend.value] ?? 0.6;
      spiritProgress.value = (journalProgress * 0.7 + moodScore * 0.3).clamp(0.0, 1.0);

      // Global Governance Average
      progressPercentage.value = (mindProgress.value + bodyProgress.value + spiritProgress.value) / 3;

      // ✅ Parallelize non-essential analytics to speed up UI responsiveness
      Future.wait([
        _loadWeeklyData(),
        _loadCompletedDays(),
        _analyzeMoodData(),
        _loadReadingStats(),
      ]);
      
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Home Data Load Error');
    }
  }

  void _updateSalaryCountdown(WorkProfile profile) {
    final now = DateTime.now();
    final salDay = profile.salaryDay;
    
    final nextSalary = now.nextOccurrenceOfMonthDay(salDay);
    
    daysUntilSalary.value = nextSalary.difference(now.normalized).inDays;
  }

  Future<void> _loadReadingStats() async {
    try {
      // ✅ Optimization: Query only active books sorted by last read, avoid full mapping
      final activeBooks = await _isar.books
          .filter()
          .isCompletedEqualTo(false)
          .sortByLastReadAtDesc()
          .thenByCreatedAtDesc()
          .limit(1)
          .findAll();

      if (activeBooks.isNotEmpty) {
        currentBookTitle.value = activeBooks.first.title;
        currentBookProgress.value = activeBooks.first.progress;
      } else {
        currentBookTitle.value = 'my_library'.tr;
        currentBookProgress.value = 0.0;
      }
    } catch (e) {
      talker.error('Error loading reading stats: $e');
    }
  }

  Future<void> _analyzeMoodData() async {
    final now = DateTime.now();
    final logs = await _isar.journals.filter()
        .dateGreaterThan(now.subtract(const Duration(days: 7)))
        .findAll();
    
    if (logs.isEmpty) {
      weeklyMoodTrend.value = 'neutral';
      moodEmoji.value = '😐';
      return;
    }

    final counts = <Mood, int>{};
    for (var j in logs) {
      counts[j.mood] = (counts[j.mood] ?? 0) + 1;
    }
    final topMood = counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    weeklyMoodTrend.value = topMood.name;
    final emojis = {'amazing': '🤩', 'good': '😊', 'neutral': '😐', 'bad': '😢', 'terrible': '😤'};
    moodEmoji.value = emojis[weeklyMoodTrend.value] ?? '😐';
  }

  void onDateSelected(DateTime date) {
    selectedDate.value = date;
    _loadRealData();
  }

  Future<void> _loadWeeklyData() async {
    final now = DateTime.now();
    final sevenDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
    
    // ✅ Optimization: Use property query to only fetch timestamps
    final completedDates = await _isar.tasks.filter()
        .statusEqualTo(TaskStatus.completed)
        .completedAtGreaterThan(sevenDaysAgo)
        .completedAtProperty()
        .findAll();
        
    final List<int> data = List.filled(7, 0);
    final List<String> labels = [];
    final locale = Get.locale?.languageCode ?? 'en';
    
    for (int i = 0; i < 7; i++) {
      final day = sevenDaysAgo.add(Duration(days: i));
      labels.add(DateFormat.E(locale).format(day).substring(0, 1));
      
      data[i] = completedDates.where((d) {
        return d != null && d.year == day.year && d.month == day.month && d.day == day.day;
      }).length;
    }
    weeklyData.assignAll(data);
    weeklyLabels.assignAll(labels);
  }

  Future<void> _loadCompletedDays() async {
    // ✅ Optimization: Use property query to only fetch timestamps, avoid loading full Task objects
    final completedDates = await _isar.tasks.filter()
        .statusEqualTo(TaskStatus.completed)
        .completedAtProperty()
        .findAll();
        
    final days = completedDates
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
    
    if (completedDays.length != days.length || !completedDays.containsAll(days)) {
      completedDays.assignAll(days);
    }
  }

  void changePage(int index) {
    currentIndex.value = index;
    if (index == 0) _loadRealData();
  }

  DateTime _parseRobustTime(String timeStr) {
    const english = ['0','1','2','3','4','5','6','7','8','9'];
    const arabic = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    String normalized = timeStr;
    for (int i = 0; i < english.length; i++) {
      normalized = normalized.replaceAll(arabic[i], english[i]);
    }
    normalized = normalized.replaceAll('ص', 'AM').replaceAll('م', 'PM');
    normalized = normalized.replaceAll('صباحاً', 'AM').replaceAll('مساءً', 'PM');
    return DateFormat.jm().parse(normalized);
  }
}
