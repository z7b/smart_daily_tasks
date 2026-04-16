import 'package:get/get.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:isar/isar.dart';
import '../../core/helpers/log_helper.dart';
import '../models/step_log_model.dart';
import 'dart:async';

class HealthService extends GetxService {
  final Isar _isar;
  HealthService(this._isar);

  final Health health = Health();

  final isAuthorized = false.obs;
  final isConnecting = false.obs;
  final isHandshaking = false.obs;

  // ✅ Official Expert Mapping: Unified types for Google Fit, S-Health & Apple Health
  final List<HealthDataType> types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.BASAL_ENERGY_BURNED, // Mandatory for parity
  ];

  final List<HealthDataAccess> permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  Future<HealthService> init() async {
    try {
      // 🔥 Android 16 Handshake: Configure bridge during initialization
      await health.configure();
      talker.info('🏥 Health Service Configured for Life OS (Unified)');
      await checkAuthorization();
    } catch (e) {
      talker.error('❌ Health Service Init Error: $e');
    }
    return this;
  }

  Future<void> checkAuthorization() async {
    try {
      // Robust multi-stage check for Android 16
      final activityStatus = await Permission.activityRecognition.status;
      bool? hasHealth = await health.hasPermissions(types, permissions: permissions);
      
      isAuthorized.value = activityStatus.isGranted && (hasHealth ?? false);
      talker.info('📊 Centralized Health Status: ${isAuthorized.value}');
    } catch (e) {
      talker.error('⚠️ Error checking centralized auth: $e');
    }
  }

  /// Master Handshake: Official Pulse Activation (Android 16 & iOS)
  Future<bool> requestPermissions() async {
    if (isHandshaking.value) return false;
    
    isHandshaking.value = true;
    isConnecting.value = true;

    try {
      // 1. Android Activity Recognition (Native Sensor Handshake)
      talker.info('🛡️ Requesting Activity Recognition (Trust Handshake)...');
      if (await Permission.activityRecognition.request().isDenied) {
        talker.warning('🚫 Activity Recognition denied - Handshake aborted');
        return false;
      }

      // 2. Official Health Interface (Health Connect / HealthKit)
      talker.info('🏥 Official Handshake: Requesting Health Connect/HealthKit access...');
      bool granted = await health.requestAuthorization(types, permissions: permissions);
      
      // ✅ Expert Fallback: Partial Authorization Resilience
      if (!granted) {
        talker.info('⚠️ Full handshake failed. Checking for partial sensor access...');
        bool? hasSteps = await health.hasPermissions([HealthDataType.STEPS]);
        if (hasSteps ?? false) {
          talker.info('✅ Handshake Verified: Steps access remains active');
          granted = true; 
        }
      }

      if (granted) {
        talker.info('🔥 Master Handshake Success: Official Pulse Active');
        isAuthorized.value = true;
        await fetchAndPersistSteps();
      } else {
        talker.warning('❌ Master Handshake Denied: User rejected access');
        isAuthorized.value = false;
      }
      
      return granted;
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Fatal Master Handshake Failure');
      return false;
    } finally {
      isConnecting.value = false;
      Future.delayed(const Duration(seconds: 3), () => isHandshaking.value = false);
    }
  }

  /// Master Intelligence Sync: Multi-Strategy Data Acquisition
  Future<int> fetchAndPersistSteps() async {
    if (!isAuthorized.value) {
      talker.warning('⚠️ Sync blocked: Not authorized');
      return 0;
    }

    try {
      final now = DateTime.now();
      // Apply 1-minute buffer for Android 16 Health Connect stability
      final endRange = now.subtract(const Duration(minutes: 1));
      final midnight = DateTime(now.year, now.month, now.day);
      
      talker.info('📥 Life OS Pulse: Auditing health data since midnight ($midnight)');
      
      // Strategy 1: Aggregated Count (High Performance)
      int? steps = await health.getTotalStepsInInterval(midnight, endRange);
      
      // Strategy 2: Raw Point Sum (Samsung Health Resilience)
      if (steps == null || steps == 0) {
        talker.info('🔍 Strategy 1 returned $steps. Launching Strategy 2 (Point Sum)...');
        final rawData = await health.getHealthDataFromTypes(
          types: [HealthDataType.STEPS],
          startTime: midnight,
          endTime: endRange,
        );
        if (rawData.isNotEmpty) {
           steps = 0;
           for (var d in rawData) {
              final val = d.value;
              if (val is NumericHealthValue) {
                steps = steps! + val.numericValue.toInt();
              }
           }
           talker.info('✅ Strategy 2 recovered $steps steps');
        }
      }

      // Strategy 3: Historical Deep Diagnostics (The "Proof of Life" sync)
      if (steps == null || steps == 0) {
        talker.info('🛰️ All strategies returned 0. Checking last 24h as a diagnostic probe...');
        final diagnosticStart = now.subtract(const Duration(hours: 24));
        final diagSteps = await health.getTotalStepsInInterval(diagnosticStart, endRange);
        if (diagSteps != null && diagSteps > 0) {
           talker.info('📈 Diagnostic Success: Sensor is active, but today is empty ($diagSteps steps found in 24h)');
        } else {
           talker.warning('📉 Diagnostic Alert: Zero data detected in full 24h cycle');
        }
      }

      if (steps != null) {
        talker.info('🏆 Sync Finalized: $steps steps');
        
        await _isar.writeTxn(() async {
          final existing = await _isar.stepLogs.filter().dateEqualTo(midnight).findFirst();
          if (existing != null) {
            if (!existing.isManual) {
               existing.steps = steps!;
               await _isar.stepLogs.put(existing);
               talker.info('💾 Isar: Updated cached record');
            } else {
               talker.info('⛔ Isar: Skipped update (Manual mode protected)');
            }
          } else {
            final newLog = StepLog(date: midnight, steps: steps!, goal: 10000);
            await _isar.stepLogs.put(newLog);
            talker.info('💾 Isar: New daily record created');
          }
        });
        return steps;
      }
      return 0;
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Fatal Master Sync Failure');
      return 0;
    }
  }
}
