import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import '../../../data/models/step_log_model.dart';
import '../../../data/providers/step_repository.dart';
import '../../../data/services/health_service.dart';
import '../../../core/helpers/log_helper.dart';
import 'dart:async';

class StepsController extends GetxController with WidgetsBindingObserver {
  final StepRepository _repository = Get.find<StepRepository>();
  final HealthService _healthService = Get.find<HealthService>();
  final _storage = GetStorage();

  final stepsToday = 0.obs;
  final dailyGoal = 10000.obs;
  final isLoading = false.obs;
  
  // Bind UI reactivity to centralized HealthService
  RxBool get isHealthAuthorized => _healthService.isAuthorized;
  
  // Controllers for manual input
  final dailyGoalController = TextEditingController();
  final manualStepsController = TextEditingController();
  
  // Historical Data
  final weeklyLogs = <StepLog>[].obs;
  final monthlyLogs = <StepLog>[].obs;
  final yearlyLogs = <StepLog>[].obs;
  final totalStepsAllTime = 0.obs;
  final _isSyncing = false.obs; // Logic guard

  Timer? _pollTimer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    
    final savedGoal = _storage.read('daily_step_goal') ?? 10000;
    dailyGoal.value = savedGoal;
    dailyGoalController.text = savedGoal.toString();
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
    manualStepsController.dispose();
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
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (isHealthAuthorized.value && !isLoading.value && !_isSyncing.value) {
        talker.info('⏱️ Real-time Polling Triggered (60s)');
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
      
      if (isHealthAuthorized.value) {
        // Fetch from Master Sensor Authority
        final sensorSteps = await _healthService.fetchAndPersistSteps();
        
        // Sync historical window (7 days) for data integrity
        for (int i = 0; i < 7; i++) {
          final date = today.subtract(Duration(days: i));
          if (i == 0) {
             stepsToday.value = sensorSteps;
          } else {
             // For history, we fetch from sensor if needed, or at least ensure repo is valid
             await _repository.getStepLog(date);
          }
        }
      } else {
        // Fallback: Read from local Isar cache
        final todayLog = await _repository.getStepLog(today);
        stepsToday.value = todayLog?.steps ?? 0;
      }

      _loadHistoricalStats();
      totalStepsAllTime.value = await _repository.getTotalStepsForAllTime();
      
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 StepsController Sync Error');
    } finally {
      isLoading.value = false;
      _isSyncing.value = false;
    }
  }

  Future<void> _loadHistoricalStats() async {
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));
    weeklyLogs.assignAll(await _repository.getLogsInRange(weekStart, now));

    final monthStart = DateTime(now.year, now.month, 1);
    monthlyLogs.assignAll(await _repository.getLogsInRange(monthStart, now));

    final yearStart = DateTime(now.year - 1, now.month, now.day);
    yearlyLogs.assignAll(await _repository.getLogsInRange(yearStart, now));
  }

  double get progress => dailyGoal.value > 0 ? (stepsToday.value / dailyGoal.value).clamp(0.0, 1.0) : 0.0;

  void updateGoal(int newGoal) {
    if (newGoal <= 0 || newGoal > 200000) return; // Reasonable bounds
    dailyGoal.value = newGoal;
    dailyGoalController.text = newGoal.toString();
    _storage.write('daily_step_goal', newGoal);
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
      Get.back();
    } catch (e) {
      talker.error('Failed to add manual steps: $e');
    }
  }
}
