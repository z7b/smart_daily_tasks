import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../helpers/log_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Defer initialization to avoid blocking the main thread during startup
    Future.delayed(const Duration(seconds: 1), () async {
      try {
        tz.initializeTimeZones();

        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        const InitializationSettings initializationSettings =
            InitializationSettings(android: initializationSettingsAndroid);

        await flutterLocalNotificationsPlugin.initialize(initializationSettings);

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
            
        await requestPermissions(); // ✅ Request permissions explicitly
        
        talker.info('✅ Notifications initialized successfully');
      } catch (e, stack) {
        talker.handle(e, stack, '⚠️ Error initializing notifications');
      }
    });
  }

  Future<void> requestPermissions() async {
    // Request basic notification permission (Android 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    
    // Request exact alarm scheduling (Android 12/14) if needed
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // Convert to TZDateTime
    final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    // If time is in the past, don't schedule
    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) return;

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
        tzTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_tasks_channel',
            'Smart Daily Tasks',
            channelDescription: 'Notifications for scheduled tasks',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: canScheduleExact 
            ? AndroidScheduleMode.exactAllowWhileIdle 
            : AndroidScheduleMode.inexactAllowWhileIdle, // ✅ Safe Fallback
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e, stack) {
      talker.handle(e, stack, '❌ Notification scheduling failed');
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
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    // Calculate how many days to add to reach the target day of week
    int daysToAdd = (dayOfWeek - scheduledDate.weekday + 7) % 7;
    if (daysToAdd == 0 && scheduledDate.isBefore(now)) {
      daysToAdd = 7;
    }
    
    scheduledDate = scheduledDate.add(Duration(days: daysToAdd));

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
            : AndroidScheduleMode.inexactAllowWhileIdle, // ✅ Safe Fallback
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, 
      );
      talker.info('📅 Scheduled weekly notification $id for day $dayOfWeek at $hour:$minute (Mode: ${canScheduleExact ? "Exact" : "Inexact"})');
    } catch (e, stack) {
      talker.handle(e, stack, '❌ Weekly notification scheduling failed');
    }
  }

  Future<void> openAlarmSettings() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await openAppSettings();
    }
  }

  Future<bool> checkExactAlarmPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await Permission.scheduleExactAlarm.isGranted;
    }
    return true;
  }
}
