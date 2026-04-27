import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../../../core/services/assistant/intent_parser.dart';
import '../../../core/services/assistant/command_executor.dart';
import '../../../core/services/assistant/query_engine.dart';
import '../../../core/services/assistant/local_ai_client.dart';
import '../../../core/services/assistant/intent_router.dart';
import '../../../core/services/assistant/assistant_response.dart';
import '../../../core/services/task_time_service.dart';
import '../../../core/services/appointment_time_service.dart';
import '../../../core/services/time_service.dart';
import '../../../core/helpers/log_helper.dart';
import '../../../data/providers/task_repository.dart';
import '../../../data/providers/note_repository.dart';
import '../../../data/providers/medication_repository.dart';
import '../../../data/providers/appointment_repository.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final AssistantResponse? response; // Rich response data

  Message({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.response,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum AssistantState {
  idle,
  waitingForTaskTitle,
  waitingForNoteContent,
  waitingForJournalContent,
}

class AssistantController extends GetxController {
  final messages = <Message>[].obs;
  final isTyping = false.obs;
  final currentState = AssistantState.idle.obs;

  late final IntentRouter _router;

  // 🛡️ Debounce guard
  DateTime? _lastActionTime;

  @override
  void onInit() {
    super.onInit();

    // Build the dependency graph
    final isar = Get.find<Isar>();
    final taskRepo = Get.find<TaskRepository>();
    final noteRepo = Get.find<NoteRepository>();
    final medRepo = Get.find<MedicationRepository>();
    final appointmentRepo = Get.find<AppointmentRepository>();
    final taskTimeService = Get.find<TaskTimeService>();
    final appointmentTimeService = Get.find<AppointmentTimeService>();
    final timeService = Get.find<TimeService>();

    final parser = IntentParser();

    final commandExecutor = CommandExecutor(
      taskRepo: taskRepo,
      noteRepo: noteRepo,
      medRepo: medRepo,
      isar: isar,
    );

    final queryEngine = QueryEngine(
      taskRepo: taskRepo,
      medRepo: medRepo,
      appointmentRepo: appointmentRepo,
      taskTimeService: taskTimeService,
      appointmentTimeService: appointmentTimeService,
      timeService: timeService,
    );

    final localClient = LocalAiClient(
      parser: parser,
      commandExecutor: commandExecutor,
      queryEngine: queryEngine,
    );

    _router = IntentRouter(localClient: localClient);

    talker.info('🤖 AssistantController initialized with IntentRouter (mode: ${_router.activeMode})');
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    final greeting = _getGreeting();
    messages.add(Message(
      text: '$greeting\n${'assistant_welcome'.tr}',
      isUser: false,
    ));
  }

  /// Current AI mode for UI display
  String get aiMode => _router.activeMode;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 🛡️ 2-second cooldown
    final now = DateTime.now();
    if (_lastActionTime != null &&
        now.difference(_lastActionTime!) < const Duration(seconds: 2)) {
      return;
    }
    _lastActionTime = now;

    messages.add(Message(text: text, isUser: true));
    isTyping.value = true;

    // Humanized response delay
    final delay = 300 + (text.length * 8).clamp(0, 800);
    await Future.delayed(Duration(milliseconds: delay));

    try {
      await _processMessage(text);
    } catch (e, stack) {
      talker.handle(e, stack, '🤖 Assistant processing error');
      messages.add(Message(
        text: '${'error'.tr}: $e',
        isUser: false,
      ));
    }

    isTyping.value = false;
  }

  Future<void> _processMessage(String text) async {
    final rawText = text.trim();

    // Handle cancel from any state
    final normalized = rawText.toLowerCase();
    if (normalized == 'cancel' || normalized == 'الغاء' || normalized == 'انسى') {
      if (currentState.value != AssistantState.idle) {
        currentState.value = AssistantState.idle;
        messages.add(Message(text: 'command_cancelled'.tr, isUser: false));
        return;
      }
    }

    // Handle follow-up states (waiting for input)
    if (currentState.value != AssistantState.idle) {
      final response = await _handleFollowUp(rawText);
      messages.add(Message(text: response.text, isUser: false, response: response));
      return;
    }

    // Route through the AI client
    final response = await _router.process(rawText);

    // Check if we need to enter a waiting state
    if (response.text == 'ask_task_title'.tr) {
      currentState.value = AssistantState.waitingForTaskTitle;
    } else if (response.text == 'ask_note_content'.tr) {
      currentState.value = AssistantState.waitingForNoteContent;
    } else if (response.text == 'ask_journal_content'.tr) {
      currentState.value = AssistantState.waitingForJournalContent;
    }

    // Handle "guess add task" — enter waiting state
    if (response.text.contains('guess_add_task'.tr.split('@').first)) {
      currentState.value = AssistantState.waitingForTaskTitle;
    }

    messages.add(Message(text: response.text, isUser: false, response: response));
  }

  Future<AssistantResponse> _handleFollowUp(String text) async {
    AssistantResponse response;

    switch (currentState.value) {
      case AssistantState.waitingForTaskTitle:
        // User provided the task title
        response = await _router.process('add task $text');
        break;
      case AssistantState.waitingForNoteContent:
        response = await _router.process('add note $text');
        break;
      case AssistantState.waitingForJournalContent:
        response = await _router.process('journal $text');
        break;
      case AssistantState.idle:
        response = await _router.process(text);
        break;
    }

    currentState.value = AssistantState.idle;
    return response;
  }

  void clearChat() {
    messages.clear();
    currentState.value = AssistantState.idle;
    _addWelcomeMessage();
    talker.info('🧹 Assistant chat cleared');
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'good_morning'.tr;
    if (hour < 17) return 'good_afternoon'.tr;
    return 'good_evening'.tr;
  }
}
