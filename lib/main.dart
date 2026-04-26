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
import 'package:smart_daily_tasks/app/core/translations/messages.dart';
import 'package:smart_daily_tasks/app/core/theme/theme_service.dart';
import 'package:smart_daily_tasks/app/core/services/security_service.dart';
import 'package:smart_daily_tasks/app/core/services/app_lock_service.dart';
import 'package:smart_daily_tasks/app/core/services/app_lock_observer.dart';
import 'package:smart_daily_tasks/app/core/services/notification_service.dart';

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

import 'package:workmanager/workmanager.dart';

// ✅ Phase 6: Expert Background Sync Dispatcher (Google Standards)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Background isolate has its own memory; we must re-init essential services
      final dir = await getApplicationDocumentsDirectory();
      
      // Open Isar (Background Instance)
      final isar = await Isar.open([
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
      ], directory: dir.path, inspector: false);

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) =>
      talker.handle(details.exception, details.stack);
  PlatformDispatcher.instance.onError = (error, stack) {
    talker.handle(error, stack);
    return true;
  };

  talker.info('🚀 Life OS Initializing...');
  
  // ✅ Initialize Background Synchronization
  Workmanager().initialize(
    callbackDispatcher,
  );

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

      // ✅ Phase 4: Expert Isar Initialization (Singleton-Aware + Lock Recovery)
      Isar? isar = Isar.getInstance();

      if (isar == null) {
        int retryCount = 0;
        const int maxRetries = 5;
        while (retryCount < maxRetries) {
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
            talker.info(
              '📦 Isar successfully initialized (Attempt ${retryCount + 1})',
            );
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
      await Get.putAsync(() => HealthService().init(), permanent: true);

      // ✅ Step 4: Initialize Features
      talker.info('🔔 Initializing Notifications...');
      Get.put(NotificationService(), permanent: true);

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
        supportedLocales: const [Locale('en'), Locale('ar')],
        builder: (context, child) {
          final isDark = themeService.isDarkModeRx.value;
          final bgColor = isDark ? const Color(0xFF050505) : const Color(0xFFE5E5E5);
          
          return Container(
            color: bgColor,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: ClipRect( // Ensures overlay doesn't bleed outside the 550px constraint
                  child: Stack(
                    children: [
                      child!,
                      Obx(() {
                        if (!appLockService.isOverlayVisible.value) {
                          return const SizedBox.shrink();
                        }

                        return Positioned.fill(
                          child: GestureDetector(
                            onTap: () => appLockService.authenticate(),
                            child: Stack(
                              children: [
                                // 🌈 Layer 1: Mesh Gradient Blobs (Animated)
                                Positioned.fill(
                                  child: Container(color: Colors.black),
                                ),
                                Positioned(
                                  top: -100,
                                  right: -100,
                                  child: Container(
                                    width: 300,
                                    height: 300,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5E5CE6).withAlpha(100),
                                      shape: BoxShape.circle,
                                    ),
                                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                                   .move(duration: const Duration(seconds: 5), begin: const Offset(-20, -20), end: const Offset(20, 20))
                                   .blur(begin: const Offset(80, 80), end: const Offset(100, 100)),
                                ),
                                Positioned(
                                  bottom: -50,
                                  left: -50,
                                  child: Container(
                                    width: 250,
                                    height: 250,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF007AFF).withAlpha(100),
                                      shape: BoxShape.circle,
                                    ),
                                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                                   .move(duration: const Duration(seconds: 7), begin: const Offset(10, 10), end: const Offset(-10, -10))
                                   .blur(begin: const Offset(80, 80), end: const Offset(100, 100)),
                                ),

                                // 🪟 Layer 2: Global Frosted Glass Effect
                                BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                                  child: Container(
                                    color: Colors.black.withAlpha(80),
                                  ),
                                ),

                                // 🛡️ Layer 3: Central Professional Lock Card
                                Center(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 40),
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(15),
                                      borderRadius: BorderRadius.circular(40),
                                      border: Border.all(
                                        color: Colors.white.withAlpha(30),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Pulsing Security Icon
                                        Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withAlpha(20),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.white.withAlpha(10),
                                                blurRadius: 20,
                                                spreadRadius: 5,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            appLockService.isBiometricEnabled.value 
                                              ? Icons.fingerprint_rounded 
                                              : Icons.lock_outline_rounded,
                                            color: Colors.white,
                                            size: 56,
                                          ),
                                        ).animate(onPlay: (c) => c.repeat(reverse: true))
                                         .scale(duration: const Duration(seconds: 2), begin: const Offset(1, 1), end: const Offset(1.1, 1.1))
                                         .shimmer(duration: const Duration(seconds: 3), delay: const Duration(seconds: 1)),
                                        
                                        const SizedBox(height: 32),
                                        
                                        // Header Text
                                        Text(
                                          'identity_verification'.tr,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.none,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 12),
                                        
                                        // Description Text
                                        Text(
                                          'security_locked_desc'.tr,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white.withAlpha(160),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            decoration: TextDecoration.none,
                                            height: 1.5,
                                          ),
                                        ),

                                        const SizedBox(height: 48),

                                        // Action Hint
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.security_rounded, color: Colors.blue, size: 18),
                                              const SizedBox(width: 8),
                                              Text(
                                                'tap_to_unlock'.tr,
                                                style: const TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  decoration: TextDecoration.none,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ).animate().fadeIn(duration: const Duration(milliseconds: 400)).scale(begin: const Offset(0.9, 0.9)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
