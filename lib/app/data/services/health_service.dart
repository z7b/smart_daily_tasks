import 'package:get/get.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:isar/isar.dart';
import 'package:smart_daily_tasks/app/core/helpers/log_helper.dart';
import 'package:smart_daily_tasks/app/data/models/step_log_model.dart';

class HealthService extends GetxService {
  final Isar _isar;
  HealthService(this._isar);

  final Health health = Health();
  
  final isAuthorized = false.obs;
  final isConnecting = false.obs;

  /// types of data we want to read
  static const types = [
    HealthDataType.STEPS,
  ];

  /// permissions for each type
  static const permissions = [
    HealthDataAccess.READ,
  ];

  Future<HealthService> init() async {
    // 🔥 Ensure Health Connect is explicitly used for Android 14+ 
    if (GetPlatform.isAndroid) {
      health.configure();
    }
    talker.info('🏥 HealthService initialized');
    await checkAuthorization();
    return this;
  }

  Future<void> checkAuthorization() async {
    try {
      // Activity recognition is needed on Android for manual step tracking fallback
      final status = await Permission.activityRecognition.status;
      isAuthorized.value = status.isGranted;
    } catch (e) {
      talker.error('Error checking health auth: $e');
    }
  }

  Future<bool> requestPermissions() async {
    isConnecting.value = true;
    try {
      // 1. Android Activity Recognition Permission
      if (GetPlatform.isAndroid) {
        final activityStatus = await Permission.activityRecognition.request();
        if (!activityStatus.isGranted) {
          talker.warning('⚠️ Activity Recognition denied');
          return false;
        }
      }

      // 2. Health Connect / Google Fit Permissions
      bool requested = await health.requestAuthorization(types, permissions: permissions);
      
      if (requested) {
        isAuthorized.value = true;
        talker.info('✅ Health Access Granted');
        await syncSteps();
      } else {
        talker.warning('❌ Health Access Denied by user');
      }
      return requested;
    } catch (e) {
      talker.error('🔴 Health Permission Error: $e');
      return false;
    } finally {
      isConnecting.value = false;
    }
  }

  Future<void> syncSteps() async {
    if (!isAuthorized.value) return;

    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      
      // Fetch steps from health plugin
      int? steps = await health.getTotalStepsInInterval(midnight, now);
      
      if (steps != null) {
        talker.info('👣 Syncing Steps: $steps');
        
        await _isar.writeTxn(() async {
          final existing = await _isar.stepLogs.filter().dateEqualTo(midnight).findFirst();
          
          if (existing != null) {
            existing.steps = steps;
            await _isar.stepLogs.put(existing);
          } else {
            final newLog = StepLog(date: midnight, steps: steps, goal: 10000);
            await _isar.stepLogs.put(newLog);
          }
        });
      }
    } catch (e) {
      talker.error('🔴 Step Sync Error: $e');
    }
  }
}
