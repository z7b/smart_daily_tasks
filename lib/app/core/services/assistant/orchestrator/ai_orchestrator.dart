import 'package:get/get.dart';
import '../message_model.dart';
import '../assistant_response.dart';
import '../external_ai_client.dart';
import '../query_engine.dart';
import 'package:smart_daily_tasks/app/modules/settings/controllers/settings_controller.dart';
import 'package:smart_daily_tasks/app/core/helpers/log_helper.dart';
import 'intent_analyzer.dart';
import 'model_router.dart';
import 'prompt_builder.dart';

/// 🏗️ Production-Grade AI Orchestrator
/// 
/// Contract: NEVER throws exceptions. Always returns AssistantResponse.
class AiOrchestrator {
  final QueryEngine _queryEngine = Get.find<QueryEngine>();
  final ModelRouter _router = ModelRouter();
  final SettingsController _settings = Get.find<SettingsController>();

  /// Process a message with full error isolation.
  /// Returns AssistantResponse — never throws.
  Future<AssistantResponse> processMessage(String text, List<Message> history, {String? correlationId}) async {
    try {
      // 1. Analyze Intent
      final intent = IntentAnalyzer.analyze(text);
      
      if (correlationId != null) {
        talker.info('🧠 Orchestrator [$correlationId]: Detected intent ${intent.name}');
      }

      // 2. Handle simple local intents directly (Optimization — no network needed)
      if (_isPurelyLocal(intent) && !_isConversational(text)) {
        return await _handleLocalIntent(intent, correlationId);
      }

      // 3. Routing & AI Processing
      final provider = _router.getBestProvider(intent);
      final client = ExternalAiClient(
        config: provider,
        apiKey: _settings.aiApiKey.value,
        model: _settings.aiModel.value,
        customBaseUrl: _settings.aiUseCustomUrl.value ? _settings.aiCustomUrl.value : '',
        toolsEnabled: _settings.aiToolsEnabled.value,
      );

      final systemContext = PromptBuilder.buildSystemPrompt(intent: intent);

      return await client.process(history, systemContext: systemContext, correlationId: correlationId);

    } catch (e, stack) {
      // 🛡️ Nuclear Safety Net — nothing escapes the orchestrator
      talker.handle(e, stack, '🔴 Orchestrator [$correlationId] unhandled error');
      return AssistantResponse.error('${'error'.tr}: $e');
    }
  }

  bool _isPurelyLocal(IntentType intent) {
    return intent != IntentType.general && intent != IntentType.createTask;
  }

  bool _isConversational(String text) {
    // Short queries (≤7 words) are likely simple commands that can be handled locally.
    // Longer text likely needs AI for nuanced understanding.
    return text.trim().split(' ').length > 7;
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
        default:
          return const AssistantResponse(text: 'I am not sure how to help with that locally.');
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Local intent [$correlationId] error');
      return AssistantResponse.error('${'error'.tr}: $e');
    }
  }
}
