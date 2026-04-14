import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/note_model.dart';
import '../../../data/models/journal_model.dart';
import '../../../data/providers/task_repository.dart';
import '../../../data/providers/note_repository.dart';
import '../../../data/providers/journal_repository.dart';
import '../../../data/providers/medication_repository.dart';
import '../../../core/helpers/log_helper.dart';
import '../../../core/extensions/date_time_extensions.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({required this.text, required this.isUser, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

class AssistantController extends GetxController {
  final messages = <Message>[].obs;
  final isTyping = false.obs;

  late final TaskRepository _taskRepository;
  late final NoteRepository _noteRepository;
  late final MedicationRepository _medicationRepository;

  @override
  void onInit() {
    super.onInit();
    _taskRepository = Get.find<TaskRepository>();
    _noteRepository = Get.find<NoteRepository>();
    _medicationRepository = Get.find<MedicationRepository>();
    talker.info('🤖 AssistantController initialized');
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    // ✅ Doctoral Fix: Using translation key for the whole welcome block
    messages.add(
      Message(
        text: 'assistant_welcome'.tr,
        isUser: false,
      ),
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    messages.add(Message(text: text, isUser: true));
    isTyping.value = true;
    await Future.delayed(const Duration(milliseconds: 600));
    await _processCommand(text);
    isTyping.value = false;
  }

  Future<void> _processCommand(String text) async {
    final lowerText = text.toLowerCase().trim();
    String responseText = '';

    try {
      final taskRegex = RegExp(r'^(?:add|new|create|make|ضيف|أضف|انشاء|إنشاء)\s+(?:task|todo|مهمة)(?:\s+(.+))?', caseSensitive: false);
      final noteRegex = RegExp(r'^(?:add|new|write|take|ضيف|أضف|دون|اكتب|إنشاء)\s+(?:note|memo|ملاحظة)(?:\s+(.+))?', caseSensitive: false);
      final journalRegex = RegExp(r'^(?:log|journal|diary|record|سجل|يوميات|مذكرة|تدوين|كتبت)(?:\s+(.+))?', caseSensitive: false);
      final medRegex = RegExp(r'^(?:took|taken|had|log|record|أخذت|شربت|سجل|تم|تناولت|بلعت)\s+(?:med|medication|medicine|pill|dose|tabs|الدواء|العلاج|الحبة|الجرعة|برشام|علاجي)(?:\s+(.+))?', caseSensitive: false);

      if (lowerText.contains('hello') || lowerText.contains('hi') || lowerText.contains('مرحبا')) {
        responseText = 'assistant_greeting'.tr;
      } else if (taskRegex.hasMatch(text)) {
        final match = taskRegex.firstMatch(text);
        final title = match?.group(1)?.trim();
        if (title != null && title.isNotEmpty) {
          await _addTask(title);
          responseText = 'task_added_success'.trParams({'title': title});
        } else {
          responseText = 'ask_task_title'.tr;
        }
      } else if (noteRegex.hasMatch(text)) {
        final match = noteRegex.firstMatch(text);
        final content = match?.group(1)?.trim();
        if (content != null && content.isNotEmpty) {
          await _addNote(content);
          responseText = 'note_added_success'.tr;
        } else {
          responseText = 'ask_note_content'.tr;
        }
      } else if (journalRegex.hasMatch(text)) {
        final match = journalRegex.firstMatch(text);
        final content = match?.group(1)?.trim();
        if (content != null && content.isNotEmpty) {
          await _addJournal(content);
          responseText = 'journal_added_success'.tr;
        } else {
          responseText = 'ask_journal_content'.tr;
        }
      } else if (medRegex.hasMatch(text)) {
        responseText = await _recordMedicationIntake();
      } else if (lowerText.contains('help') || lowerText.contains('مساعدة')) {
        responseText = 'assistant_help_cmd'.tr;
      } else if (lowerText.contains('calendar') || lowerText.contains('تقويم')) {
        Get.toNamed('/calendar');
        responseText = '📅 ' + 'calendar'.tr;
      } else {
        responseText = 'not_understood'.tr;
      }
      messages.add(Message(text: responseText, isUser: false));
    } catch (e, stack) {
      talker.handle(e, stack, '🤖 Assistant command processing error');
      messages.add(Message(text: 'error'.tr + ': $e', isUser: false));
    }
  }

  Future<void> _addTask(String title) async {
    final task = Task(
      title: title,
      scheduledAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
    await _taskRepository.addTask(task);
  }

  Future<void> _addNote(String content) async {
    final note = Note(
      title: 'add_note'.tr,
      content: content,
      createdAt: DateTime.now(),
    );
    await _noteRepository.addNote(note);
  }

  Future<void> _addJournal(String content) async {
    final journal = Journal(
      date: DateTime.now(),
      mood: Mood.neutral,
      note: content,
      createdAt: DateTime.now(),
    );
    await Get.find<JournalRepository>().addJournal(journal);
  }

  Future<String> _recordMedicationIntake() async {
    try {
      final meds = await _medicationRepository.getAllMedications();
      final activeMeds = meds.where((m) => m.isActive).toList();
      
      if (activeMeds.isEmpty) {
        return 'no_active_meds'.tr;
      }

      // Doctoral Logic: Find the first medication that hasn't reached its daily dose limit
      final now = DateTime.now();
      for (var med in activeMeds) {
        final todayIntakes = med.intakeHistory.where((dt) => dt.isSameDay(now)).length;
        
        if (todayIntakes < med.reminderTimes.length) {
          await _medicationRepository.logIntake(med.id);
          return 'med_logged_success'.trParams({'name': med.name});
        }
      }

      return 'all_meds_taken_today'.tr;
    } catch (e) {
      return 'error'.tr + ': $e';
    }
  }

  void clearChat() {
    messages.clear();
    _addWelcomeMessage();
  }
}
