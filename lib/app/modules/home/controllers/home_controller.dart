import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

import 'package:smart_daily_tasks/app/core/helpers/log_helper.dart';
import 'package:smart_daily_tasks/app/core/helpers/number_extension.dart';
import 'package:smart_daily_tasks/app/core/extensions/date_time_extensions.dart';
import 'package:smart_daily_tasks/app/core/services/app_lock_observer.dart';

import 'package:smart_daily_tasks/app/data/models/task_model.dart';
import 'package:smart_daily_tasks/app/data/models/work_profile_model.dart';
import 'package:smart_daily_tasks/app/data/models/note_model.dart';
import 'package:smart_daily_tasks/app/data/models/journal_model.dart';
import 'package:smart_daily_tasks/app/data/models/bookmark_model.dart';
import 'package:smart_daily_tasks/app/data/models/calendar_event_model.dart';
import 'package:smart_daily_tasks/app/data/models/book_model.dart';
import 'package:smart_daily_tasks/app/data/models/medication_model.dart';
import 'package:smart_daily_tasks/app/data/models/step_log_model.dart';
import 'package:smart_daily_tasks/app/data/models/attendance_log_model.dart';
import 'package:smart_daily_tasks/app/data/services/health_service.dart';

import 'package:smart_daily_tasks/app/routes/app_pages.dart';
import 'package:smart_daily_tasks/app/routes/app_routes.dart';

import 'package:smart_daily_tasks/app/data/providers/task_repository.dart';
import 'package:smart_daily_tasks/app/data/providers/medication_repository.dart';
import 'package:smart_daily_tasks/app/data/providers/step_repository.dart';
import 'package:smart_daily_tasks/app/data/providers/journal_repository.dart';

import '../services/home_medication_service.dart';
import '../services/home_task_service.dart';
import '../services/home_health_service.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  // Dependencies
  final _isar = Get.find<Isar>();
  final _healthService = Get.find<HealthService>();
  
  late final HomeMedicationService _medicationService;
  late final HomeTaskService _taskService;
  late final HomeHealthService _healthServiceStats;

  // Streams
  StreamSubscription? _taskSub;
  StreamSubscription? _journalSub;
  StreamSubscription? _bookmarkSub;
  StreamSubscription? _bookSub;
  StreamSubscription? _stepLogSub;
  StreamSubscription? _attendanceSub;
  StreamSubscription? _medicationSub;
  Timer? _pulseTimer;

  // UI State
  final greetingKey = 'greet_morning'.obs;
  final greetingMsg = 'msg_morning'.obs;
  final currentIndex = 0.obs;
  final selectedDate = DateTime.now().obs;

  // Real-time Database Counts
  final taskCount = 0.obs;
  final tasksLeftCount = 0.obs;
  final completedTasksCount = 0.obs;
  final cancelledTasksCount = 0.obs;
  final noteCount = 0.obs;
  final journalCount = 0.obs;
  final bookmarkCount = 0.obs;
  final medicationCount = 0.obs;
  final calendarEventCount = 0.obs;
  final bookCount = 0.obs;
  
  // ✅ Architecture Fix: No more Dropped Events logic
  final _isRefreshing = false.obs;
  bool _needsRefresh = false; // Dirty flag for serial execution
  final _loadToken = 0.obs; // For cancelling stale future results // ✅ Token System to prevent Race Conditions

  // Progress Pillars
  final mindProgress = 0.0.obs;
  final bodyProgress = 0.0.obs;
  final spiritProgress = 0.0.obs;
  final progressPercentage = 0.0.obs;

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
  final caloriesCount = 0.0.obs;
  final distanceCount = 0.0.obs;
  final isHealthVerified = false.obs;
  final healthLastSync = ''.obs;
  final isSyncingHealth = false.obs;
  final currentStreak = 0.obs;

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

  DateTime _lastRefreshDay = DateTime.now();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    // Initialize Services
    _medicationService = HomeMedicationService(Get.find<MedicationRepository>());
    _taskService = HomeTaskService(Get.find<TaskRepository>());
    _healthServiceStats = HomeHealthService(
      Get.find<StepRepository>(),
      Get.find<JournalRepository>(),
      _isar,
    );

    _updateGreeting();
    _setupStaticListeners(); 
    _bindTaskStream();      // ✅ SSOT: Dedicated Reactive Task Stream
    _loadRealData();        // One-time load for non-reactive pillars (Health, Meds, etc)
    
    // ✅ Architecture Fix: Re-bind dashboard when user changes the date
    ever(selectedDate, (_) {
      _bindTaskStream();
      _loadRealData();
    });

    // ✅ Architecture Fix: Run recurrence engine once on boot
    Get.find<TaskRepository>().instantiateRecurringTasks();
  }

  @override
  void onReady() {
    super.onReady();
    if (Get.isRegistered<AppLockObserver>()) {
      Get.find<AppLockObserver>().enforceColdBootLock();
    }

    final startRoute = AppPages.savedStartRoute;
    if (startRoute != Routes.HOME) {
      Get.toNamed(startRoute);
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (_healthService.isAuthorized.value == true) {
        talker.info('🏥 Phase 5: Triggering background pulse sync...');
        _healthService.fetchAndPersistSteps();
      }
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _taskSub?.cancel();
    _journalSub?.cancel();
    _bookmarkSub?.cancel();
    _bookSub?.cancel();
    _stepLogSub?.cancel();
    _attendanceSub?.cancel();
    _medicationSub?.cancel();
    _pulseTimer?.cancel();
    super.onClose();
  }

  /// ✅ Midnight Bug Fix: Full Date Comparison
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      // Compare Full Date (Year/Month/Day) instead of just Day
      if (now.year != _lastRefreshDay.year || now.month != _lastRefreshDay.month || now.day != _lastRefreshDay.day) {
        talker.info('🌙 Midnight transition detected! Refreshing Dashboard.');
        _lastRefreshDay = now;
        selectedDate.value = now;
        _loadRealData();
      }
    }
  }

  void refreshDashboard() {
    _healthService.fetchAndPersistSteps();
    _loadRealData();
  }
  
  void connectHealth() async {
    final success = await _healthService.requestPermissions();
    if (success) _loadRealData();
  }

  void _bindTaskStream() {
    // ✅ Pure Reactive SSOT: This stream bypasses the _isBusy guard.
    // It ensures that EVERY database change is reflected in the UI immediately.
    _taskSub?.cancel();
    _taskSub = _taskService.watchDailyStats(selectedDate.value).listen((stats) {
      tasksLeftCount.value = stats.pending;
      completedTasksCount.value = stats.completed;
      cancelledTasksCount.value = stats.cancelled;
      
      nextTaskTitle.value = stats.nextTitle;
      nextTaskTime.value = stats.nextTime;
      nextTaskEndTime.value = stats.nextEndTime;
      nextTaskTimeLeft.value = stats.nextTimeLeft;
      nextTaskFullDate.value = stats.nextFullDate;
      nextTaskPriority.value = stats.nextPriority;

      // ✅ SSOT: Update Today's Total Count
      taskCount.value = stats.total;

      // Update Pillars that depend on tasks
      final taskScore = stats.total > 0 ? (stats.completed / stats.total).clamp(0.0, 1.0) : 0.0;
      final bookScore = currentBookProgress.value.clamp(0.0, 1.0);
      mindProgress.value = (taskScore * 0.7 + bookScore * 0.3).clamp(0.0, 1.0);
      
      _updateTotalProgress();
    });
  }

  void _setupStaticListeners() {
    _pulseTimer?.cancel();
    _pulseTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateGreeting();
      final now = DateTime.now();
      if (selectedDate.value.year == now.year &&
          selectedDate.value.month == now.month &&
          selectedDate.value.day == now.day) {
        _loadRealData();
        // Periodically check for recurring tasks if the day has changed
        Get.find<TaskRepository>().instantiateRecurringTasks();
      }
    });

    // Note: Task watcher removed from here. Tasks are now handled via _bindTaskStream().
        
    _journalSub?.cancel();
    _journalSub = _isar.journals.watchLazy().debounceTime(const Duration(milliseconds: 500)).listen((_) => _loadRealData());
    _bookmarkSub?.cancel();
    _bookmarkSub = _isar.bookmarks.watchLazy().debounceTime(const Duration(milliseconds: 500)).listen((_) => _loadRealData());
    _bookSub?.cancel();
    _bookSub = _isar.books.watchLazy().debounceTime(const Duration(milliseconds: 500)).listen((_) => _loadRealData());
    _medicationSub?.cancel();
    _medicationSub = _isar.medications.watchLazy().debounceTime(const Duration(milliseconds: 500)).listen((_) => _loadRealData());
    _stepLogSub?.cancel();
    _stepLogSub = _isar.stepLogs.watchLazy().debounceTime(const Duration(milliseconds: 300)).listen((_) => _loadRealData());
    _attendanceSub?.cancel();
    _attendanceSub = _isar.attendanceLogs.watchLazy().debounceTime(const Duration(milliseconds: 500)).listen((_) => _loadRealData());

    GetStorage().listenKey('daily_step_goal', (_) => _loadRealData());
  }

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

    if (progressPercentage.value >= 0.9) {
      greetingMsg.value = 'msg_high_performance';
    } 
  }

  Future<void> _loadRealData() async {
    // ✅ Architecture Fix: Serial Execution (Dirty Flag Pattern)
    // We never "drop" an event. If busy, we mark it as dirty and re-run after.
    if (_isRefreshing.value) {
      _needsRefresh = true;
      talker.info('🕒 Home: Busy, marking state as DIRTY for next cycle');
      return;
    }

    _isRefreshing.value = true;
    _needsRefresh = false;

    try {
      await _performActualLoad();
    } finally {
      _isRefreshing.value = false;
      // If a request came in while we were busy, run it now to ensure data fidelity.
      if (_needsRefresh) {
        talker.info('🔄 Home: Cycle complete, running PENDING dirty-refresh');
        _loadRealData();
      }
    }
  }

  Future<void> _performActualLoad() async {
    final int currentToken = ++_loadToken.value;
    final viewDate = selectedDate.value;

    try {
      final results = await Future.wait([
        _medicationService.getDailyStats(viewDate),
        _healthServiceStats.getHealthStats(viewDate),
      ]);
      
      if (currentToken != _loadToken.value) return;

      final medStats = results[0] as MedicationDailyStats;
      // Task stats removed from here - now handled by dedicated reactive stream
      final healthStats = results[1] as HomeHealthStats;

      // Update Non-Task Counts
      noteCount.value = await _isar.notes.count();
      journalCount.value = await _isar.journals.count();
      bookmarkCount.value = await _isar.bookmarks.count();
      medicationCount.value = await _isar.medications.count();
      calendarEventCount.value = await _isar.calendarEvents.count();
      bookCount.value = await _isar.books.count();

      // Update Work Profile (Non-reactive, pull-based)
      final profile = await _isar.workProfiles.get(0) ?? WorkProfile();
      workCompany.value = profile.companyName ?? '';
      workPosition.value = profile.jobPosition ?? '';
      _updateSalaryCountdown(profile);

      // Update Medications
      medTakenDoses.value = medStats.taken;
      medExpectedDoses.value = medStats.expected;
      nextMedicationTime.value = medStats.nextTime;
      nextMedicationName.value = medStats.nextName;
      nextMedicationTimeLeft.value = medStats.nextTimeLeft;

      // Update Health & Activity
      currentStreak.value = healthStats.currentStreak;
      moodEmoji.value = healthStats.moodEmoji;
      weeklyMoodTrend.value = healthStats.moodTrend;
      currentBookTitle.value = healthStats.currentBookTitle;
      currentBookProgress.value = healthStats.currentBookProgress;
      
      final stepLog = healthStats.todayStepLog;
      stepsCount.value = stepLog?.steps ?? 0;
      stepsGoal.value = stepLog?.goal ?? 10000;
      stepsProgress.value = (stepLog?.progress ?? 0.0).clamp(0.0, 1.0);
      caloriesCount.value = stepLog?.calories ?? 0.0;
      distanceCount.value = stepLog?.distance ?? 0.0;
      
      isHealthVerified.value = stepLog?.isManual == false;
      if (stepLog?.lastSyncedAt != null) {
        final locale = Get.locale?.languageCode ?? 'en';
        healthLastSync.value = DateFormat.jm(locale).format(stepLog!.lastSyncedAt!).f;
      } else {
        healthLastSync.value = '';
      }

      final medScore = medStats.expected > 0 ? (medStats.taken / medStats.expected).clamp(0.0, 1.0) : 0.0;
      bodyProgress.value = (stepsProgress.value * 0.5 + medScore * 0.5).clamp(0.0, 1.0);

      final moodMap = {'happy': 1.0, 'relaxed': 0.8, 'neutral': 0.6, 'stressed': 0.4, 'sad': 0.2};
      final moodScore = moodMap[weeklyMoodTrend.value] ?? 0.6;
      spiritProgress.value = (healthStats.journalProgress * 0.7 + moodScore * 0.3).clamp(0.0, 1.0);

      _updateTotalProgress();

      _loadWeeklyData();
      _loadCompletedDays();
      _updateGreeting();
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Home Data Load Internal Error');
    }
  }

  void _updateTotalProgress() {
    progressPercentage.value = (mindProgress.value + bodyProgress.value + spiritProgress.value) / 3;
  }

  void _updateSalaryCountdown(WorkProfile profile) {
    final contextDate = selectedDate.value; // ✅ Rule 2: Time Context
    final salDay = profile.salaryDay;
    final nextSalary = contextDate.nextOccurrenceOfMonthDay(salDay);
    daysUntilSalary.value = nextSalary.normalized.difference(contextDate.normalized).inDays;
  }

  void onDateSelected(DateTime date) {
    selectedDate.value = date;
    _loadRealData();
  }

  Future<void> _loadWeeklyData() async {
    final contextDate = selectedDate.value; // ✅ Rule 2: Time Context
    final today = contextDate.normalized;
    final sevenDaysAgo = today.subtract(const Duration(days: 6));
    
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
}
