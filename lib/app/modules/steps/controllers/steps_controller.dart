import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import '../../../data/models/step_log_model.dart';
import '../../../data/providers/step_repository.dart';
import '../../../core/helpers/log_helper.dart';

class StepsController extends GetxController {
  final StepRepository _repository = Get.find<StepRepository>();
  final _storage = GetStorage();

  final stepsToday = 0.obs;
  final dailyGoal = 10000.obs;
  final isLoading = false.obs;
  final isHealthAuthorized = false.obs;
  
  // Controllers for manual input
  final dailyGoalController = TextEditingController();
  final manualStepsController = TextEditingController();
  
  // Historical Data
  final weeklyLogs = <StepLog>[].obs;
  final monthlyLogs = <StepLog>[].obs;
  final yearlyLogs = <StepLog>[].obs;

  final totalStepsAllTime = 0.obs;

  @override
  void onInit() {
    super.onInit();
    final savedGoal = _storage.read('daily_step_goal') ?? 10000;
    dailyGoal.value = savedGoal;
    dailyGoalController.text = savedGoal.toString();
    checkPermissionStatus();
    syncData();
  }

  Future<void> checkPermissionStatus() async {
    isHealthAuthorized.value = await _repository.hasPermissions();
  }

  Future<void> requestHealthPermission() async {
    final granted = await _repository.requestPermissions();
    isHealthAuthorized.value = granted;
    if (granted) syncData();
  }

  Future<void> syncData() async {
    if (isLoading.value) return;
    
    try {
      isLoading.value = true;
      talker.info('🔄 Syncing Life OS Steps...');
      
      final today = DateTime.now();
      
      // 1. Sync data for last 7 days from health sensors (If permitted)
      if (isHealthAuthorized.value) {
        for (int i = 0; i < 7; i++) {
          final date = today.subtract(Duration(days: i));
          final count = await _repository.syncStepsForDate(date);
          if (i == 0) stepsToday.value = count;
        }
      } else {
        // Fallback: Read from local Isar cache for today
        final todayLog = await _repository.getStepLog(today);
        stepsToday.value = todayLog?.steps ?? 0;
      }

      // 2. Load historical data from Isar
      _loadHistoricalStats();
      
      totalStepsAllTime.value = await _repository.getTotalStepsForAllTime();
      
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 StepsController Sync Error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadHistoricalStats() async {
    final now = DateTime.now();
    
    // Weekly
    final weekStart = now.subtract(const Duration(days: 7));
    weeklyLogs.assignAll(await _repository.getLogsInRange(weekStart, now));

    // Monthly
    final monthStart = DateTime(now.year, now.month, 1);
    monthlyLogs.assignAll(await _repository.getLogsInRange(monthStart, now));

    // Yearly (Simulated for this MVP - last 12 months)
    final yearStart = DateTime(now.year - 1, now.month, now.day);
    yearlyLogs.assignAll(await _repository.getLogsInRange(yearStart, now));
  }

  double get progress => dailyGoal.value > 0 ? (stepsToday.value / dailyGoal.value).clamp(0.0, 1.0) : 0.0;

  void updateGoal(int newGoal) {
    dailyGoal.value = newGoal;
    dailyGoalController.text = newGoal.toString();
    _storage.write('daily_step_goal', newGoal);
    talker.info('🎯 New Step Goal persisted: $newGoal');
    syncData(); 
  }

  Future<void> addManualSteps() async {
    final stepsStr = manualStepsController.text;
    if (stepsStr.isEmpty) return;
    
    final int? additionalSteps = int.tryParse(stepsStr);
    if (additionalSteps == null || additionalSteps <= 0) return;

    try {
      final newTotal = await _repository.updateStepsLocally(DateTime.now(), additionalSteps, isManual: true);
      stepsToday.value = newTotal;
      manualStepsController.clear();
      _loadHistoricalStats();
      Get.back(); // Close dialog
      Get.snackbar('success'.tr, 'steps_added'.tr, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      talker.error('Failed to add manual steps: $e');
    }
  }
}
