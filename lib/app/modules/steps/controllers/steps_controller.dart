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

class StepsController extends GetxController with WidgetsBindingObserver {
  final StepRepository _repository = Get.find<StepRepository>();
  final HealthService _healthService = Get.find<HealthService>();
  final _storage = GetStorage();
  NotificationService get _notificationService => Get.find<NotificationService>();

  final stepsToday = 0.obs;
  final caloriesToday = 0.0.obs;
  final distanceToday = 0.0.obs;
  final activeTimeToday = 0.obs; // In minutes
  final dailyGoal = 10000.obs;
  final isLoading = false.obs;
  
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
          _healthService.performDeepSync(365).then((_) {
             _storage.write('health_deep_sync_done_v2', true);
             isDeepSyncing.value = false;
             _loadHistoricalStats();
          });
          stepsToday.value = await _healthService.fetchAndPersistSteps();
        } else {
          stepsToday.value = await _healthService.fetchAndPersistSteps();
        }
        
        // Update hourly distribution from real sensors
        final hSteps = await _healthService.getHourlySteps();
        hourlySteps.assignAll(hSteps);
      } else {
        // ✅ Streak Fix: Ensure today's log ALWAYS exists in Isar.
        // Previously, non-Health users had NO log created → streak was always 0.
        final todayLog = await _repository.getStepLog(today);
        stepsToday.value = todayLog?.steps ?? 0;
        if (todayLog == null) {
          // Create a minimal log so the streak engine has data to work with
          await _repository.updateStepsLocally(today, 0, isManual: true);
        }
      }

      // ✅ Batch all metric updates together to avoid stale UI flash
      final todayLog = await _repository.getStepLog(today);
      _recalculateTodayMetrics(todayLog);
      final effectiveSteps = todayLog?.steps ?? stepsToday.value;
      activeTimeToday.value = (effectiveSteps / 100).round();

      await _loadHistoricalStats();
      totalStepsAllTime.value = await _repository.getTotalStepsForAllTime();
      lastSyncTime.value = DateTime.now();
      
      _evaluateAchievements();
      _check80PercentGoal();
      _checkGoalCompletion();
      
      // Schedule smart reminders based on current progress
      _notificationService.scheduleSmartStepsReminders(
        goal: dailyGoal.value,
        currentSteps: stepsToday.value,
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
          'label': DateFormat.E('ar').format(d),
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
        {'label': 'الأول', 'value': week1, 'dateRange': '1 - 7'},
        {'label': 'الثاني', 'value': week2, 'dateRange': '8 - 14'},
        {'label': 'الثالث', 'value': week3, 'dateRange': '15 - 21'},
        {'label': 'الرابع', 'value': week4, 'dateRange': '22 - $lastDay'},
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
          'label': DateFormat.MMM('ar').format(d),
          'value': monthlySums[i] ?? 0,
        });
      }
    }

    return result;
  }

  int get getDailyAverage {
    final filter = selectedTimeFilter.value;
    final logs = filter == 'yearly' ? yearlyLogs.where((l) => l.date.year == selectedYear.value).toList() : (filter == 'monthly' ? monthlyLogs : weeklyLogs);
    if (logs.isEmpty) return stepsToday.value;
    final total = logs.fold<int>(0, (p, e) => p + e.steps);
    return (total / logs.length).round();
  }

  Map<String, dynamic> get getBestPeriod {
    final filter = selectedTimeFilter.value;
    if (filter == 'monthly') {
      final aggregated = getAggregatedChartData();
      if (aggregated.isEmpty) return {'title': 'أفضل أسبوع', 'label': 'الأسبوع', 'sublabel': '', 'value': 0};
      var best = aggregated.first;
      for (var a in aggregated) {
        if ((a['value'] as int) > (best['value'] as int)) best = a;
      }
      return {
        'title': 'أفضل أسبوع',
        'label': 'الأسبوع ${best['label']}',
        'sublabel': '${best['dateRange']} ${DateFormat.MMM('ar').format(DateTime.now())}',
        'value': best['value'],
      };
    } else if (filter == 'yearly') {
      final aggregated = getAggregatedChartData();
      if (aggregated.isEmpty) return {'title': 'أفضل شهر', 'label': 'الشهر', 'sublabel': '', 'value': 0};
      var best = aggregated.first;
      for (var a in aggregated) {
        if ((a['value'] as int) > (best['value'] as int)) best = a;
      }
      return {
        'title': 'أفضل شهر',
        'label': best['label'],
        'sublabel': '${selectedYear.value}',
        'value': best['value'],
      };
    } else {
      final logs = weeklyLogs;
      if (logs.isEmpty) return {'title': 'أفضل يوم', 'label': 'اليوم', 'sublabel': '', 'value': stepsToday.value};
      StepLog best = logs.first;
      for (var l in logs) {
        if (l.steps > best.steps) best = l;
      }
      return {
        'title': 'أفضل يوم',
        'label': DateFormat.E('ar').format(best.date),
        'sublabel': DateFormat('d MMM', 'ar').format(best.date),
        'value': best.steps,
      };
    }
  }

  Map<String, dynamic> get getWorstPeriod {
    final filter = selectedTimeFilter.value;
    if (filter == 'monthly') {
      final aggregated = getAggregatedChartData();
      if (aggregated.isEmpty) return {'title': 'أقل أسبوع', 'label': 'الأسبوع', 'sublabel': '', 'value': 0};
      var worst = aggregated.first;
      for (var a in aggregated) {
        if ((a['value'] as int) < (worst['value'] as int)) worst = a;
      }
      return {
        'title': 'أقل أسبوع',
        'label': 'الأسبوع ${worst['label']}',
        'sublabel': '${worst['dateRange']} ${DateFormat.MMM('ar').format(DateTime.now())}',
        'value': worst['value'],
      };
    } else if (filter == 'yearly') {
      final aggregated = getAggregatedChartData();
      if (aggregated.isEmpty) return {'title': 'أقل شهر', 'label': 'الشهر', 'sublabel': '', 'value': 0};
      var worst = aggregated.first;
      for (var a in aggregated) {
        if ((a['value'] as int) < (worst['value'] as int)) worst = a;
      }
      return {
        'title': 'أقل شهر',
        'label': worst['label'],
        'sublabel': '${selectedYear.value}',
        'value': worst['value'],
      };
    } else {
      final logs = weeklyLogs;
      if (logs.isEmpty) return {'title': 'أقل يوم', 'label': 'اليوم', 'sublabel': '', 'value': stepsToday.value};
      StepLog worst = logs.first;
      for (var l in logs) {
        if (l.steps < worst.steps) worst = l;
      }
      return {
        'title': 'أقل يوم',
        'label': DateFormat.E('ar').format(worst.date),
        'sublabel': DateFormat('d MMM', 'ar').format(worst.date),
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

    // For yearly, fetch from install date to get all available years
    final startBoundary = DateTime(installDate.year, installDate.month, installDate.day);
    yearlyLogs.assignAll(await _repository.getLogsInRange(startBoundary, now));

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
    final todayLog = logMap[todayKey];
    final int todaySteps = stepsToday.value;
    final int todayGoal = todayLog?.goal ?? dailyGoal.value;
    
    if (todaySteps >= todayGoal && todayGoal > 0) {
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
    talker.info('🔥 Streak calculated: $streak days (today: $todaySteps/$todayGoal)');
  }

  void _evaluateAchievements() {
    final startBoundary = DateTime(installDate.year, installDate.month, installDate.day);
    
    // Filter data for Achievements: Only count logs >= installDate
    final validWeeklyLogs = weeklyLogs.where((l) => !l.date.isBefore(startBoundary)).toList();
    
    // Calculate effective total since install (for medals)
    // Note: totalStepsAllTime still shows historical data for the chart/stats
    int totalSinceInstall = stepsToday.value;
    if (validWeeklyLogs.isNotEmpty) {
      // Avoid double counting today if it's in weeklyLogs
      totalSinceInstall = validWeeklyLogs.fold<int>(0, (p, e) => p + e.steps);
    }
    
    final todaySteps = stepsToday.value;
    final maxInWeek = validWeeklyLogs.isNotEmpty 
        ? validWeeklyLogs.map((e) => e.steps).reduce((a, b) => a > b ? a : b)
        : 0;
        
    // Calculate current streak from valid logs
    int streak = 0;
    for (var log in validWeeklyLogs) {
      if (log.steps >= log.goal) {
        streak++;
      } else {
        break;
      }
    }

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
          prog = unlocked ? 1.0 : (todaySteps / dailyGoal.value).clamp(0, 1);
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
          unlocked = isWeekend && todaySteps >= 20000 && !DateTime.now().isBefore(startBoundary);
          prog = (todaySteps / 20000).clamp(0, 1);
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
      title: 'إنجاز جديد! 🎖️',
      body: 'تهانينا! لقد حصلت على وسام: ${achievement.titleKey.tr}',
      bigText: 'إنجاز جديد! 🎖️\n\nلقد حصلت على وسام: ${achievement.titleKey.tr}\n${achievement.descKey.tr}\n\nاستمر في التقدم لتحقيق المزيد من الإنجازات! 💪',
      largeIcon: 'achievement',
    );
  }

  double get progress => dailyGoal.value > 0 ? (stepsToday.value / dailyGoal.value).clamp(0.0, 1.0) : 0.0;
  
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
    if (newGoal <= 0 || newGoal > 200000) return; // Reasonable bounds
    dailyGoal.value = newGoal;
    dailyGoalController.text = newGoal.toString();
    _storage.write('daily_step_goal', newGoal);
    _hasNotified80 = false; // Reset notification for new goal
    syncData(); 
  }

  bool _hasNotifiedGoal = false;

  void _check80PercentGoal() {
    if (progress >= 0.8 && !_hasNotified80 && stepsToday.value < dailyGoal.value) {
      _hasNotified80 = true;
      final remaining = (dailyGoal.value - stepsToday.value).clamp(0, 999999);
      _notificationService.showSmartStepsNotification(
        id: 80,
        title: 'أنت قريـب جداً! 🔥',
        body: 'فقط $remaining خطوة وتصل للقمة',
        bigText: 'فقط $remaining خطوة وتصل للقمة! 💪\nهدفك اليوم ${dailyGoal.value} خطوة، أنت قريب من إنجازه!',
        largeIcon: 'walker',
      );
    }
  }

  void _checkGoalCompletion() {
    if (progress >= 1.0 && !_hasNotifiedGoal) {
      _hasNotifiedGoal = true;
      _notificationService.showSmartStepsNotification(
        id: 100,
        title: 'بطل حقيقي! 🏆🎉',
        body: 'لقد حطمت هدفك اليومي بنجاح!',
        bigText: 'لقد حطمت هدفك اليومي بنجاح! 🎉\n${stepsToday.value} خطوة من ${dailyGoal.value}\nاحرص على الراحة والنوم الجيد الليلة 😴',
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

  /// ✅ Bug Fix: Made async to fetch todayLog instead of passing null.
  /// Previously, saving biometrics would LOSE real sensor data and replace
  /// it with estimates. Now it re-fetches the log to preserve sensor priority.
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
    final todayLog = await _repository.getStepLog(DateTime.now());
    _recalculateTodayMetrics(todayLog);
  }

  /// ✅ Bug Fix: Removed redundant _recalculateTodayMetrics(null).
  /// syncData() already calls _recalculateTodayMetrics(todayLog) with the
  /// correct log. Calling it with null first would briefly flash wrong
  /// estimated values before syncData overwrites them with sensor data.
  void updateDailyGoal(int newGoal) {
    dailyGoal.value = newGoal;
    _storage.write('daily_step_goal', newGoal);
    syncData();
  }

  /// Expert-Grade Metrics Engine.
  /// 
  /// Priority chain:
  /// 1. Real sensor data from Health Connect (if non-zero AND non-manual)
  /// 2. High-precision biomechanical estimation (stride × weight formula)
  ///
  /// ✅ Bug Fix: Previously, sensor data with 0 calories/distance (common when
  /// Health Connect returns steps but no energy/distance data) would be accepted
  /// as-is, showing "0 سعرة" and "0.00 كم" even though the user walked thousands
  /// of steps. Now we detect this case and fall through to estimation.
  void _recalculateTodayMetrics(StepLog? log) {
    final steps = stepsToday.value;
    
    // Logic 1: Use real sensor data ONLY if it's verified AND has meaningful values
    if (log != null && !log.isManual) {
      final bool hasSensorCalories = log.calories > 0;
      final bool hasSensorDistance = log.distance > 0;
      
      if (hasSensorCalories && hasSensorDistance) {
        // Full sensor data available — use it directly
        caloriesToday.value = log.calories;
        distanceToday.value = log.distance / 1000; // meters → km
        return;
      }
      
      // Partial sensor data: use what's available, estimate the rest
      if (hasSensorDistance) {
        distanceToday.value = log.distance / 1000;
        // Estimate calories from real distance + weight
        final w = userWeight.value ?? 70.0;
        caloriesToday.value = distanceToday.value * w * 0.73;
        _persistRecalculatedMetrics(steps, caloriesToday.value, distanceToday.value * 1000);
        return;
      }
      
      if (hasSensorCalories) {
        caloriesToday.value = log.calories;
        // Estimate distance from steps + stride
        final h = userHeight.value ?? 170.0;
        final g = userGender.value ?? 'male';
        final multiplier = g == 'female' ? 0.413 : 0.415;
        final strideLength = (h / 100) * multiplier;
        distanceToday.value = (steps * strideLength) / 1000;
        _persistRecalculatedMetrics(steps, caloriesToday.value, distanceToday.value * 1000);
        return;
      }
      
      // Sensor returned 0 for both — fall through to full estimation
    }

    // Logic 2: Biomechanical Estimation (Doctoral Formula)
    final h = userHeight.value ?? 170.0;
    final w = userWeight.value ?? 70.0;
    final g = userGender.value ?? 'male';

    // Stride Length in meters (research-backed multipliers)
    final multiplier = g == 'female' ? 0.413 : 0.415;
    final strideLength = (h / 100) * multiplier;

    // Distance in km
    final dist = (steps * strideLength) / 1000;
    distanceToday.value = dist;

    // Calories: MET-based walking energy expenditure
    final cals = dist * w * 0.73;
    caloriesToday.value = cals;

    // ✅ Synchronize with Isar so Home Dashboard updates instantly
    _persistRecalculatedMetrics(steps, cals, dist * 1000);
  }

  /// ✅ Professional Persistence: Ensures Home Dashboard (Isar Watcher) sees estimates immediately
  Future<void> _persistRecalculatedMetrics(int steps, double calories, double distanceInMeters) async {
    if (steps == 0 && calories == 0) return;
    
    await _repository.updateStepsLocally(
      DateTime.now(),
      steps,
      isManual: false,
      calories: calories,
      distance: distanceInMeters,
    );
  }
}
