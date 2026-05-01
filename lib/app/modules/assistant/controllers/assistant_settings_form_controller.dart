import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../../core/services/assistant/ai_provider_config.dart';

class AssistantSettingsFormController extends GetxController {
  final SettingsController settingsController = Get.find<SettingsController>();

  late final TextEditingController apiKeyController;
  late final TextEditingController modelController;
  late final TextEditingController urlController;
  
  late final FocusNode apiKeyFocus;
  late final FocusNode modelFocus;
  late final FocusNode urlFocus;

  @override
  void onInit() {
    super.onInit();
    
    apiKeyController = TextEditingController(text: settingsController.aiApiKey.value);
    modelController = TextEditingController(text: settingsController.aiModel.value);
    urlController = TextEditingController(text: settingsController.aiCustomUrl.value);
    
    apiKeyFocus = FocusNode();
    modelFocus = FocusNode();
    urlFocus = FocusNode();

    // Listen to provider changes to clean up and replace form data properly
    ever(settingsController.aiProviderId, (_) {
      _syncFieldsWithSettings();
    });
  }

  void _syncFieldsWithSettings() {
    if (isClosed) return;
    apiKeyController.text = settingsController.aiApiKey.value;
    modelController.text = settingsController.aiModel.value;
    urlController.text = settingsController.aiCustomUrl.value;
  }
  
  /// Get dynamic hint text based on the provider type
  String getApiKeyHint(AiProviderType type) {
    switch (type) {
      case AiProviderType.openai:
        return 'sk-...';
      case AiProviderType.gemini:
        return 'AIzaSy...';
      case AiProviderType.anthropic:
        return 'sk-ant-...';
      case AiProviderType.openrouter:
        return 'sk-or-v1-...';
      case AiProviderType.lmStudio:
      case AiProviderType.ollama:
        return 'Not required';
    }
  }

  @override
  void onClose() {
    apiKeyController.dispose();
    modelController.dispose();
    urlController.dispose();
    apiKeyFocus.dispose();
    modelFocus.dispose();
    urlFocus.dispose();
    super.onClose();
  }
}
