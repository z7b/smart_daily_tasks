import 'dart:io';
import 'dart:ui';
import 'dart:async';
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
import 'package:smart_daily_tasks/app/core/translations/messages.dart';
import 'package:smart_daily_tasks/app/core/theme/theme_service.dart';
import 'package:smart_daily_tasks/app/core/services/security_service.dart';
import 'package:smart_daily_tasks/app/core/services/app_lock_service.dart';
import 'package:smart_daily_tasks/app/core/services/app_lock_observer.dart';
import 'package:smart_daily_tasks/app/core/services/notification_service.dart';
import 'package:smart_daily_tasks/app/core/services/appointment_time_service.dart';
import 'package:smart_daily_tasks/app/core/services/task_time_service.dart';

import 'package:smart_daily_tasks/app/data/models/task_model.dart';
import 'package:smart_daily_tasks/app/data/models/note_model.dart';
import 'package:smart_daily_tasks/app/data/models/journal_model.dart';
import 'package:smart_daily_tasks/app/data/models/calendar_event_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_daily_tasks/app/data/models/bookmark_model.dart';
import 'package:smart_daily_tasks/app/data/models/book_model.dart';
import 'package:smart_daily_tasks/app/data/models/medication_model.dart';
import 'package:smart_daily_tasks/app/data/models/step_log_model.dart';
import 'package:smart_daily_tasks/app/data/models/work_profile_model.dart';
import 'package:smart_daily_tasks/app/data/models/attendance_log_model.dart';
import 'package:smart_daily_tasks/app/data/models/appointment_model.dart';

import 'package:smart_daily_tasks/app/data/providers/task_repository.dart';
import 'package:smart_daily_tasks/app/data/providers/note_repository.dart';
import 'package:smart_daily_tasks/app/data/providers/journal_repository.dart';
import 'package:smart_daily_tasks/app/data/providers/calendar_repository.dart';
import 'package:smart_daily_tasks/app/data/providers/bookmark_repository.dart';
import 'package:smart_daily_tasks/app/data/providers/medication_repository.dart';
import 'package:smart_daily_tasks/app/data/providers/step_repository.dart';
import 'package:smart_daily_tasks/app/data/providers/job_repository.dart';
import 'package:smart_daily_tasks/app/data/providers/appointment_repository.dart';
import 'package:smart_daily_tasks/app/data/services/health_service.dart';
import 'package:smart_daily_tasks/app/core/services/time_service.dart';
import 'package:smart_daily_tasks/app/routes/app_pages.dart';
import 'package:smart_daily_tasks/app/modules/settings/controllers/settings_controller.dart';
import 'package:smart_daily_tasks/app/core/services/assistant/command_executor.dart';
import 'package:smart_daily_tasks/app/core/services/assistant/query_engine.dart';

import 'package:workmanager/workmanager.dart';

// ✅ Phase 6: Expert Background Sync Dispatcher (Google Standards)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Background isolate has its own memory; we must re-init essential services
      final dir = await getApplicationDocumentsDirectory();

      // Open Isar (Background Instance)
      final isar = await Isar.open(
        [
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
          AppointmentSchema,
        ],
        directory: dir.path,
        inspector: false,
      );

      // ✅ Inject StepRepository for SSOT writes in background
      Get.put(StepRepository(isar));

      // Trigger the specialized background sync pulse
      final healthService = HealthService();
      await healthService.init();

      if (healthService.isAuthorized.value == true) {
        // ✅ Rule: Background tasks MUST have a timeout to prevent persistent DB locks
        await healthService.fetchAndPersistSteps().timeout(
          const Duration(seconds: 25),
          onTimeout: () => 0,
        );
      }

      await isar.close();
      return true;
    } catch (e) {
      talker.error('❌ Background Sync Failed: $e');
      return false;
    }
  });
}

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) =>
          talker.handle(details.exception, details.stack);
      PlatformDispatcher.instance.onError = (error, stack) {
        talker.handle(error, stack);
        return true;
      };

      talker.info('🚀 Life OS Initializing...');

      // ✅ Initialize Background Synchronization
      Workmanager().initialize(callbackDispatcher);

      tz.initializeTimeZones();
      await GetStorage.init();

      runApp(const AppBootstrapper());
    },
    (error, stack) {
      talker.handle(error, stack, '🔥 Global Unhandled Error');
    },
  );
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
    final masterSw = Stopwatch()..start();
    final phaseSw = Stopwatch()..start();

    try {
      talker.info('🛠️ Phase 1: Initializing Core Services...');
      await Get.putAsync(() => ThemeService().init(), permanent: true);
      await Get.putAsync(() => SecurityService().init(), permanent: true);
      await Get.putAsync(() => AppLockService().init(), permanent: true);
      await Get.putAsync(() => TimeService().init(), permanent: true);
      
      talker.info('⏱️ [Trace] Phase 1 (Core Services) completed in ${phaseSw.elapsedMilliseconds}ms');
      phaseSw.reset();

      final dir = await getApplicationDocumentsDirectory();

      talker.info('🛠️ Phase 2: Expert Isar Initialization...');
      // ✅ Phase 2: Expert Isar Initialization (Singleton-Aware + Lock Recovery)
      Isar? isar = Isar.getInstance();

      if (isar == null) {
        int retryCount = 0;
        const int maxRetries = 5;
        while (retryCount < maxRetries) {
          try {
            isar = await Isar.open(
              [
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
                AppointmentSchema,
              ],
              directory: dir.path,
              inspector: false,
            ); // 🛡️ Disable inspector to prevent debug hang
            talker.info('📦 Isar successfully initialized');
            break;
          } catch (e) {
            retryCount++;
            final errorStr = e.toString();

            // Handle Lock Error (MdbxError (11) / EAGAIN)
            // This happens if a background process or previous run is holding the lock.
            if (errorStr.contains('MdbxError (11)') ||
                errorStr.contains('Try again')) {
              final delay = 500 * retryCount; // Exponential backoff
              talker.warning(
                '🕒 Database locked. Retrying in ${delay}ms... ($retryCount/$maxRetries)',
              );
              await Future.delayed(Duration(milliseconds: delay));
              continue;
            }

            // Handle Corruption or Migration errors (Attempt Recovery)
            talker.error('⚠️ Critical Isar open failure: $e');
            if (retryCount <= 2) {
              try {
                final dbFile = File('${dir.path}/default.isar');
                if (await dbFile.exists()) {
                  final backupPath =
                      '${dir.path}/default_backup_${DateTime.now().millisecondsSinceEpoch}.isar';
                  await dbFile.rename(backupPath);
                  talker.warning(
                    '🚨 Potential corruption detected. Backup created at: $backupPath',
                  );
                }
              } catch (resErr) {
                talker.error('❌ Recovery rename failed: $resErr');
              }
            } else {
              rethrow;
            }
          }
        }
      } else {
        talker.info('♻️ Reusing existing Isar singleton instance');
      }

      if (isar == null) {
        throw Exception('Failed to initialize database after retries');
      }
      Get.put<Isar>(isar, permanent: true);
      talker.info('⏱️ [Trace] Phase 2 (Isar DB) completed in ${phaseSw.elapsedMilliseconds}ms');
      phaseSw.reset();

      // ✅ Phase 3: Register Repositories
      talker.info('📚 Phase 3: Registering Repositories...');
      Get.put(TaskRepository(isar), permanent: true);
      Get.put(NoteRepository(isar), permanent: true);
      Get.put(JournalRepository(isar), permanent: true);
      Get.put(CalendarRepository(isar), permanent: true);
      Get.put(BookmarkRepository(isar), permanent: true);
      Get.put(MedicationRepository(isar), permanent: true);

      Get.put(StepRepository(isar), permanent: true);

      Get.put(JobRepository(isar), permanent: true);
      Get.put(AppointmentRepository(isar), permanent: true);
      
      talker.info('⏱️ [Trace] Phase 3 (Repositories) completed in ${phaseSw.elapsedMilliseconds}ms');
      phaseSw.reset();

      // ✅ Phase 4: Initialize Health & Pedometer
      talker.info('🏥 Phase 4: Initializing Health Services...');
      await Get.putAsync(() => HealthService().init(), permanent: true);
      
      talker.info('⏱️ [Trace] Phase 4 (Health) completed in ${phaseSw.elapsedMilliseconds}ms');
      phaseSw.reset();

      // ✅ Phase 5: Initialize Features
      talker.info('🔔 Phase 5: Initializing Notifications...');
      Get.put(NotificationService(), permanent: true);
      Get.put(AppointmentTimeService(), permanent: true);
      Get.put(TaskTimeService(), permanent: true);

      // ✅ Phase 6: Register AI Assistant Services (Tool Execution)
      Get.put(
        CommandExecutor(
          taskRepo: Get.find<TaskRepository>(),
          noteRepo: Get.find<NoteRepository>(),
          medRepo: Get.find<MedicationRepository>(),
          journalRepo: Get.find<JournalRepository>(),
        ),
        permanent: true,
      );
      Get.put(
        QueryEngine(
          taskRepo: Get.find<TaskRepository>(),
          medRepo: Get.find<MedicationRepository>(),
          appointmentRepo: Get.find<AppointmentRepository>(),
          taskTimeService: Get.find<TaskTimeService>(),
          timeService: Get.find<TimeService>(),
        ),
        permanent: true,
      );

      final appLockObserver = AppLockObserver();
      WidgetsBinding.instance.addObserver(appLockObserver);
      Get.put<AppLockObserver>(appLockObserver, permanent: true);

      Get.put(SettingsController(), permanent: true);
      
      talker.info('⏱️ [Trace] Phases 5 & 6 (Features & AI) completed in ${phaseSw.elapsedMilliseconds}ms');
      phaseSw.stop();

      if (mounted) setState(() => _isInit = true);
      
      masterSw.stop();
      talker.info('✅ Life OS is Ready! Total Cold Boot Time: ${masterSw.elapsedMilliseconds}ms');
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

    return Obx(
      () => GetMaterialApp(
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
        builder: (context, child) {
          return Stack(
            children: [
              if (child != null) Positioned.fill(child: child),
              // 🛡️ Global App Lock Overlay
              Obx(() {
                if (!appLockService.isOverlayVisible.value) {
                  return const SizedBox.shrink();
                }

                return Positioned.fill(
                  child: GestureDetector(
                    onTap: () => appLockService.authenticate(),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.95),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                                  Icons.lock_outline_rounded,
                                  color: Colors.white,
                                  size: 64,
                                )
                                .animate(onPlay: (c) => c.repeat())
                                .shimmer(duration: const Duration(seconds: 2)),
                            const SizedBox(height: 24),
                            Text(
                              'tap_to_unlock'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 1.1,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
