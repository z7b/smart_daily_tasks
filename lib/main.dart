import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_daily_tasks/app/core/helpers/log_helper.dart';
import 'package:smart_daily_tasks/app/core/bindings/initial_binding.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:smart_daily_tasks/app/core/translations/messages.dart';
import 'package:smart_daily_tasks/app/core/theme/app_theme.dart';
import 'package:smart_daily_tasks/app/core/theme/theme_service.dart';
import 'package:smart_daily_tasks/app/core/services/security_service.dart';
import 'package:smart_daily_tasks/app/core/services/app_lock_service.dart';
import 'package:smart_daily_tasks/app/core/services/app_lock_observer.dart';
import 'package:smart_daily_tasks/app/core/services/notification_service.dart';

import 'package:smart_daily_tasks/app/data/models/task_model.dart';
import 'package:smart_daily_tasks/app/data/models/note_model.dart';
import 'package:smart_daily_tasks/app/data/models/journal_model.dart';
import 'package:smart_daily_tasks/app/data/models/calendar_event_model.dart';
import 'package:smart_daily_tasks/app/data/models/bookmark_model.dart';
import 'package:smart_daily_tasks/app/data/models/book_model.dart';
import 'package:smart_daily_tasks/app/data/models/medication_model.dart';
import 'package:smart_daily_tasks/app/data/models/step_log_model.dart';
import 'package:smart_daily_tasks/app/data/models/work_profile_model.dart';
import 'package:smart_daily_tasks/app/data/models/attendance_log_model.dart';

import 'package:smart_daily_tasks/app/data/providers/task_repository.dart';
import 'package:smart_daily_tasks/app/data/providers/note_repository.dart';
import 'package:smart_daily_tasks/app/data/providers/journal_repository.dart';
import 'package:smart_daily_tasks/app/data/providers/calendar_repository.dart';
import 'package:smart_daily_tasks/app/data/providers/bookmark_repository.dart';
import 'package:smart_daily_tasks/app/data/providers/medication_repository.dart';
import 'package:smart_daily_tasks/app/data/providers/step_repository.dart';
import 'package:smart_daily_tasks/app/data/providers/job_repository.dart';
import 'package:smart_daily_tasks/app/data/services/health_service.dart';

import 'package:smart_daily_tasks/app/routes/app_pages.dart';
import 'package:smart_daily_tasks/app/modules/settings/controllers/settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) =>
      talker.handle(details.exception, details.stack);
  PlatformDispatcher.instance.onError = (error, stack) {
    talker.handle(error, stack);
    return true;
  };

  talker.info('🚀 Life OS Initializing...');
  tz.initializeTimeZones();
  await GetStorage.init();
  runApp(const AppBootstrapper());
}

class AppBootstrapper extends StatefulWidget {
  const AppBootstrapper({super.key});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  bool _isInit = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      talker.info('🛠️ Initializing Core Services...');
      await Get.putAsync(() => ThemeService().init(), permanent: true);
      await Get.putAsync(() => SecurityService().init(), permanent: true);
      await Get.putAsync(() => AppLockService().init(), permanent: true);

      final dir = await getApplicationDocumentsDirectory();

      // ✅ Step 1: Robust Isar Initialization with Retry & Recovery
      Isar? isar;
      int retryCount = 0;
      while (retryCount <= 2) {
        try {
          isar = await Isar.open([
            TaskSchema,
            NoteSchema,
            JournalSchema,
            CalendarEventSchema,
            BookmarkSchema,
            BookSchema,
            MedicationSchema,
            StepLogSchema,
            WorkProfileSchema,
            AttendanceLogSchema,
          ], directory: dir.path);
          break; // Success
        } catch (e) {
          retryCount++;
          talker.error('⚠️ Isar open failed (Attempt $retryCount/3): $e');
          if (retryCount <= 2) {
            final dbFile = File('${dir.path}/default.isar');
            if (await dbFile.exists()) {
              final backupPath =
                  '${dir.path}/default_backup_${DateTime.now().millisecondsSinceEpoch}.isar';
              await dbFile.rename(backupPath);
              talker.warning('🚨 Corrupted DB backed up to: $backupPath');
            }
          } else {
            rethrow;
          }
        }
      }

      if (isar == null)
        throw Exception('Failed to initialize database after retries');
      Get.put<Isar>(isar, permanent: true);

      // ✅ Step 2: Register Repositories
      talker.info('📚 Registering Repositories...');
      Get.put(TaskRepository(isar), permanent: true);
      Get.put(NoteRepository(isar), permanent: true);
      Get.put(JournalRepository(isar), permanent: true);
      Get.put(CalendarRepository(isar), permanent: true);
      Get.put(BookmarkRepository(isar), permanent: true);
      Get.put(MedicationRepository(isar), permanent: true);

      Get.put(StepRepository(isar), permanent: true);

      Get.put(JobRepository(isar), permanent: true);

      // ✅ Step 3: Initialize Health & Pedometer
      talker.info('🏥 Initializing Health Services...');
      await Get.putAsync(() => HealthService(isar!).init(), permanent: true);

      // ✅ Step 4: Initialize Features
      talker.info('🔔 Initializing Notifications...');
      await Get.putAsync(() => Future.value(NotificationService()), permanent: true);

      final appLockObserver = AppLockObserver();
      WidgetsBinding.instance.addObserver(appLockObserver);
      Get.put<AppLockObserver>(appLockObserver, permanent: true);

      Get.put(SettingsController(), permanent: true);

      if (mounted) setState(() => _isInit = true);
      talker.info('✅ Life OS is Ready');
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Fatal System Init Error');
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<AppLockObserver>()) {
      WidgetsBinding.instance.removeObserver(Get.find<AppLockObserver>());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInit) return const MainApp();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF09090B),
        body: Center(
          child: _error != null
              ? Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.red),
                )
              : const CircularProgressIndicator(color: Colors.blue),
        ),
      ),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    final appLockService = Get.find<AppLockService>();

    return Obx(() => GetMaterialApp(
      title: 'Smart Daily Tasks',
      debugShowCheckedModeBanner: false,
      theme: themeService.currentTheme,
      darkTheme: themeService.currentDarkTheme,
      themeMode: themeService.theme,
      initialRoute: AppPages.initial,
      initialBinding: InitialBinding(),
      getPages: AppPages.routes,
      translations: Messages(),
      locale: Locale(themeService.getLocale().languageCode),
      fallbackLocale: const Locale('en'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            Obx(() {
              if (!appLockService.isOverlayVisible.value) {
                return const SizedBox.shrink();
              }
              
              return Positioned.fill(
                child: GestureDetector(
                  onTap: () => appLockService.authenticate(),
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        color: Colors.black.withAlpha(150),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(20),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withAlpha(40)),
                              ),
                              child: const Icon(
                                Icons.security_rounded,
                                color: Colors.white,
                                size: 64,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'privacy_overlay_active'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'tap_to_unlock'.tr,
                              style: TextStyle(
                                color: Colors.white.withAlpha(120),
                                fontSize: 14,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    ));
  }
}
