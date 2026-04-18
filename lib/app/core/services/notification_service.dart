import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../helpers/log_helper.dart';

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final isInitialized = false.obs;
  
  // 🛡️ Global ID Governance (Phase 4: Triple Hardening)
  static const int MED_OFFSET = 100000000;
  static const int TASK_OFFSET = 200000000;
  static const int SHIFT_OFFSET = 300000000;
  static const int CALENDAR_OFFSET = 400000000;

  /// ✅ Phase 4: Deterministic ID Strategy
  /// Ensures notifications are consistent across app installs/restores.
  int getDeterministicId(String key, {int offset = 0}) {
    // Basic hash logic: sum of chars * prime
    int hash = 0;
    for (int i = 0; i < key.length; i++) {
      hash = (31 * hash + key.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return (offset + (hash % 10000000));
  }


  @override
  void onInit() {
    super.onInit();
    init();
  }

  Future<void> init() async {
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          talker.info('🔔 Notification tapped: ${details.payload}');
        },
      );

      // Create channel for high importance notifications
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'daily_tasks_channel', // id
        'Smart Daily Tasks', // title
        description: 'Notifications for your scheduled tasks', // description
        importance: Importance.high,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      // Create channel for work shifts
      const AndroidNotificationChannel shiftChannel = AndroidNotificationChannel(
        'work_shifts_channel', 
        'Work Shifts',
        description: 'Reminders for your work shift start times',
        importance: Importance.max,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(shiftChannel);
          
      await requestFullPermissions(); // ✅ Request permissions explicitly
      
      isInitialized.value = true;
      talker.info('✅ Notifications Ready (GetX Service)');
    } catch (e, stack) {
      talker.handle(e, stack, '⚠️ Error initializing notifications');
    }
  }

  /// ✅ Pro Governance: Advanced Permission Request Logic for Android 13/14/15/16
  Future<void> requestFullPermissions() async {
    // 1. Post Notifications (Android 13+)
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      talker.info('📢 Notification Permission Status: $status');
    }
    
    // 2. Exact Alarms (Android 12+)
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isDenied) {
        talker.warning('🕒 Exact Alarm Permission is Denied. Reminders might be delayed.');
        await Permission.scheduleExactAlarm.request();
      }
    }

    // 3. Android 16 Stability: Request Battery Optimization Exemption
    await requestBatteryExemption();
  }

  /// ✅ Android 16 Stability: Ensure app survives aggressive background quotas
  /// ✅ Android Stability: Ensure app survives aggressive background quotas
  /// Returns true if exempted or if not on Android
  Future<bool> requestBatteryExemption() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (status.isDenied) {
        talker.info('🔋 Requesting Battery Optimization Exemption...');
        final result = await Permission.ignoreBatteryOptimizations.request();
        return result.isGranted;
      }
      return status.isGranted;
    }
    return true;
  }

  /// ✅ Exact Alarm Check (Android 12+)
  Future<bool> checkExactAlarmPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isDenied) {
        talker.info('🕒 Requesting Exact Alarm Permission...');
        await Permission.scheduleExactAlarm.request();
        return (await Permission.scheduleExactAlarm.status).isGranted;
      }
      return status.isGranted;
    }
    return true;
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // Safety check for initialization
    if (!isInitialized.value) {
      talker.warning('⚠️ Scheduling attempted before notification service ready. Deferring...');
      await _waitForInit();
    }

    // Convert to local timezone TZDateTime for correct scheduling
    final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    // If time is in the past (with 5s safety buffer for performance overhead), don't schedule
    if (tzTime.isBefore(tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)))) {
      talker.warning('🕒 Notification time is in the past or too close (buffer: 5s). Skipping.');
      return;
    }

    // Check for exact alarm permission on Android 12+
    bool canScheduleExact = true;
    if (defaultTargetPlatform == TargetPlatform.android) {
      canScheduleExact = await Permission.scheduleExactAlarm.isGranted;
    }
    
    // 🛡️ Governance: Do not silently fail if permissions are utterly revoked
    if (!(await Permission.notification.isGranted)) {
      talker.warning('⚠️ Notification permission explicitly denied by user. Aborting.');
      return;
    }

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_tasks_channel',
            'Smart Daily Tasks',
            channelDescription: 'Notifications for scheduled tasks',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          ),
        ),
        androidScheduleMode: canScheduleExact 
            ? AndroidScheduleMode.exactAllowWhileIdle 
            : AndroidScheduleMode.inexactAllowWhileIdle, 
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e, stack) {
      talker.handle(e, stack, '❌ Notification scheduling failed');
    }
  }

  /// ✅ Diagnostic Signal: Fires an immediate test notification to prove system stability
  Future<void> sendTestNotification() async {
    if (!isInitialized.value) await _waitForInit();
    
    try {
      await flutterLocalNotificationsPlugin.show(
        999, // Diagnostic ID
        'Life OS: Diagnostic Signal',
        'System is stable and signal delivery is audible. 🚀',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_tasks_channel',
            'System Diagnostics',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            showWhen: true,
          ),
        ),
      );
      talker.info('🔔 Diagnostic Signal Fired Successfully');
    } catch (e, stack) {
      talker.handle(e, stack, '❌ Diagnostic Signal Failed');
    }
  }

  /// ✅ Real-time Stability Status
  Future<bool> isSystemStable() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    
    final notifStatus = await Permission.notification.isGranted;
    final batteryStatus = await Permission.ignoreBatteryOptimizations.isGranted;
    final alarmStatus = await Permission.scheduleExactAlarm.isGranted;
    
    return notifStatus && batteryStatus && alarmStatus;
  }

  Future<void> _waitForInit() async {
    int attempts = 0;
    while (!isInitialized.value && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }
    if (!isInitialized.value) {
      talker.error('⚠️ NotificationService failed to initialize after $attempts attempts');
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek, // 1-7 (Mon-Sun)
    required int hour,
    required int minute,
  }) async {
    if (!isInitialized.value) await _waitForInit();

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    int daysToAdd = (dayOfWeek - scheduledDate.weekday + 7) % 7;
    scheduledDate = scheduledDate.add(Duration(days: daysToAdd));
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    // Check for exact alarm permission on Android 12+
    bool canScheduleExact = true;
    if (defaultTargetPlatform == TargetPlatform.android) {
      canScheduleExact = await Permission.scheduleExactAlarm.isGranted;
    }

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'work_shifts_channel',
            'Work Shifts',
            channelDescription: 'Shift start reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: canScheduleExact 
            ? AndroidScheduleMode.exactAllowWhileIdle 
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, 
      );
      talker.info('📅 Scheduled weekly notification $id for day $dayOfWeek at $hour:$minute');
    } catch (e, stack) {
      talker.handle(e, stack, '❌ Weekly notification scheduling failed');
    }
  }
}
