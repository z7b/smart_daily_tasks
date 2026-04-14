import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'app/core/helpers/log_helper.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'app/core/bindings/initial_binding.dart';
import 'app/core/translations/messages.dart';

import 'app/core/theme/app_theme.dart';
import 'app/core/theme/theme_service.dart';
import 'app/core/services/security_service.dart';

import 'app/core/services/app_lock_service.dart';
import 'app/core/services/app_lock_observer.dart';
import 'app/core/services/notification_service.dart';

import 'app/data/models/task_model.dart';
import 'app/data/models/note_model.dart';
import 'app/data/models/journal_model.dart';
import 'app/data/models/calendar_event_model.dart';
import 'app/data/models/bookmark_model.dart';
import 'app/data/models/book_model.dart'; 
import 'app/data/models/medication_model.dart';
import 'app/data/models/step_log_model.dart'; 
import 'app/data/models/work_profile_model.dart';
import 'app/data/models/attendance_log_model.dart';

import 'app/data/providers/task_repository.dart';
import 'app/data/providers/note_repository.dart';
import 'app/data/providers/journal_repository.dart';
import 'app/data/providers/calendar_repository.dart';
import 'app/data/providers/bookmark_repository.dart';
import 'app/data/providers/medication_repository.dart'; 
import 'app/data/providers/step_repository.dart';
import 'app/data/providers/job_repository.dart';

import 'app/routes/app_pages.dart';
import 'app/modules/settings/controllers/settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) => talker.handle(details.exception, details.stack);
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
  AppLockObserver? _appLockObserver;

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
            ],
            directory: dir.path,
          );
          break; // Success
        } catch (e) {
          retryCount++;
          talker.error('⚠️ Isar open failed (Attempt $retryCount/3): $e');
          if (retryCount <= 2) {
            final dbFile = File('${dir.path}/default.isar');
            if (await dbFile.exists()) {
              final backupPath = '${dir.path}/default_backup_${DateTime.now().millisecondsSinceEpoch}.isar';
              await dbFile.rename(backupPath);
              talker.warning('🚨 Corrupted DB backed up to: $backupPath');
            }
          } else {
            rethrow;
          }
        }
      }

      if (isar == null) throw Exception('Failed to initialize database after retries');
      Get.put<Isar>(isar, permanent: true);

      // ✅ Step 2: Register Repositories
      talker.info('📚 Registering Repositories...');
      Get.put(TaskRepository(isar), permanent: true);
      Get.put(NoteRepository(isar), permanent: true);
      Get.put(JournalRepository(isar), permanent: true);
      Get.put(CalendarRepository(isar), permanent: true);
      Get.put(BookmarkRepository(isar), permanent: true);
      Get.put(MedicationRepository(isar), permanent: true);
      
      final stepRepo = StepRepository(isar);
      await stepRepo.init(); // ✅ Safe async initialization
      Get.put(stepRepo, permanent: true);

      Get.put(JobRepository(isar), permanent: true);

      // ✅ Step 3: Initialize Features
      talker.info('🔔 Initializing Notifications...');
      await NotificationService().init();
      
      _appLockObserver = AppLockObserver();
      WidgetsBinding.instance.addObserver(_appLockObserver!);

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
    if (_appLockObserver != null) WidgetsBinding.instance.removeObserver(_appLockObserver!);
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
            ? Text('Error: $_error', style: const TextStyle(color: Colors.red))
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

    return GetMaterialApp(
      title: 'Smart Daily Tasks',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
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
    );
  }
}
