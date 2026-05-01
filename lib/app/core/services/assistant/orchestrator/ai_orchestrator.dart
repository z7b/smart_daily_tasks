import 'package:get/get.dart';
import '../message_model.dart';
import '../assistant_response.dart';
import '../external_ai_client.dart';
import '../query_engine.dart';
import 'package:smart_daily_tasks/app/modules/settings/controllers/settings_controller.dart';
import 'intent_analyzer.dart';
import 'model_router.dart';
import 'prompt_builder.dart';

class AiOrchestrator {
  final QueryEngine _queryEngine = Get.find<QueryEngine>();
  final ModelRouter _router = ModelRouter();
  final SettingsController _settings = Get.find<SettingsController>();

  Future<AssistantResponse> processMessage(String text, List<Message> history) async {
    // 1. Analyze Intent
    final intent = IntentAnalyzer.analyze(text);

    // 2. Handle simple local intents directly (Optimization)
    if (_isPurelyLocal(intent) && !_isConversational(text)) {
      return await _handleLocalIntent(intent);
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

    return await client.process(history, systemContext: systemContext);
  }

  bool _isPurelyLocal(IntentType intent) {
    return intent != IntentType.general && intent != IntentType.createTask;
  }

  bool _isConversational(String text) {
    // If the text is long or contains complex words, it might need AI even for local intents
    return text.trim().split(' ').length > 4;
  }

  Future<AssistantResponse> _handleLocalIntent(IntentType intent) async {
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
  }
}
