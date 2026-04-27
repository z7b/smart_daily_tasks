import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import '../../../data/models/step_log_model.dart';
import '../../../data/providers/step_repository.dart';
import '../../../data/services/health_service.dart';
import '../../../core/helpers/log_helper.dart';
import '../../../data/models/achievement_model.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/time_service.dart';

class StepsController extends GetxController with WidgetsBindingObserver {
  final StepRepository _repository = Get.find<StepRepository>();
  final HealthService _healthService = Get.find<HealthService>();
  final _storage = GetStorage();
  NotificationService get _notificationService => Get.find<NotificationService>();
  final TimeService _timeService = Get.find<TimeService>();

  // ✅ Rule 3: Single Source of Truth (No competing local state)
  final todayLog = Rxn<StepLog>();
  
  int get stepsToday => todayLog.value?.steps ?? 0;
  double get caloriesToday => todayLog.value?.calories ?? 0.0;
  double get distanceToday => (todayLog.value?.distance ?? 0.0) / 1000.0; // ✅ Fix: Meters to Km
  int get activeTimeToday => ((todayLog.value?.steps ?? 0) / 100).round();

  // ✅ Principal Architecture: Dynamic Aggregation SSOT
  // This ensures that the grid stats below the chart reflect the selected period.
  
  List<StepLog> get currentPeriodLogs {
    final filter = selectedTimeFilter.value;
    if (filter == 'yearly') return yearlyLogs.where((l) => l.date.year == selectedYear.value).toList();
    if (filter == 'monthly') return monthlyLogs;
    return weeklyLogs;
  }

  int get stepsForPeriod {
    if (selectedTimeFilter.value == 'daily') return stepsToday;
    return currentPeriodLogs.fold<int>(0, (sum, log) => sum + log.steps);
  }

  double get distanceKmForPeriod {
    if (selectedTimeFilter.value == 'daily') return distanceToday;
    final totalMeters = currentPeriodLogs.fold<double>(0.0, (sum, log) => sum + log.distance);
    return totalMeters / 1000.0; // ✅ Fix: Convert to KM
  }

  double get caloriesForPeriod {
    if (selectedTimeFilter.value == 'daily') return caloriesToday;
    return currentPeriodLogs.fold<double>(0.0, (sum, log) => sum + log.calories);
  }

  int get activeTimeForPeriod {
    // We estimate active time based on steps for consistent metrics
    return (stepsForPeriod / 100).round();
  }
  
  final dailyGoal = 10000.obs;
  final isLoading = false.obs;
  StreamSubscription? _stepLogSub;
  
  // Bind UI reactivity to centralized HealthService
  RxnBool get isHealthAuthorized => _healthService.isAuthorized;
  
  // Biometrics
  final userHeight = Rxn<double>(); // cm
  final userWeight = Rxn<double>(); // kg
  final userGender = Rxn<String>(); // 'male' or 'female'
  
  // Controllers for goal input
  final dailyGoalController = TextEditingController();
  final heightCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  
  // Historical Data
  final weeklyLogs = <StepLog>[].obs;
  final monthlyLogs = <StepLog>[].obs;
  final yearlyLogs = <StepLog>[].obs;
  final totalStepsAllTime = 0.obs;
  final lastSyncTime = Rxn<DateTime>();
  final achievements = <StepAchievement>[].obs;
  final _isSyncing = false.obs; // Logic guard
  final isDeepSyncing = false.obs; // UI feedback for backfill

  // Stats for Comparison
  final lastWeekTotalSteps = 0.obs;
  final weekOverWeekChange = 0.0.obs;
  final currentStreak = 0.obs;
  bool _hasNotified80 = false;
  Set<String> _notifiedAchievements = {};

  // UI Redesign State
  final selectedTimeFilter = 'weekly'.obs; // 'weekly', 'monthly', 'yearly'
  final selectedYear = DateTime.now().year.obs;
  final hourlySteps = <int>[].obs;
  final healthPromptDismissed = false.obs;

  Timer? _pollTimer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    healthPromptDismissed.value = _storage.read('health_prompt_dismissed') ?? false;
    
    // ✅ Expert Logic: Anchor Achievements to Installation Date
    if (!_storage.hasData('app_install_date')) {
      _storage.write('app_install_date', DateTime.now().toIso8601String());
    }
    
    final savedGoal = _storage.read('daily_step_goal') ?? 10000;
    dailyGoal.value = savedGoal;
    dailyGoalController.text = savedGoal.toString();
    
    // Load Biometrics
    userHeight.value = _storage.read('user_height');
    userWeight.value = _storage.read('user_weight');
    userGender.value = _storage.read('user_gender');
    
    heightCtrl.text = userHeight.value?.toString() ?? '';
    weightCtrl.text = userWeight.value?.toString() ?? '';
    
    _initAchievementCatalog();
    
    // Load notified achievements
    final notified = _storage.read<List>('notified_achievements') ?? [];
    _notifiedAchievements = notified.cast<String>().toSet();
    
    // ✅ Sprint 1: SSOT - Bind directly to repository stream
    _listenToTodayStepLog();

    // ✅ Sprint 1 Fix: Listen for day rotation (Midnight Bug Fix)
    _timeService.dayChangedStream.listen((newToday) {
      talker.info('🌅 StepsController: Day rotated to $newToday. Re-binding streams.');
      _listenToTodayStepLog();
      _syncAndRefreshAll();
    });

    // ✅ Architecture Fix: Ensure yearly data updates when user changes the year
    ever(selectedYear, (_) => _loadHistoricalStats());
  }

  void _syncAndRefreshAll() {
    syncData();
    _loadHistoricalStats();
  }

  void _listenToTodayStepLog() {
    _stepLogSub?.cancel();
    // Use TimeService.today instead of DateTime.now() to ensure consistency
    final today = _timeService.today;
    _stepLogSub = _repository.watchStepLog(today).listen((log) {
      // Direct binding! The UI will react to `todayLog.value` changing
      todayLog.value = log;
      
      _evaluateAchievements();
      _check80PercentGoal();
      _checkGoalCompletion();
    });
  }

  DateTime get installDate {
    final dateStr = _storage.read('app_install_date');
    return dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
  }

  void _initAchievementCatalog() {
    achievements.assignAll([
      StepAchievement(
        id: 'first_step',
        titleKey: 'medal_first_step',
        descKey: 'medal_first_step_desc',
        icon: CupertinoIcons.paw,
        color: Colors.blue,
        missionText: 'medal_mission_1_step',
      ),
      StepAchievement(
        id: 'goal_crusher',
        titleKey: 'medal_goal_crusher',
        descKey: 'medal_goal_crusher_desc',
        icon: CupertinoIcons.bolt_fill,
        color: Colors.orange,
        missionText: 'medal_mission_goal',
      ),
      StepAchievement(
        id: 'marathoner',
        titleKey: 'medal_marathoner',
        descKey: 'medal_marathoner_desc',
        icon: CupertinoIcons.infinite,
        color: Colors.red,
        missionText: 'medal_mission_marathon',
      ),
      StepAchievement(
        id: 'streak_3',
        titleKey: 'medal_streak_3',
        descKey: 'medal_streak_3_desc',
        icon: CupertinoIcons.flame,
        color: Colors.amber,
        missionText: 'medal_mission_streak_3',
      ),
      StepAchievement(
        id: 'streak_7',
        titleKey: 'medal_streak_7',
        descKey: 'medal_streak_7_desc',
        icon: CupertinoIcons.flame_fill,
        color: Colors.deepOrange,
        missionText: 'medal_mission_streak_7',
      ),
      StepAchievement(
        id: 'millionaire',
        titleKey: 'medal_millionaire',
        descKey: 'medal_millionaire_desc',
        icon: CupertinoIcons.money_dollar_circle_fill,
        color: Colors.purple,
        missionText: 'medal_mission_millionaire',
      ),
      StepAchievement(
        id: 'trailblazer',
        titleKey: 'medal_trailblazer',
        descKey: 'medal_trailblazer_desc',
        icon: CupertinoIcons.map_fill,
        color: Colors.indigo,
        missionText: 'medal_mission_trailblazer',
      ),
      StepAchievement(
        id: 'weekend_warrior',
        titleKey: 'medal_weekend_warrior',
        descKey: 'medal_weekend_warrior_desc',
        icon: CupertinoIcons.wind,
        color: Colors.teal,
        missionText: 'medal_mission_weekend',
      ),
      StepAchievement(
        id: 'elite_week',
        titleKey: 'medal_elite_week',
        descKey: 'medal_elite_week_desc',
        icon: CupertinoIcons.star_fill,
        color: Colors.black,
        missionText: 'medal_mission_elite',
      ),
      StepAchievement(
        id: 'early_bird',
        titleKey: 'medal_early_bird',
        descKey: 'medal_early_bird_desc',
        icon: CupertinoIcons.sunrise_fill,
        color: Colors.orangeAccent,
        missionText: 'medal_mission_early_bird',
      ),
      StepAchievement(
        id: 'night_owl',
        titleKey: 'medal_night_owl',
        descKey: 'medal_night_owl_desc',
        icon: CupertinoIcons.moon_stars_fill,
        color: Colors.deepPurple,
        missionText: 'medal_mission_night_owl',
      ),
      StepAchievement(
        id: 'elite_100k',
        titleKey: 'medal_elite_100k',
        descKey: 'medal_elite_100k_desc',
        icon: CupertinoIcons.rosette,
        color: Colors.pink,
        missionText: 'medal_mission_elite_100k',
      ),
    ]);
  }

  @override
  void onReady() {
    super.onReady();
    syncData();
    _startPolling();
  }

  @override
  void onClose() {
    _stepLogSub?.cancel();
    _pollTimer?.cancel();
    dailyGoalController.dispose();
    heightCtrl.dispose();
    weightCtrl.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      talker.info('♻️ App Resumed: Triggering Life OS Steps Pulse...');
      syncData();
    }
  }

  Future<void> requestHealthPermission() async {
    final granted = await _healthService.requestPermissions();
    if (granted) {
      syncData();
      _startPolling();
    } else {
      // If denied, we still mark it as seen/dismissed to respect "Show only once"
      dismissHealthPrompt();
    }
  }

  void dismissHealthPrompt() {
    healthPromptDismissed.value = true;
    _storage.write('health_prompt_dismissed', true);
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isHealthAuthorized.value == true && !isLoading.value && !_isSyncing.value) {
        talker.info('⏱️ Real-time Polling Triggered (30s)');
        syncData();
      }
    });
  }

  Future<void> syncData() async {
    if (isLoading.value || _isSyncing.value) return;
    
    try {
      _isSyncing.value = true;
      isLoading.value = true;
      talker.info('🔄 Syncing Life OS Steps (Authorized: ${isHealthAuthorized.value})');
      
      final today = DateTime.now();
      
      if (isHealthAuthorized.value == true) {
        final bool hasDeepSynced = _storage.read('health_deep_sync_done_v2') ?? false;
        
        if (!hasDeepSynced) {
          talker.info('🌊 Initial Handshake: Performing 365-Day Deep Sync Pulse...');
          isDeepSyncing.value = true;
          // ✅ Sprint 1 Concurrency Fix: Sync today FIRST, wait for it, then run deep sync safely
          await _healthService.fetchAndPersistSteps();
          
          _healthService.performDeepSync(365).then((_) {
             _storage.write('health_deep_sync_done_v2', true);
             isDeepSyncing.value = false;
             _loadHistoricalStats();
          });
        } else {
          await _healthService.fetchAndPersistSteps();
        }
        
        // Update hourly distribution from real sensors
        final hSteps = await _healthService.getHourlySteps();
        hourlySteps.assignAll(hSteps);
      } else {
        // ✅ Streak Fix: Ensure today's log ALWAYS exists in Isar.
        final todayLog = await _repository.getStepLog(today);
        if (todayLog == null) {
          await _repository.updateStepsLocally(today, 0, isManual: true);
        }
      }

      // Load historical data for charts
      await _loadHistoricalStats();
      totalStepsAllTime.value = await _repository.getTotalStepsForAllTime();
      lastSyncTime.value = DateTime.now();
      
      // Schedule smart reminders based on current progress
      _notificationService.scheduleSmartStepsReminders(
        goal: dailyGoal.value,
        currentSteps: stepsToday,
      );
      
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 StepsController Sync Error');
    } finally {
      isLoading.value = false;
      _isSyncing.value = false;
    }
  }

  // --- UI Redesign Logic (Expert Data Aggregation) ---

  void setTimeFilter(String filter) {
    selectedTimeFilter.value = filter;
  }

  void setYear(int year) {
    selectedYear.value = year;
    // trigger UI update automatically because it's reactive
  }

  List<int> get availableYears {
    final startYear = installDate.year;
    final currentYear = DateTime.now().year;
    List<int> years = [];
    for (int y = currentYear; y >= startYear; y--) {
      years.add(y);
    }
    return years.isEmpty ? [currentYear] : years;
  }

  /// Aggregates logs dynamically for the bar chart.
  /// Weekly: 7 days. Monthly: 4-5 weeks. Yearly: 12 months.
  List<Map<String, dynamic>> getAggregatedChartData() {
    final filter = selectedTimeFilter.value;
    final now = DateTime.now();
    List<Map<String, dynamic>> result = [];

    if (filter == 'weekly') {
      // Last 7 days
      final logs = weeklyLogs.toList();
      // Ensure we have 7 days even if empty
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final match = logs.firstWhere(
          (l) => l.date.year == d.year && l.date.month == d.month && l.date.day == d.day,
          orElse: () => StepLog(date: d, goal: dailyGoal.value),
        );
        result.add({
          'label': DateFormat.E(Get.locale?.languageCode ?? 'en').format(d),
          'value': match.steps,
        });
      }
    } else if (filter == 'monthly') {
      // 4 weeks of the current month
      final logs = monthlyLogs.toList();
      int week1 = 0, week2 = 0, week3 = 0, week4 = 0;
      for (var l in logs) {
        if (l.date.day <= 7) {
          week1 += l.steps;
        } else if (l.date.day <= 14) {
          week2 += l.steps;
        } else if (l.date.day <= 21) {
          week3 += l.steps;
        } else {
          week4 += l.steps;
        }
      }
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      result = [
        {'label': 'week_1'.tr, 'value': week1, 'dateRange': '1 - 7'},
        {'label': 'week_2'.tr, 'value': week2, 'dateRange': '8 - 14'},
        {'label': 'week_3'.tr, 'value': week3, 'dateRange': '15 - 21'},
        {'label': 'week_4'.tr, 'value': week4, 'dateRange': '22 - $lastDay'},
      ];
    } else if (filter == 'yearly') {
      // 12 months of selected year
      final targetYear = selectedYear.value;
      final logs = yearlyLogs.where((l) => l.date.year == targetYear).toList();
      Map<int, int> monthlySums = {};
      for (var l in logs) {
        monthlySums[l.date.month] = (monthlySums[l.date.month] ?? 0) + l.steps;
      }
      for (int i = 1; i <= 12; i++) {
        final d = DateTime(targetYear, i, 1);
        result.add({
          'label': DateFormat.MMM(Get.locale?.languageCode ?? 'en').format(d),
          'value': monthlySums[i] ?? 0,
        });
      }
    }

    return result;
  }

  int get getDailyAverage {
    final filter = selectedTimeFilter.value;
    final logs = filter == 'yearly' ? yearlyLogs.where((l) => l.date.year == selectedYear.value).toList() : (filter == 'monthly' ? monthlyLogs : weeklyLogs);
    if (logs.isEmpty) return stepsToday;
    final total = logs.fold<int>(0, (p, e) => p + e.steps);
    return (total / logs.length).round();
  }

  Map<String, dynamic> get getBestPeriod {
    final filter = selectedTimeFilter.value;
    if (filter == 'monthly') {
      final aggregated = getAggregatedChartData();
      if (aggregated.isEmpty) return {'title': 'best_week'.tr, 'label': 'the_week'.tr, 'sublabel': '', 'value': 0};
      var best = aggregated.first;
      for (var a in aggregated) {
        if ((a['value'] as int) > (best['value'] as int)) best = a;
      }
      return {
        'title': 'best_week'.tr,
        'label': '${'the_week'.tr} ${best['label']}',
        'sublabel': '${best['dateRange']} ${DateFormat.MMM(Get.locale?.languageCode ?? 'en').format(DateTime.now())}',
        'value': best['value'],
      };
    } else if (filter == 'yearly') {
      final aggregated = getAggregatedChartData();
      if (aggregated.isEmpty) return {'title': 'best_month'.tr, 'label': 'the_month'.tr, 'sublabel': '', 'value': 0};
      var best = aggregated.first;
      for (var a in aggregated) {
        if ((a['value'] as int) > (best['value'] as int)) best = a;
      }
      return {
        'title': 'best_month'.tr,
        'label': best['label'],
        'sublabel': '${selectedYear.value}',
        'value': best['value'],
      };
    } else {
      final logs = weeklyLogs;
      if (logs.isEmpty) return {'title': 'best_day'.tr, 'label': 'the_day'.tr, 'sublabel': '', 'value': stepsToday};
      StepLog best = logs.first;
      for (var l in logs) {
        if (l.steps > best.steps) best = l;
      }
      return {
        'title': 'best_day'.tr,
        'label': DateFormat.E(Get.locale?.languageCode ?? 'en').format(best.date),
        'sublabel': DateFormat('d MMM', Get.locale?.languageCode ?? 'en').format(best.date),
        'value': best.steps,
      };
    }
  }

  Map<String, dynamic> get getWorstPeriod {
    final filter = selectedTimeFilter.value;
    if (filter == 'monthly') {
      final aggregated = getAggregatedChartData();
      if (aggregated.isEmpty) return {'title': 'worst_week'.tr, 'label': 'the_week'.tr, 'sublabel': '', 'value': 0};
      var worst = aggregated.first;
      for (var a in aggregated) {
        if ((a['value'] as int) < (worst['value'] as int)) worst = a;
      }
      return {
        'title': 'worst_week'.tr,
        'label': '${'the_week'.tr} ${worst['label']}',
        'sublabel': '${worst['dateRange']} ${DateFormat.MMM(Get.locale?.languageCode ?? 'en').format(DateTime.now())}',
        'value': worst['value'],
      };
    } else if (filter == 'yearly') {
      final aggregated = getAggregatedChartData();
      if (aggregated.isEmpty) return {'title': 'worst_month'.tr, 'label': 'the_month'.tr, 'sublabel': '', 'value': 0};
      var worst = aggregated.first;
      for (var a in aggregated) {
        if ((a['value'] as int) < (worst['value'] as int)) worst = a;
      }
      return {
        'title': 'worst_month'.tr,
        'label': worst['label'],
        'sublabel': '${selectedYear.value}',
        'value': worst['value'],
      };
    } else {
      final logs = weeklyLogs;
      if (logs.isEmpty) return {'title': 'worst_day'.tr, 'label': 'the_day'.tr, 'sublabel': '', 'value': stepsToday};
      StepLog worst = logs.first;
      for (var l in logs) {
        if (l.steps < worst.steps) worst = l;
      }
      return {
        'title': 'worst_day'.tr,
        'label': DateFormat.E(Get.locale?.languageCode ?? 'en').format(worst.date),
        'sublabel': DateFormat('d MMM', Get.locale?.languageCode ?? 'en').format(worst.date),
        'value': worst.steps,
      };
    }
  }

  Future<void> _loadHistoricalStats() async {
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));
    weeklyLogs.assignAll(await _repository.getLogsInRange(weekStart, now));

    final monthStart = DateTime(now.year, now.month, 1);
    monthlyLogs.assignAll(await _repository.getLogsInRange(monthStart, now));

    // ✅ Architecture Fix: Yearly data should cover the FULL selected year, 
    // independent of install date, to ensure aggregation sums are correct.
    final targetYear = selectedYear.value;
    final yearStart = DateTime(targetYear, 1, 1);
    final yearEnd = DateTime(targetYear, 12, 31, 23, 59, 59);
    
    yearlyLogs.assignAll(await _repository.getLogsInRange(yearStart, yearEnd));

    // Calculate Week over Week Comparison
    final lastWeekStart = now.subtract(const Duration(days: 14));
    final lastWeekEnd = now.subtract(const Duration(days: 7));
    final lastWeekLogs = await _repository.getLogsInRange(lastWeekStart, lastWeekEnd);
    
    lastWeekTotalSteps.value = lastWeekLogs.fold<int>(0, (p, e) => p + e.steps);
    final thisWeekTotal = weeklyLogs.fold<int>(0, (p, e) => p + e.steps);
    
    if (lastWeekTotalSteps.value > 0) {
      weekOverWeekChange.value = ((thisWeekTotal - lastWeekTotalSteps.value) / lastWeekTotalSteps.value) * 100;
    } else {
      weekOverWeekChange.value = 0.0;
    }

    // --- Smart Streak Logic (Expert Rewrite) ---
    // 
    // Bug Fix: Previous version had 3 issues:
    // 1. Used stepsToday.value for today but log.goal for other days (inconsistent)
    // 2. If today's goal wasn't reached, streak showed 0 even if yesterday was reached
    // 3. Non-Health users had no logs → streak was always 0
    //
    // New logic: Walk backwards from today. Count consecutive days where steps >= goal.
    // Today counts if goal is reached. If not, start counting from yesterday.
    
    int streak = 0;
    final allLogs = await _repository.getLogsInRange(
      now.subtract(const Duration(days: 60)), now,
    );
    
    // Build a fast lookup map: date (midnight) → StepLog
    final Map<String, StepLog> logMap = {};
    for (var log in allLogs) {
      final key = '${log.date.year}-${log.date.month}-${log.date.day}';
      logMap[key] = log;
    }
    
    DateTime cursor = DateTime(now.year, now.month, now.day);
    
    // Check today first using live data (most accurate)
    final todayKey = '${cursor.year}-${cursor.month}-${cursor.day}';
    final currentLog = logMap[todayKey];
    final int todayStepsCount = stepsToday;
    final int todayGoal = currentLog?.goal ?? dailyGoal.value;
    
    if (todayStepsCount >= todayGoal && todayGoal > 0) {
      streak = 1;
      cursor = cursor.subtract(const Duration(days: 1));
    } else {
      // Today not reached — start checking from yesterday
      cursor = cursor.subtract(const Duration(days: 1));
    }
    
    // Walk backwards through previous days
    while (streak < 365) {
      final key = '${cursor.year}-${cursor.month}-${cursor.day}';
      final log = logMap[key];
      
      if (log != null && log.goal > 0 && log.steps >= log.goal) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break; // Streak broken
      }
    }
    
    currentStreak.value = streak;
    talker.info('🔥 Streak calculated: $streak days (today: $todayStepsCount/$todayGoal)');
  }

  void _evaluateAchievements() {
    final startBoundary = DateTime(installDate.year, installDate.month, installDate.day);
    
    // Filter data for Achievements: Only count logs >= installDate
    final validWeeklyLogs = weeklyLogs.where((l) => !l.date.isBefore(startBoundary)).toList();
    
    // Calculate effective total since install (for medals)
    // Note: totalStepsAllTime still shows historical data for the chart/stats
    int totalSinceInstall = stepsToday;
    if (validWeeklyLogs.isNotEmpty) {
      // Avoid double counting today if it's in weeklyLogs
      totalSinceInstall = validWeeklyLogs.fold<int>(0, (p, e) => p + e.steps);
    }
    
    final currentStepsToday = stepsToday;
    final maxInWeek = validWeeklyLogs.isNotEmpty 
        ? validWeeklyLogs.map((e) => e.steps).reduce((a, b) => a > b ? a : b)
        : 0;
        
    // ✅ Fix: Use unified currentStreak instead of separate calculation
    final streak = currentStreak.value;

    achievements.assignAll(achievements.map((a) {
      bool unlocked = false;
      double prog = 0.0;

      switch (a.id) {
        case 'first_step':
          unlocked = totalSinceInstall > 0;
          prog = unlocked ? 1.0 : 0.0;
          break;
        case 'goal_crusher':
          unlocked = validWeeklyLogs.any((l) => l.steps >= l.goal);
          prog = unlocked ? 1.0 : (currentStepsToday / dailyGoal.value).clamp(0, 1);
          break;
        case 'marathoner':
          unlocked = maxInWeek >= 42195;
          prog = (maxInWeek / 42195).clamp(0, 1);
          break;
        case 'streak_3':
          unlocked = streak >= 3;
          prog = (streak / 3).clamp(0, 1);
          break;
        case 'streak_7':
          unlocked = streak >= 7;
          prog = (streak / 7).clamp(0, 1);
          break;
        case 'millionaire':
          unlocked = totalSinceInstall >= 1000000;
          prog = (totalSinceInstall / 1000000).clamp(0, 1);
          break;
        case 'trailblazer':
          unlocked = totalSinceInstall >= 5000000;
          prog = (totalSinceInstall / 5000000).clamp(0, 1);
          break;
        case 'weekend_warrior':
          final isWeekend = DateTime.now().weekday == DateTime.saturday || DateTime.now().weekday == DateTime.sunday;
          unlocked = isWeekend && currentStepsToday >= 20000 && !DateTime.now().isBefore(startBoundary);
          prog = (currentStepsToday / 20000).clamp(0, 1);
          break;
        case 'elite_week':
          final weekTotal = validWeeklyLogs.fold<int>(0, (p, e) => p + e.steps);
          unlocked = weekTotal >= 100000;
          prog = (weekTotal / 100000).clamp(0, 1);
          break;
      }

      return a.copyWith(isUnlocked: unlocked, progress: prog);
    }).toList());

    // ✅ Smart Achievement Notifications
    for (var a in achievements) {
      if (a.isUnlocked && !_notifiedAchievements.contains(a.id)) {
        _notifyAchievement(a);
        _notifiedAchievements.add(a.id);
        _storage.write('notified_achievements', _notifiedAchievements.toList());
      }
    }
  }

  void _notifyAchievement(StepAchievement achievement) {
    _notificationService.showSmartStepsNotification(
      id: achievement.id.hashCode % 1000000,
      title: 'new_achievement'.tr,
      body: 'achievement_earned'.trParams({'name': achievement.titleKey.tr}),
      bigText: '${'new_achievement'.tr}\n\n${'achievement_earned'.trParams({'name': achievement.titleKey.tr})}\n${achievement.descKey.tr}\n\n${'keep_achieving'.tr}',
      largeIcon: 'achievement',
    );
  }

  double get progress => dailyGoal.value > 0 ? (stepsToday / dailyGoal.value).clamp(0.0, 1.0) : 0.0;
  
  // ✅ Professional Analytics: Computed Averages
  int get weeklyAverage {
    if (weeklyLogs.isEmpty) return 0;
    final sum = weeklyLogs.fold<int>(0, (p, e) => p + e.steps);
    return (sum / 7).round(); // Fixed divisor for weekly rhythm
  }

  int get monthlyAverage {
    if (monthlyLogs.isEmpty) return 0;
    final sum = monthlyLogs.fold<int>(0, (p, e) => p + e.steps);
    return (sum / monthlyLogs.length).round();
  }

  int get yearlyAverage {
    if (yearlyLogs.isEmpty) return 0;
    final sum = yearlyLogs.fold<int>(0, (p, e) => p + e.steps);
    return (sum / yearlyLogs.length).round();
  }

  void updateGoal(int newGoal) {
    if (newGoal < 500 || newGoal > 200000) return; // ✅ Fix: Min 500 steps, Max 200k
    dailyGoal.value = newGoal;
    dailyGoalController.text = newGoal.toString();
    _storage.write('daily_step_goal', newGoal);
    _hasNotified80 = false; // Reset notification for new goal
    syncData(); 
  }

  bool _hasNotifiedGoal = false;

  void _check80PercentGoal() {
    if (progress >= 0.8 && !_hasNotified80 && stepsToday < dailyGoal.value) {
      _hasNotified80 = true;
      final remaining = (dailyGoal.value - stepsToday).clamp(0, 999999);
      _notificationService.showSmartStepsNotification(
        id: 80,
        title: 'almost_there_title'.tr,
        body: 'steps_remaining_msg'.trParams({'count': '$remaining'}),
        bigText: '${'steps_remaining_msg'.trParams({'count': '$remaining'})} 💪\n${'goal_today_msg'.trParams({'goal': '${dailyGoal.value}'})}',
        largeIcon: 'walker',
      );
    }
  }

  void _checkGoalCompletion() {
    if (progress >= 1.0 && !_hasNotifiedGoal) {
      _hasNotifiedGoal = true;
      _notificationService.showSmartStepsNotification(
        id: 100,
        title: 'goal_complete_title'.tr,
        body: 'goal_complete_body'.tr,
        bigText: '${'goal_complete_body'.tr} 🎉\n$stepsToday ${'step_unit'.tr} ${'of'.tr} ${dailyGoal.value}\n${'rest_well'.tr}',
        largeIcon: 'walker',
      );
    }
  }

  String getMotivationalMessage() {
    if (progress >= 1.0) return 'goal_achieved_msg'.tr;
    if (progress >= 0.8) return 'almost_there_msg'.tr;
    if (progress >= 0.5) return 'halfway_there_msg'.tr;
    return 'keep_moving_msg'.tr;
  }

  void calculateSmartGoal(int age, double weight, String fitnessLevel) {
    int baseGoal = 5000;
    if (fitnessLevel == 'active') baseGoal = 10000;
    if (fitnessLevel == 'pro') baseGoal = 15000;
    
    // Adjust by age
    if (age > 60) baseGoal = (baseGoal * 0.8).round();
    if (age < 30) baseGoal = (baseGoal * 1.2).round();
    
    updateGoal(baseGoal);
  }

  /// ✅ Bug Fix: Previously, saving biometrics would LOSE real sensor data and replace
  /// it with estimates. Now it triggers syncData to preserve sensor priority.
  Future<void> saveBiometrics({double? height, double? weight, String? gender}) async {
    if (height != null) {
      userHeight.value = height;
      _storage.write('user_height', height);
    }
    if (weight != null) {
      userWeight.value = weight;
      _storage.write('user_weight', weight);
    }
    if (gender != null) {
      userGender.value = gender;
      _storage.write('user_gender', gender);
    }
    syncData();
  }

  void updateDailyGoal(int newGoal) {
    dailyGoal.value = newGoal;
    _storage.write('daily_step_goal', newGoal);
    syncData();
  }

}
