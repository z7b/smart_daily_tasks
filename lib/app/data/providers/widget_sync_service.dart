import 'package:home_widget/home_widget.dart';
import 'package:get/get.dart';
import '../../core/helpers/log_helper.dart';
import '../../routes/app_routes.dart';

class WidgetSyncService extends GetxService {
  static WidgetSyncService get to => Get.find<WidgetSyncService>();

  @override
  void onInit() {
    super.onInit();
    // Listen to widget clicks when the app is in background/foreground
    HomeWidget.widgetClicked.listen(handleWidgetClick);
  }

  /// Handles deep link widget click navigation
  void handleWidgetClick(Uri? uri) {
    if (uri == null) return;
    talker.info('🎯 Widget clicked with deep link: $uri');
    final scheme = uri.scheme;
    final host = uri.host;

    if (scheme == 'rattib') {
      switch (host) {
        case 'tasks':
          Get.toNamed(Routes.TASKS);
          break;
        case 'appointments':
          Get.toNamed(Routes.APPOINTMENTS);
          break;
        case 'medication':
          Get.toNamed(Routes.MEDICATION);
          break;
        case 'notes':
          Get.toNamed(Routes.NOTES);
          break;
        case 'home':
          if (Get.currentRoute != Routes.HOME) {
            Get.offAllNamed(Routes.HOME);
          }
          break;
        default:
          talker.warning('⚠️ Unknown widget host route: $host');
          break;
      }
    }
  }

  /// Check if the app was initially launched by a widget click
  Future<void> checkInitialWidgetLaunch() async {
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (uri != null) {
        talker.info('🚀 App started from widget launch: $uri');
        handleWidgetClick(uri);
      }
    } catch (e) {
      talker.error('❌ Failed to check initially launched widget: $e');
    }
  }

  /// Sync Life OS balance progress data to home widget
  Future<void> syncLifeOsProgress({required double percentage, required String statusText}) async {
    try {
      await HomeWidget.saveWidgetData<double>('life_os_percentage', percentage);
      await HomeWidget.saveWidgetData<int>('life_os_progress_int', (percentage * 100).toInt());
      await HomeWidget.saveWidgetData<String>('life_os_text', '${(percentage * 100).toInt()}%');
      await HomeWidget.saveWidgetData<String>('life_os_status', statusText);
      await HomeWidget.updateWidget(
        name: 'LifeOsWidgetProvider',
        androidName: 'LifeOsWidgetProvider',
      );
      talker.info('🔄 Widget synced: Life OS Progress (${(percentage * 100).toInt()}%)');
    } catch (e) {
      talker.error('❌ Failed to sync Life OS Progress widget: $e');
    }
  }

  /// Sync today's tasks to home widget
  /// [count] = remaining pending tasks
  /// [completed] = number of completed tasks
  /// [total] = total tasks today
  /// [taskTitles] = list of up to 3 pending task titles
  Future<void> syncTasks({
    required int count,
    required List<String> taskTitles,
    int completed = 0,
    int total = 0,
  }) async {
    try {
      await HomeWidget.saveWidgetData<int>('tasks_count', count);
      await HomeWidget.saveWidgetData<int>('tasks_completed', completed);
      await HomeWidget.saveWidgetData<int>('tasks_total', total);
      for (int i = 0; i < 3; i++) {
        final title = i < taskTitles.length ? taskTitles[i] : '';
        await HomeWidget.saveWidgetData<String>('task_${i + 1}_title', title);
      }
      await HomeWidget.updateWidget(
        name: 'TasksWidgetProvider',
        androidName: 'TasksWidgetProvider',
      );
      talker.info('🔄 Widget synced: Tasks ($completed/$total, $count remaining)');
    } catch (e) {
      talker.error('❌ Failed to sync Tasks widget: $e');
    }
  }

  /// Sync next doctor appointment to home widget
  /// [countdown] = human readable countdown e.g. "غداً" or "بعد 3 أيام"
  Future<void> syncAppointments({
    required String doctor,
    required String time,
    required String location,
    String countdown = '',
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('next_appt_doctor', doctor);
      await HomeWidget.saveWidgetData<String>('next_appt_time', time);
      await HomeWidget.saveWidgetData<String>('next_appt_location', location);
      await HomeWidget.saveWidgetData<String>('next_appt_countdown', countdown);
      await HomeWidget.updateWidget(
        name: 'AppointmentsWidgetProvider',
        androidName: 'AppointmentsWidgetProvider',
      );
      talker.info('🔄 Widget synced: Doctor Appointment ($doctor - $time)');
    } catch (e) {
      talker.error('❌ Failed to sync Appointments widget: $e');
    }
  }

  /// Sync daily medications progress and next dose
  Future<void> syncMedications({
    required int completed,
    required int total,
    required String nextTitle,
    required String nextTime,
  }) async {
    try {
      await HomeWidget.saveWidgetData<int>('meds_completed', completed);
      await HomeWidget.saveWidgetData<int>('meds_total', total);
      await HomeWidget.saveWidgetData<String>('next_med_title', nextTitle);
      await HomeWidget.saveWidgetData<String>('next_med_time', nextTime);
      await HomeWidget.updateWidget(
        name: 'MedicationsWidgetProvider',
        androidName: 'MedicationsWidgetProvider',
      );
      talker.info('🔄 Widget synced: Medications ($completed/$total, Next: $nextTitle)');
    } catch (e) {
      talker.error('❌ Failed to sync Medications widget: $e');
    }
  }

  /// Sync whiteboard note to home widget
  Future<void> syncWhiteboard({required String text, required String colorHex}) async {
    try {
      await HomeWidget.saveWidgetData<String>('board_text', text);
      await HomeWidget.saveWidgetData<String>('board_color', colorHex);
      await HomeWidget.updateWidget(
        name: 'WhiteboardWidgetProvider',
        androidName: 'WhiteboardWidgetProvider',
      );
      talker.info('🔄 Widget synced: Whiteboard note');
    } catch (e) {
      talker.error('❌ Failed to sync Whiteboard widget: $e');
    }
  }
}
