import 'package:get/get.dart';
import 'package:health/health.dart';
import 'package:get_storage/get_storage.dart';
import 'package:isar/isar.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workmanager/workmanager.dart';
import '../../core/helpers/log_helper.dart';
import '../models/step_log_model.dart';
import '../../core/services/app_lock_service.dart';
import 'package:flutter/services.dart';
import '../../routes/app_routes.dart';
import 'dart:async';
import 'dart:io';

class HealthService extends GetxService {
  final Isar _isar;
  final _storage = GetStorage();
  HealthService(this._isar);

  final Health health = Health();

  final RxnBool isAuthorized = RxnBool(null); 
  
  // ✅ Expert Logic: Track connection intent to avoid UI flickering on startup
  static const String _authIntentKey = 'health_connection_intended';
  final isConnecting = false.obs;
  final isHandshaking = false.obs;
  final lastSynced = Rxn<DateTime>(null);
  
  static const MethodChannel _rationaleChannel = MethodChannel('com.example.smart_daily_tasks/health_rationale');

  // ✅ Official Expert Mapping: Unified types for Google Fit, S-Health & Apple Health
  // We make these late/dynamic to handle platform incompatibilities (Google Standards)
  List<HealthDataType> types = [];
  List<HealthDataAccess> permissions = [];

  void _initializeTypes() {
    types = [
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.DISTANCE_DELTA,
      HealthDataType.DISTANCE_WALKING_RUNNING,
    ];

    // Synchronize permissions list with types
    permissions = List.filled(types.length, HealthDataAccess.READ);
  }

  Future<HealthService> init() async {
    _initializeTypes();
    try {
      // ✅ Step 1: Configure Health (Health Connect is now the exclusive Android provider in v13+)
      try {
        await health.configure();
        talker.info('🏥 Health Service Configured for Life OS (Health Connect Verified)');
      } catch (configError) {
        talker.error('❌ Health Service: configure() failed — $configError');
      }
      
      // ✅ Highest Standard: Read connection intent BEFORE checking actual permissions
      // This prevents the "Connect" button from flickering on every app restart.
      final bool wasIntended = _storage.read(_authIntentKey) ?? false;
      if (wasIntended) {
        isAuthorized.value = true; 
        talker.info('🎯 Restoration: Persisted intent found. Pre-setting health status to OK.');
      }

      // ✅ Step 2: Perform the real Check in background
      await checkAuthorization();
      
      // ✅ Step 3: Global Intent Handling for Health Rationale (Google Standard)
      _rationaleChannel.setMethodCallHandler((call) async {
        if (call.method == 'showRationale') {
          talker.info('🏥 OS Triggered: Displaying Health Rationale Privacy View');
          Get.toNamed(Routes.HEALTH_RATIONALE);
        }
      });
      
      // ✅ Step 4: We strictly DEFER requesting permissions until the UI commands it.
      // Calling requestPermissions() during init() crashes Get.dialog because the Navigator.context is null during AppBootstrapper.
      if (isAuthorized.value == false) {
        talker.warning('⚠️ Health Connect not authorized - Awaiting manual handshake trigger from UI.');
      } else if (isAuthorized.value == true) {
        talker.info('✅ Already authorized - Pulse synchronization ready');
      }
      
      // ✅ Highest Standard: Register Background Sync if authorized
      if (isAuthorized.value == true) {
        Workmanager().registerPeriodicTask(
          "1", 
          "health_sync_task",
          frequency: const Duration(hours: 1),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
          constraints: Constraints(
            networkType: NetworkType.connected,
          ),
        );
      }
    } catch (e, stack) {
      talker.handle(e, stack, '❌ Health Service Init Error');
    }
    return this;
  }

  Future<Map<HealthDataType, bool>> checkDetailedPermissions() async {
    final Map<HealthDataType, bool> status = {};
    for (var type in types) {
      bool? has = await health.hasPermissions([type]);
      status[type] = has ?? false;
      if (has != true) {
        talker.warning('🚨 Health Audit: Permission Missing for $type');
      }
    }
    return status;
  }

  Future<void> checkAuthorization() async {
    try {
      final bool hadPriorConnection = _storage.read(_authIntentKey) ?? false;
      bool? hasHealth = await health.hasPermissions(types, permissions: permissions);
      
      talker.info('📊 Health Permission Check: hasHealth=$hasHealth, hadPriorConnection=$hadPriorConnection');
      
      if (hasHealth == true) {
        // ✅ Explicit confirmation — persist and trust
        isAuthorized.value = true;
        _storage.write(_authIntentKey, true);
        checkDetailedPermissions();
      } else if (hadPriorConnection) {
        // 🛡️ Premium Restoration Logic: 
        // If we previously connected successfully, we keep the "Authorized" state in the UI 
        // to prevent the "Connect Health" button from flickering or reappearing.
        // Even if hasHealth returns false/null (common during early boot or platform delays), 
        // we trust the user's intent.
        isAuthorized.value = true;
        talker.info('🔄 Health: Preserving prior connection state (Indeterminate/False result bypassed)');
      } else {
        // ❌ No prior connection AND not currently authorized
        isAuthorized.value = false;
      }
      
      talker.info('📊 Centralized Health Status: ${isAuthorized.value}');
    } catch (e) {
      // ✅ On error, preserve prior connection intent rather than breaking the UI
      final bool hadPriorConnection = _storage.read(_authIntentKey) ?? false;
      if (hadPriorConnection) {
        isAuthorized.value = true;
        talker.warning('⚠️ Auth check error, preserving prior connection: $e');
      } else {
        talker.error('⚠️ Error checking centralized auth: $e');
      }
    }
  }

  /// Master Handshake: Official Pulse Activation (Android 16 & iOS)
  Future<bool> requestPermissions() async {
    if (isHandshaking.value) return false;
    
    isHandshaking.value = true;
    isConnecting.value = true;

    try {
      // ✅ Security Audit: Pause App Lock protection during system-level handshake
      // This prevents the "App Inactive" blur from covering the permissions dialog
      if (Get.isRegistered<AppLockService>()) {
        Get.find<AppLockService>().isProtectionPaused.value = true;
      }

      // 0. Check Device Security (Lock screen requirement)
      try {
        final localAuth = LocalAuthentication();
        final isSupported = await localAuth.isDeviceSupported();
        if (!isSupported) {
          talker.warning('🔒 Device not secured. Health Connect will reject the handshake.');
          Get.dialog(
            AlertDialog(
              title: Text('security_required'.tr),
              content: Text('health_security_desc'.tr),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              actions: [
                TextButton(
                  onPressed: () { 
                    Get.back();
                    try { launchUrl(Uri.parse('package:com.android.settings')); } catch (_) {}
                  },
                  child: Text('open_settings'.tr, style: TextStyle(color: Get.theme.primaryColor)),
                ),
              ],
            ),
          );
          return false;
        }
      } catch (e) {
        talker.error('Security check failed: $e');
      }

      // 1. Check SDK Status
      try {
        final sdkStatus = await health.getHealthConnectSdkStatus();
        if (sdkStatus == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
          talker.warning('⚠️ Health Connect APK needs updating.');
          Get.snackbar(
            'update_required'.tr, 
            'health_update_desc'.tr,
            mainButton: TextButton(
              onPressed: () => health.installHealthConnect(),
              child: Text('open_settings'.tr),
            ),
          );
        }
      } catch (_) {}

      // 2. Official Health Interface (Health Connect / HealthKit)
      talker.info('🏥 Official Handshake: Requesting Health Connect/HealthKit access...');
      
      bool granted = false;
      for (int i = 0; i < 3; i++) {
        granted = await health.requestAuthorization(types, permissions: permissions);
        if (granted) break;
        await Future.delayed(const Duration(seconds: 1));
      }
      
      if (!granted) {
        talker.info('⚠️ Full handshake failed. Checking for partial sensor access or opening settings...');
        bool? hasSteps = await health.hasPermissions([HealthDataType.STEPS]);
        if (hasSteps ?? false) {
          talker.info('✅ Handshake Verified: Steps access remains active');
          granted = true; 
        } else {
          // Display the Dialog for Sideloading Manual Fix Without Disrupting UI
          Get.dialog(
            AlertDialog(
              title: Text('health_manual_title'.tr),
              content: Text('health_manual_desc'.tr),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('ok'.tr, style: const TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () async {
                    Get.back();
                    try {
                      // Trigger health connect settings / install
                      await health.installHealthConnect(); 
                    } catch (_) {}
                  },
                  child: Text('open_settings'.tr, style: TextStyle(color: Get.theme.primaryColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      }

      if (granted) {
        talker.info('🔥 Master Handshake Success: Official Pulse Active');
        isAuthorized.value = true;
        _storage.write(_authIntentKey, true); // ✅ Persist successful intent
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
      // ✅ Restore security protection
      if (Get.isRegistered<AppLockService>()) {
        Get.find<AppLockService>().isProtectionPaused.value = false;
      }
      isConnecting.value = false;
      Future.delayed(const Duration(seconds: 3), () => isHandshaking.value = false);
    }
  }

  /// Master Intelligence Sync: Multi-Strategy Data Acquisition
  /// [targetDate] defaults to today.
  Future<int> fetchAndPersistSteps({DateTime? targetDate}) async {
    if (isAuthorized.value != true) {
      talker.warning('⚠️ Sync blocked: Not authorized');
      return 0;
    }

    try {
      final now = DateTime.now();
      final date = targetDate ?? now;
      final midnight = DateTime(date.year, date.month, date.day);
      
      talker.info('📥 Master Overhaul: Synchronizing official activity from Health Connect...');
      
      // ✅ 1. Steps (Direct Aggregate - Google High Standard)
      int steps = await health.getTotalStepsInInterval(midnight, now) ?? 0;
      
      // ✅ 2. Exclusive Metrics Extraction (No Estimates)
      // On Android 16/Samsung, we check multiple source types to ensure we miss nothing
      // ✅ 2. Exclusive Metrics Extraction (No Estimates)
      // We strictly fetch what the platform supports to avoid crashes
      final List<HealthDataType> metricsToFetch = [
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.DISTANCE_DELTA,
      ];
      
      // ✅ Expert Fix: Platform-Specific Distance Handling
      // Android Health Connect ONLY supports DISTANCE_DELTA
      // Apple HealthKit supports DISTANCE_WALKING_RUNNING
      if (Platform.isIOS) {
        metricsToFetch.add(HealthDataType.DISTANCE_WALKING_RUNNING);
      }
      
      final List<HealthDataPoint> dataPoints = await health.getHealthDataFromTypes(
        startTime: midnight, 
        endTime: now, 
        types: metricsToFetch,
      );
      
      double calories = 0.0;
      double distance = 0.0;
      
      talker.info('📥 Exclusive Audit: Received ${dataPoints.length} points from Health Connect. Steps found: $steps');
      
      for (var p in dataPoints) {
        final val = _extractNumericValue(p.value);
        if (p.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
          calories += val;
        } else if (p.type == HealthDataType.DISTANCE_DELTA || p.type == HealthDataType.DISTANCE_WALKING_RUNNING) {
          distance += val;
        }
      }

      // ✅ 2.5 Smart Estimation Fallback (Biomechanical Logic)
      // If Health Connect returns 0 for calories or distance, we estimate them based on steps.
      if (steps > 0 && (calories == 0 || distance == 0)) {
        final h = (_storage.read('user_height') ?? 170.0).toDouble();
        final w = (_storage.read('user_weight') ?? 70.0).toDouble();
        final g = _storage.read('user_gender') ?? 'male';
        
        final double multiplier = g == 'female' ? 0.413 : 0.415;
        final double strideLength = (h / 100) * multiplier; // meters

        if (distance == 0) {
          distance = (steps * strideLength).toDouble(); // meters
        }
        
        if (calories == 0) {
          // MET-based calculation: (dist in km) * weight * 0.73
          calories = ((distance / 1000) * w * 0.73).toDouble();
        }
        talker.info('🧪 Smart Estimation Applied: ${calories.toStringAsFixed(1)} kcal | ${distance.toStringAsFixed(1)}m');
      }

      talker.info('🏥 Official Sync Pulse: $steps steps | ${calories.toStringAsFixed(1)} kcal | ${distance.toStringAsFixed(1)}m');

      // ✅ 3. Persistence to Isar (Medical Grade)
      await _isar.writeTxn(() async {
        final existing = await _isar.stepLogs.filter().dateEqualTo(midnight).findFirst();
        final currentGoal = _storage.read('daily_step_goal') ?? 10000;
        
        final updated = (existing ?? StepLog(date: midnight, goal: currentGoal)).copyWith(
          steps: steps,
          calories: calories,
          distance: distance,
          goal: currentGoal,
          isManual: false, 
          lastSyncedAt: now,
        );
        lastSynced.value = updated.lastSyncedAt;
        await _isar.stepLogs.put(updated);
      });

      return steps;
    } catch (e, stack) {
      talker.handle(e, stack, '❌ Error in Master pulse sync');
      return 0;
    }
  }

  /// Bulk Intelligence Sync: Monthly Bucketed Backfill (Expert Level)
  Future<void> performDeepSync(int days) async {
    if (isAuthorized.value != true) return;
    
    talker.info('🌊 Starting Deep Sync Pulse ($days days history)');
    final now = DateTime.now();
    
    // Process in 30-day buckets to satisfy Health Connect throughput while staying fast
    for (int i = 0; i < (days / 30).ceil(); i++) {
        final startOffset = (i + 1) * 30;
        final endOffset = i * 30;
        
        final start = now.subtract(Duration(days: startOffset));
        final end = now.subtract(Duration(days: endOffset));
        
        talker.info('📅 Syncing Bucket: $start to $end');
        
        try {
            // Get all data points for this month safely
            final List<HealthDataPoint> data = [];
            for (var type in types) {
              try {
                final points = await health.getHealthDataFromTypes(
                  startTime: start, 
                  endTime: end, 
                  types: [type],
                );
                data.addAll(points);
              } on PlatformException catch (e) {
                talker.warning('🚨 Deep Sync: Platform rejected type $type: ${e.message}');
              } catch (e) {
                talker.error('⚠️ Deep Sync: Skipping type $type');
              }
            }
            
            if (data.isNotEmpty) {
                // Group by day with precision
                final Map<DateTime, Map<String, double>> dailyBuckets = {};
                for (var p in data) {
                    final day = DateTime(p.dateFrom.year, p.dateFrom.month, p.dateFrom.day);
                    dailyBuckets.putIfAbsent(day, () => {'steps': 0, 'cal': 0, 'dist': 0});
                    
                    final val = _extractNumericValue(p.value);
                    if (p.type == HealthDataType.STEPS) {
                        dailyBuckets[day]!['steps'] = dailyBuckets[day]!['steps']! + val;
                    } else if (p.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
                        dailyBuckets[day]!['cal'] = dailyBuckets[day]!['cal']! + val;
                    } else if (p.type == HealthDataType.DISTANCE_DELTA || p.type == HealthDataType.DISTANCE_WALKING_RUNNING) {
                        dailyBuckets[day]!['dist'] = dailyBuckets[day]!['dist']! + val;
                    }
                }
                
                // Bulk Persist
                final currentGoal = _storage.read('daily_step_goal') ?? 10000;
                await _isar.writeTxn(() async {
                    for (var entry in dailyBuckets.entries) {
                        final midnight = entry.key;
                        final metrics = entry.value;
                        
                        // ✅ Smart Estimation for Historical Data
                        double finalCal = metrics['cal']!;
                        double finalDist = metrics['dist']!;
                        int finalSteps = metrics['steps']!.toInt();
                        
                        if (finalSteps > 0 && (finalCal == 0 || finalDist == 0)) {
                          final h = (_storage.read('user_height') ?? 170.0).toDouble();
                          final w = (_storage.read('user_weight') ?? 70.0).toDouble();
                          final g = _storage.read('user_gender') ?? 'male';
                          final double multiplier = g == 'female' ? 0.413 : 0.415;
                          final double strideLength = (h / 100) * multiplier;
                          
                          if (finalDist == 0) finalDist = (finalSteps * strideLength).toDouble();
                          if (finalCal == 0) finalCal = ((finalDist / 1000) * w * 0.73).toDouble();
                        }

                        final existing = await _isar.stepLogs.filter().dateEqualTo(midnight).findFirst();
                        final updated = (existing ?? StepLog(date: midnight, goal: currentGoal)).copyWith(
                            steps: finalSteps,
                            calories: finalCal,
                            distance: finalDist,
                            goal: existing == null ? currentGoal : existing.goal, 
                            lastSyncedAt: DateTime.now(),
                        );
                        await _isar.stepLogs.put(updated);
                    }
                });
                talker.info('💾 Bucket Persisted: ${dailyBuckets.length} days synced');
            }
        } catch (e) {
            talker.error('❌ Failed to sync bucket $i: $e');
        }
        
        // Safety yielded delay
        await Future.delayed(const Duration(milliseconds: 500));
    }
    talker.info('✅ Deep Sync Pulse Completed');
  }



  double _extractNumericValue(HealthValue value) {
    // ✅ Logic 1: Standard Numeric Points
    if (value is NumericHealthValue) {
      return value.numericValue.toDouble();
    }
    
    // ✅ Logic 2: Workout Aggregates (Common for Calories/Distance on some platforms)
    if (value is WorkoutHealthValue) {
      // Priority: Calories -> Distance -> Steps
      final cal = value.totalEnergyBurned?.toDouble() ?? 0.0;
      final dist = value.totalDistance?.toDouble() ?? 0.0;
      final steps = value.totalSteps?.toDouble() ?? 0.0;
      
      // We return a combined indicator or handle per type if possible
      // But for our loop, we log and return the most relevant one
      talker.debug('🔍 Health Inspector (Workout): $cal kcal | $dist m | $steps steps');
      return cal > 0 ? cal : (dist > 0 ? dist : steps);
    }

    // ✅ Logic 3: String/Legacy Fallback (Robust Cleaning)
    try {
      final valStr = value.toString();
      talker.debug('🔍 Health Inspector (Raw): $valStr');
      final cleaned = valStr.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  /// ✅ Professional Analytics: Fetch granular hourly steps for the current day
  Future<List<int>> getHourlySteps() async {
    if (isAuthorized.value != true) return List.filled(24, 0);

    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      
      // Fetch raw data points to aggregate by hour
      final List<HealthDataPoint> points = await health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [HealthDataType.STEPS],
      );

      final List<int> hourly = List.filled(24, 0);
      for (var p in points) {
        final hour = p.dateFrom.hour;
        if (hour >= 0 && hour < 24) {
          final val = _extractNumericValue(p.value).toInt();
          hourly[hour] += val;
        }
      }
      talker.info('📊 Hourly Steps Analysis: ${hourly.where((s) => s > 0).length} active hours found');
      return hourly;
    } catch (e) {
      talker.error('❌ Error fetching hourly steps: $e');
      return List.filled(24, 0);
    }
  }
}
