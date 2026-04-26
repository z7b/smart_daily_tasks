import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../helpers/log_helper.dart';

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final isInitialized = false.obs;
  
  // 🛡️ Global ID Governance (Phase 4: Triple Hardening)
  static const int medOffset = 100000000;
  static const int taskOffset = 200000000;
  static const int shiftOffset = 300000000;
  static const int calendarOffset = 400000000;
  static const int stepsOffset = 500000000;

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

      // Create channel for steps smart reminders
      const AndroidNotificationChannel stepsChannel = AndroidNotificationChannel(
        'steps_smart_channel',
        'خطواتي',
        description: 'تذكيرات ذكية للمشي والنشاط',
        importance: Importance.high,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(stepsChannel);
          
      // ✅ Defer permissions explicitly to prevent racing with Health Service during boot
      Future.delayed(const Duration(seconds: 5), () {
        requestFullPermissions();
      });
      
      isInitialized.value = true;
      talker.info('✅ Notifications Ready (GetX Service)');
    } catch (e, stack) {
      talker.handle(e, stack, '⚠️ Error initializing notifications');
    }
  }

  Future<void> requestFullPermissions() async {
    try {
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
    } catch (e) {
      talker.warning('⚠️ Gracefully suppressed permission race condition: $e');
    }
  }

  /// ✅ Android 16 Stability: Ensure app survives aggressive background quotas
  /// Returns true if exempted or if not on Android
  Future<bool> requestBatteryExemption() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final status = await Permission.ignoreBatteryOptimizations.status;
        if (status.isDenied) {
          talker.info('🔋 Requesting Battery Optimization Exemption...');
          final result = await Permission.ignoreBatteryOptimizations.request();
          return result.isGranted;
        }
        return status.isGranted;
      } catch (e) {
        talker.warning('⚠️ Suppressed battery exemption permission error: $e');
        return false;
      }
    }
    return true;
  }

  /// ✅ Exact Alarm Check (Android 12+)
  Future<bool> checkExactAlarmPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final status = await Permission.scheduleExactAlarm.status;
        if (status.isDenied) {
          talker.info('🕒 Requesting Exact Alarm Permission...');
          await Permission.scheduleExactAlarm.request();
          return (await Permission.scheduleExactAlarm.status).isGranted;
        }
        return status.isGranted;
      } catch (e) {
        talker.warning('⚠️ Suppressed exact alarm permission error: $e');
        return false;
      }
    }
    return true;
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? largeIcon,
  }) async {
    // Safety check for initialization
    if (!isInitialized.value) {
      talker.warning('⚠️ Scheduling attempted before notification service ready. Deferring...');
      await _waitForInit();
    }

    // 🛡️ Timezone Safety: Convert to UTC first to prevent double-offset
    // This ensures correct scheduling regardless of whether scheduledTime is UTC or local
    final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime.toUtc(), tz.local);

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
        NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_tasks_channel',
            'Smart Daily Tasks',
            channelDescription: 'Notifications for scheduled tasks',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            subText: 'Life OS',
            largeIcon: largeIcon != null ? DrawableResourceAndroidBitmap(largeIcon) : null,
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

  /// 🛡️ Reschedule all active notifications (called on app resume / timezone change)
  /// This cancels all pending notifications and reschedules from scratch.
  Future<void> rescheduleAllNotifications(List<Map<String, dynamic>> taskSchedules) async {
    if (!isInitialized.value) await _waitForInit();
    
    try {
      // Cancel all existing notifications first
      await flutterLocalNotificationsPlugin.cancelAll();
      talker.info('🔄 Cancelled all pending notifications for reschedule');
      
      int scheduled = 0;
      for (final schedule in taskSchedules) {
        final id = schedule['id'] as int;
        final title = schedule['title'] as String;
        final body = schedule['body'] as String;
        final time = schedule['scheduledTime'] as DateTime;
        
        if (time.isAfter(DateTime.now())) {
          await scheduleNotification(
            id: id,
            title: title,
            body: body,
            scheduledTime: time,
          );
          scheduled++;
        }
      }
      
      talker.info('✅ Rescheduled $scheduled notifications after timezone/resume check');
    } catch (e, stack) {
      talker.handle(e, stack, '❌ Failed to reschedule notifications');
    }
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

  /// ✅ Smart Steps Notification: Premium RTL Arabic notification
  /// Layout (RTL): شعار التطبيق (يسار) ← النص (وسط) ← الصورة (يمين)
  /// Android automatically places largeIcon on the right in RTL mode
  Future<void> showSmartStepsNotification({
    required int id,
    required String title,
    required String body,
    String? bigText,
    String? largeIcon,
  }) async {
    if (!isInitialized.value) await _waitForInit();
    
    if (!(await Permission.notification.isGranted)) return;

    try {
      // ✅ Expert: largeIcon appears on the RIGHT in RTL (Arabic) — exactly where we want it
      // The small app icon (@mipmap/ic_launcher) appears on the LEFT automatically
      AndroidBitmap<Object>? iconBitmap;
      if (largeIcon != null) {
        iconBitmap = DrawableResourceAndroidBitmap(largeIcon);
      }

      await flutterLocalNotificationsPlugin.show(
        stepsOffset + id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'steps_smart_channel',
            'خطواتي',
            channelDescription: 'تذكيرات ذكية للمشي والنشاط',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            // ✅ Image on the right (RTL) with no background — Android crops to circle
            largeIcon: iconBitmap,
            // ✅ App name as subtext under notification
            subText: 'Life OS',
            styleInformation: bigText != null
                ? BigTextStyleInformation(
                    bigText,
                    contentTitle: title,
                    summaryText: 'خطواتي • نشاطك اليومي',
                    htmlFormatBigText: false,
                    htmlFormatContentTitle: false,
                  )
                : null,
            category: AndroidNotificationCategory.reminder,
          ),
        ),
        payload: 'steps_smart',
      );
      talker.info('🚶 Smart Steps Notification Sent: $title');
    } on PlatformException catch (e) {
      // ✅ Fallback: If largeIcon resource fails, send without it
      talker.error('❌ Large Icon resource error: ${e.message}. Sending without icon.');
      await flutterLocalNotificationsPlugin.show(
        stepsOffset + id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'steps_smart_channel',
            'خطواتي',
            channelDescription: 'تذكيرات ذكية للمشي والنشاط',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            subText: 'Life OS',
            styleInformation: bigText != null
                ? BigTextStyleInformation(
                    bigText,
                    contentTitle: title,
                    summaryText: 'خطواتي • نشاطك اليومي',
                  )
                : null,
            category: AndroidNotificationCategory.reminder,
          ),
        ),
        payload: 'steps_smart',
      );
    } catch (e, stack) {
      talker.handle(e, stack, '❌ Smart Steps Notification Failed');
    }
  }

  /// ✅ Schedule daily smart steps reminders at key activity hours
  Future<void> scheduleSmartStepsReminders({
    required int goal,
    required int currentSteps,
  }) async {
    if (!isInitialized.value) await _waitForInit();
    if (!(await Permission.notification.isGranted)) return;

    // Cancel existing step reminders before rescheduling
    for (int i = 1; i <= 4; i++) {
      await cancelNotification(stepsOffset + i);
    }

    final now = DateTime.now();
    final progress = goal > 0 ? (currentSteps / goal).clamp(0.0, 1.0) : 0.0;
    final remaining = (goal - currentSteps).clamp(0, 999999);
    final goalFormatted = _formatNumber(goal);
    final remainingFormatted = _formatNumber(remaining);

    // Morning reminder (8:00 AM)
    if (now.hour < 8) {
      final morningTime = DateTime(now.year, now.month, now.day, 8, 0);
      await scheduleNotification(
        id: stepsOffset + 1,
        title: 'صباح النشاط! ☀️',
        body: 'هدفك اليوم $goalFormatted خطوة\nخطوة صغيرة الآن... تصنع فرقاً كبيراً لاحقاً 💪',
        scheduledTime: morningTime,
        largeIcon: 'walker',
      );
    }

    // Midday check (1:00 PM)
    if (now.hour < 13 && progress < 0.5) {
      final middayTime = DateTime(now.year, now.month, now.day, 13, 0);
      await scheduleNotification(
        id: stepsOffset + 2,
        title: 'وقت التحرك! 🚶‍♂️',
        body: 'باقي $remainingFormatted خطوة لهدفك\nاستغل وقت الظهيرة للمشي ☕',
        scheduledTime: middayTime,
        largeIcon: 'walker',
      );
    }

    // Evening push (6:00 PM)
    if (now.hour < 18 && progress < 0.8) {
      final eveningTime = DateTime(now.year, now.month, now.day, 18, 0);
      await scheduleNotification(
        id: stepsOffset + 3,
        title: 'أنت قريب من إنجازه! 🔥',
        body: 'هدفك اليوم $goalFormatted خطوة\nأفضل وقت للمشي هو بين 6 - 8 مساءً 🏃‍♂️',
        scheduledTime: eveningTime,
        largeIcon: 'walker',
      );
    }

    // Night celebration or final push (9:00 PM)
    if (now.hour < 21) {
      final nightTime = DateTime(now.year, now.month, now.day, 21, 0);
      if (progress >= 1.0) {
        await scheduleNotification(
          id: stepsOffset + 4,
          title: 'بطل حقيقي! 🏆',
          body: 'لقد حققت هدفك اليوم بنجاح!\nاحرص على الراحة والنوم الجيد 😴',
          scheduledTime: nightTime,
          largeIcon: 'walker',
        );
      } else {
        await scheduleNotification(
          id: stepsOffset + 4,
          title: 'فرصة أخيرة اليوم! 🌟',
          body: 'باقي $remainingFormatted خطوة فقط\n10 دقائق مشي قبل النوم تفرق كثيراً 🌙',
          scheduledTime: nightTime,
          largeIcon: 'walker',
        );
      }
    }

    talker.info('🔔 Smart Steps Reminders Scheduled (progress: ${(progress * 100).toInt()}%)');
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)},${(number % 1000).toString().padLeft(3, '0').substring(0, 3)}';
    }
    return number.toString();
  }
}
