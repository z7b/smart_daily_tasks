
import 'package:get/get.dart';
import '../core/helpers/log_helper.dart';

import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/tasks/bindings/tasks_binding.dart';
import '../modules/tasks/views/tasks_view.dart';
import '../modules/tasks/views/add_task_view.dart';
import '../modules/notes/bindings/notes_binding.dart';
import '../modules/notes/views/notes_view.dart';
import '../modules/notes/views/add_note_view.dart';
import '../modules/journal/bindings/journal_binding.dart';
import '../modules/journal/views/journal_view.dart';
import '../modules/bookmarks/bindings/bookmarks_binding.dart';
import '../modules/bookmarks/views/bookmarks_view.dart';
import '../modules/bookmarks/views/add_bookmark_view.dart';
import '../modules/calendar/bindings/calendar_binding.dart';
import '../modules/calendar/views/calendar_view.dart';
import '../modules/appointments/bindings/appointments_binding.dart';
import '../modules/appointments/views/appointments_view.dart';
import '../modules/appointments/views/add_appointment_view.dart';
import '../modules/assistant/bindings/assistant_binding.dart';
import '../modules/assistant/views/assistant_view.dart';
import '../modules/books/bindings/books_binding.dart';
import '../modules/books/views/book_view.dart';
import '../modules/medication/bindings/medication_binding.dart';
import '../modules/medication/views/medication_view.dart';
import '../modules/steps/bindings/steps_binding.dart';
import '../modules/steps/views/steps_view.dart';
import '../modules/steps/views/health_rationale_view.dart';
import '../modules/job/bindings/job_binding.dart';
import '../modules/job/views/job_view.dart';
import '../modules/job/views/job_settings_view.dart';
import '../modules/settings/controllers/settings_controller.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.HOME;

  static String get savedStartRoute {
    try {
      return Get.find<SettingsController>().getSavedStartRoute();
    } catch (e, stack) {
      talker.handle(e, stack, '⚠️ Error reading saved start route');
      return Routes.HOME;
    }
  }

  static final routes = [
    GetPage(
      name: Routes.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.TASKS,
      page: () => const TasksView(),
      binding: TasksBinding(),
    ),
    GetPage(
      name: Routes.ADD_TASK,
      page: () => const AddTaskView(),
      binding: TasksBinding(),
    ),
    GetPage(
      name: Routes.NOTES,
      page: () => const NotesView(),
      binding: NotesBinding(),
    ),
    GetPage(
      name: Routes.ADD_NOTE,
      page: () => const AddNoteView(),
      binding: NotesBinding(),
    ),
    GetPage(
      name: Routes.JOURNAL,
      page: () => const JournalView(),
      binding: JournalBinding(),
    ),
    GetPage(
      name: Routes.BOOKMARKS,
      page: () => const BookmarksView(),
      binding: BookmarksBinding(),
    ),
    GetPage(
      name: Routes.ADD_BOOKMARK,
      page: () => const AddBookmarkView(),
      binding: BookmarksBinding(),
    ),
    GetPage(
      name: Routes.CALENDAR,
      page: () => const CalendarView(),
      binding: CalendarBinding(),
    ),
    GetPage(
      name: Routes.APPOINTMENTS,
      page: () => const AppointmentsView(),
      binding: AppointmentsBinding(),
    ),
    GetPage(
      name: Routes.ADD_APPOINTMENT,
      page: () => const AddAppointmentView(),
      binding: AppointmentsBinding(),
    ),
    GetPage(
      name: Routes.ASSISTANT,
      page: () => const AssistantView(),
      binding: AssistantBinding(),
    ),
    GetPage(
      name: Routes.BOOKS,
      page: () => const BookView(),
      binding: BooksBinding(),
    ),
    GetPage(
      name: Routes.MEDICATION,
      page: () => const MedicationView(),
      binding: MedicationBinding(),
    ),
    GetPage(
      name: Routes.STEPS,
      page: () => const StepsView(),
      binding: StepsBinding(),
    ),
    GetPage(
      name: Routes.JOB,
      page: () => const JobView(),
      binding: JobBinding(),
    ),
    GetPage(
      name: Routes.JOB_SETTINGS,
      page: () => const JobSettingsView(),
      binding: JobBinding(),
    ),
    GetPage(
      name: Routes.HEALTH_RATIONALE,
      page: () => const HealthRationaleView(),
    ),
  ];
}
