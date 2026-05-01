import 'package:get/get.dart';
import '../ai_provider_config.dart';
import '../ai_health_tracker.dart';
import 'package:smart_daily_tasks/app/modules/settings/controllers/settings_controller.dart';
import 'intent_analyzer.dart';

class ModelRouter {
  final SettingsController _settings = Get.find<SettingsController>();

  AiProviderConfig getBestProvider(IntentType intent) {
    final active = _settings.activeAiProvider;
    
    // Logic: If active is degraded, try to find a healthy fallback
    if (!AiHealthTracker.isHealthy(active.type.name, _settings.aiModel.value)) {
      return _findFallbackProvider() ?? active;
    }

    return active;
  }

  AiProviderConfig? _findFallbackProvider() {
    // Basic fallback logic: If GPT is down, try Gemini. If Gemini is down, try Ollama if configured.
    // In a real app, this could be more sophisticated.
    return null; // For now, return null to use the error handling in client
  }
}
