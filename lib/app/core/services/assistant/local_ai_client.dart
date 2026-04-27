import 'package:get/get.dart';


import '../../../core/helpers/log_helper.dart';
import 'ai_client.dart';
import 'assistant_response.dart';
import 'intent_parser.dart';
import 'command_executor.dart';
import 'query_engine.dart';

/// Local AI client that processes intents entirely on-device.
/// Zero latency, zero internet dependency.
class LocalAiClient implements AiClient {
  final IntentParser _parser;
  final CommandExecutor _commandExecutor;
  final QueryEngine _queryEngine;

  LocalAiClient({
    required IntentParser parser,
    required CommandExecutor commandExecutor,
    required QueryEngine queryEngine,
  })  : _parser = parser,
        _commandExecutor = commandExecutor,
        _queryEngine = queryEngine;

  @override
  Future<AssistantResponse> process(String userMessage) async {
    final intent = _parser.parse(userMessage);
    talker.info('🤖 Intent: ${intent.type} (confidence: ${intent.confidence})');

    switch (intent.type) {
      // ─── Commands ─────────────────────────────────
      case IntentType.addTask:
        final payload = intent.params['payload'];
        if (payload != null && payload.isNotEmpty) {
          return _commandExecutor.addTask(payload);
        }
        return AssistantResponse.text('ask_task_title'.tr);

      case IntentType.completeTask:
        final payload = intent.params['payload'];
        if (payload != null && payload.isNotEmpty) {
          return _commandExecutor.completeTask(payload);
        }
        return AssistantResponse.text('ask_task_title'.tr);

      case IntentType.completeAllTasks:
        return _commandExecutor.completeAllTasks();

      case IntentType.addNote:
        final payload = intent.params['payload'];
        if (payload != null && payload.isNotEmpty) {
          return _commandExecutor.addNote(payload);
        }
        return AssistantResponse.text('ask_note_content'.tr);

      case IntentType.addJournal:
        final payload = intent.params['payload'];
        if (payload != null && payload.isNotEmpty) {
          return _commandExecutor.addJournal(payload);
        }
        return AssistantResponse.text('ask_journal_content'.tr);

      case IntentType.logMedication:
        return _commandExecutor.logMedication();

      case IntentType.setGoal:
        final goal = _parser.extractNumber(userMessage);
        if (goal != null && goal > 0) {
          return _commandExecutor.setStepGoal(goal);
        }
        return AssistantResponse.text('error'.tr);

      // ─── Queries ──────────────────────────────────
      case IntentType.queryTasks:
        return _queryEngine.queryTasks();

      case IntentType.queryNextTask:
        return _queryEngine.queryNextTask();

      case IntentType.queryAppointments:
        return _queryEngine.queryAppointments();

      case IntentType.queryNextAppointment:
        return _queryEngine.queryNextAppointment();

      case IntentType.queryMedications:
        return _queryEngine.queryMedications();

      case IntentType.queryNextMedication:
        return _queryEngine.queryNextMedication();

      case IntentType.queryOverview:
        return _queryEngine.queryOverview();

      // ─── Navigation ───────────────────────────────
      case IntentType.openCalendar:
        Get.toNamed('/calendar');
        return AssistantResponse.text('📅 ${'calendar'.tr}');

      case IntentType.openTasks:
        Get.toNamed('/tasks');
        return AssistantResponse.text('📝 ${'tasks'.tr}');

      case IntentType.openAppointments:
        Get.toNamed('/appointments');
        return AssistantResponse.text('🏥 ${'doctor_appointments'.tr}');

      case IntentType.openMedications:
        Get.toNamed('/medication');
        return AssistantResponse.text('💊 ${'medications'.tr}');

      case IntentType.openSettings:
        Get.toNamed('/settings');
        return AssistantResponse.text('⚙️ ${'settings'.tr}');

      // ─── Social ───────────────────────────────────
      case IntentType.greeting:
        return AssistantResponse.text('assistant_greeting'.tr);

      case IntentType.help:
        return AssistantResponse.text('assistant_help_cmd'.tr);

      case IntentType.cancel:
        return AssistantResponse.text('command_cancelled'.tr);

      // ─── Unknown ──────────────────────────────────
      case IntentType.unknown:
        final guessTitle = intent.params['guessTitle'];
        if (guessTitle != null) {
          return AssistantResponse.text(
            'guess_add_task'.trParams({'title': guessTitle}),
          );
        }
        return AssistantResponse.text('not_understood'.tr);
    }
  }
}
