import 'package:get/get.dart';
import '../message_model.dart';
import '../assistant_response.dart';
import '../query_engine.dart';
import 'package:smart_daily_tasks/app/core/helpers/log_helper.dart';
import 'intent_analyzer.dart';

/// 🏗️ Local-Only AI Orchestrator
///
/// Routes all commands to the local QueryEngine.
/// No external AI providers. No network calls.
/// Contract: NEVER throws. Always returns AssistantResponse.
class AiOrchestrator {
  final QueryEngine _queryEngine = Get.find<QueryEngine>();

  Future<AssistantResponse> processMessage(String text, List<Message> history, {String? correlationId}) async {
    try {
      final intent = IntentAnalyzer.analyze(text);

      if (correlationId != null) {
        talker.info('🧠 Orchestrator [$correlationId]: intent=${intent.name}');
      }

      return await _handleLocalIntent(intent, correlationId);

    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Orchestrator [$correlationId] error');
      return AssistantResponse.error('${'error'.tr}: $e');
    }
  }

  Future<AssistantResponse> _handleLocalIntent(IntentType intent, String? correlationId) async {
    try {
      switch (intent) {
        case IntentType.tasks:
          return await _queryEngine.queryTasks();
        case IntentType.nextTask:
          return await _queryEngine.queryNextTask();
        case IntentType.appointments:
          return await _queryEngine.queryAppointments();
        case IntentType.medications:
          return await _queryEngine.queryMedications();
        case IntentType.overview:
          return await _queryEngine.queryOverview();
        case IntentType.focus:
          return await _queryEngine.queryFocus();
        case IntentType.healthCheck:
          return await _queryEngine.queryHealthCheck();
        case IntentType.help:
          return AssistantResponse.text('assistant_help_cmd'.tr);
        case IntentType.createTask:
          return AssistantResponse.text(
            'assistant_create_task_prompt'.tr,
            stateHint: StateHint.awaitingTaskTitle,
          );
        default:
          return AssistantResponse.text('not_understood'.tr);
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Local intent [$correlationId] error');
      return AssistantResponse.error('${'error'.tr}: $e');
    }
  }
}
