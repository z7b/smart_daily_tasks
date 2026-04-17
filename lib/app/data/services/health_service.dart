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
      // ✅ Step 1: Configure Health
      await health.configure();
      talker.info('🏥 Health Service Configured for Life OS (Unified)');
      
      // ✅ Step 2: Check permissions
      await checkAuthorization();
      
      // ✅ Step 3: Request if not authorized, else sync
      if (!isAuthorized.value) {
        talker.warning('⚠️ Not authorized - requesting permissions...');
        await requestPermissions();
      } else {
        talker.info('✅ Already authorized - syncing steps');
        await fetchAndPersistSteps();
      }
    } catch (e, stack) {
      talker.handle(e, stack, '❌ Health Service Init Error');
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
      
      // ✅ Fix 1: Use exact current time (include current second)
      final endRange = now.add(const Duration(seconds: 1));
      
      // ✅ Fix 2: Proper midnight normalization
      final midnight = DateTime(now.year, now.month, now.day);
      
      talker.info('''
      📥 Life OS Pulse: Auditing health data 
      From: $midnight
      To:   $endRange
      Duration: ${endRange.difference(midnight).inHours}h
      ''');
      
      // ✅ Strategy 1: Aggregated Count
      int? steps = await health.getTotalStepsInInterval(midnight, endRange);
      
      talker.info('Strategy 1 Result: $steps steps');
      
      // ✅ Strategy 2: Raw Point Sum (Fallback for some integrations)
      if (steps == null || steps == 0) {
        talker.info('🔍 Attempting Strategy 2: Point Sum...');
        try {
          final rawData = await health.getHealthDataFromTypes(
            types: [HealthDataType.STEPS],
            startTime: midnight,
            endTime: endRange,
          );
          
          talker.info('📊 Raw data points: ${rawData.length}');
          
          if (rawData.isNotEmpty) {
            steps = 0;
            for (var d in rawData) {
              final val = d.value;
              if (val is NumericHealthValue) {
                steps = steps! + val.numericValue.toInt();
                talker.info('  └─ Point: ${val.numericValue.toInt()}');
              }
            }
            talker.info('✅ Strategy 2 recovered $steps steps');
          }
        } catch (e) {
          talker.error('Strategy 2 failed: $e');
        }
      }

      // ✅ Strategy 3: Historical Deep Diagnostics
      if (steps == null || steps == 0) {
        talker.info('🛰️ Running 24h diagnostic probe...');
        try {
          final diagnosticStart = now.subtract(const Duration(hours: 24));
          final diagSteps = await health.getTotalStepsInInterval(diagnosticStart, endRange);
          
          if (diagSteps != null && diagSteps > 0) {
             talker.warning('''
             📉 Diagnostic Alert: 
             - Today: 0 steps
             - Last 24h: $diagSteps steps
             - Possible cause: Sensor offline or permission issue
             ''');
          } else {
             talker.critical('''
             🚨 Critical Alert:
             - Zero data in 24h window
             - Sensor may be disconnected
             - Check: Activity Recognition permission
             ''');
          }
        } catch (e) {
          talker.error('Diagnostic failed: $e');
        }
      }

      // ✅ Convert to 0 if all failed instead of crashing
      steps = steps ?? 0;

      if (steps >= 0) {
        talker.info('🏆 Sync Finalized: $steps steps');
        
        await _isar.writeTxn(() async {
          final existing = await _isar.stepLogs
              .filter()
              .dateEqualTo(midnight)
              .findFirst();
              
          if (existing != null) {
            if (!existing.isManual) {
               existing.steps = steps!;
               existing.lastSyncedAt = now;
               await _isar.stepLogs.put(existing);
               talker.info('💾 Updated: ${existing.steps} steps');
            } else {
               // ✅ Critical Fix: Merge sensor data with manual entry (take higher value)
               // Previously this blocked sync forever after any manual entry
               if (steps! > existing.steps) {
                 existing.steps = steps;
                 existing.isManual = false; // Sensor took over
                 existing.lastSyncedAt = now;
                 await _isar.stepLogs.put(existing);
                 talker.info('💾 Sensor override: ${existing.steps} steps (was manual)');
               } else {
                 talker.info('⛔ Manual value higher (${ existing.steps} > $steps), keeping manual');
               }
            }
          } else {
            final newLog = StepLog(
              date: midnight,
              steps: steps!,
              goal: 10000,
              isManual: false,
              lastSyncedAt: now,
            );
            await _isar.stepLogs.put(newLog);
            talker.info('💾 Created new record: ${newLog.steps} steps');
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
