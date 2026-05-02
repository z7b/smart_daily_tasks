import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../../core/services/assistant/ai_provider_config.dart';
import '../../../core/helpers/log_helper.dart';

/// 🏗️ Form Controller for AI Assistant Settings Page
///
/// Responsibilities:
/// - Owns all TextEditingControllers and FocusNodes (lifecycle-safe)
/// - Syncs form fields when the provider changes
/// - Exposes form validation state reactively
/// - NEVER calls backend directly — delegates to SettingsController
class AssistantSettingsFormController extends GetxController {
  // ── Dependencies ──────────────────────────────────────
  final SettingsController _settings = Get.find<SettingsController>();

  // ── Form Fields ───────────────────────────────────────
  late final TextEditingController apiKeyController;
  late final TextEditingController modelController;
  late final TextEditingController urlController;

  // ── Focus Nodes ───────────────────────────────────────
  late final FocusNode apiKeyFocus;
  late final FocusNode modelFocus;
  late final FocusNode urlFocus;

  // ── Reactive State ────────────────────────────────────
  final toolsEnabled = false.obs;
  final useCustomUrl = false.obs;
  final isApiKeyVisible = false.obs;

  // ── Validation State ──────────────────────────────────
  final apiKeyError = Rxn<String>();
  final modelError = Rxn<String>();
  final urlError = Rxn<String>();

  // ── Internal ──────────────────────────────────────────
  // Tracks which provider was last synced to detect actual changes
  String _lastSyncedProviderId = '';

  @override
  void onInit() {
    super.onInit();

    // Initialize controllers with current saved values
    apiKeyController = TextEditingController(text: _settings.aiApiKey.value);
    modelController = TextEditingController(text: _settings.aiModel.value);
    urlController = TextEditingController(text: _settings.aiCustomUrl.value);

    apiKeyFocus = FocusNode();
    modelFocus = FocusNode();
    urlFocus = FocusNode();

    toolsEnabled.value = _settings.aiToolsEnabled.value;
    useCustomUrl.value = _settings.aiUseCustomUrl.value;

    _lastSyncedProviderId = _settings.aiProviderId.value;

    // React to provider changes — sync form fields with newly loaded provider data
    ever(_settings.aiProviderId, (_) => _syncFieldsFromSettings());

    // Clear validation errors as user types
    apiKeyController.addListener(() => apiKeyError.value = null);
    modelController.addListener(() => modelError.value = null);
    urlController.addListener(() => urlError.value = null);

    talker.info('📝 AssistantSettingsFormController initialized for: ${_settings.aiProviderId.value}');
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

  // ── Public Methods ────────────────────────────────────

  /// Returns provider-specific placeholder text for the API key field.
  String getApiKeyHint(AiProviderType type) {
    switch (type) {
      case AiProviderType.openai:    return 'sk-proj-...';
      case AiProviderType.gemini:    return 'AIzaSy...';
      case AiProviderType.anthropic: return 'sk-ant-api03-...';
      case AiProviderType.openrouter: return 'sk-or-v1-...';
      case AiProviderType.lmStudio:
      case AiProviderType.ollama:    return 'Not required';
    }
  }

  /// Validates all form fields.
  /// Returns true if valid, false if there are errors (errors are set reactively).
  bool validateForm() {
    bool isValid = true;
    final provider = _settings.activeAiProvider;

    // API Key validation
    if (provider.requiresApiKey) {
      final key = apiKeyController.text.trim();
      if (key.isEmpty) {
        apiKeyError.value = 'api_key_required'.tr;
        isValid = false;
      } else if (key.length < 10) {
        apiKeyError.value = 'api_key_too_short'.tr;
        isValid = false;
      }
    }

    // Model validation
    if (provider.requiresModel) {
      final m = modelController.text.trim();
      if (m.isEmpty) {
        modelError.value = 'model_required'.tr;
        isValid = false;
      }
    }

    // Custom URL validation
    if (useCustomUrl.value) {
      final rawUrl = urlController.text.trim();
      if (rawUrl.isNotEmpty) {
        final uri = Uri.tryParse(rawUrl);
        if (uri == null || !uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
          urlError.value = 'invalid_url'.tr;
          isValid = false;
        }
      }
    }

    return isValid;
  }

  /// Collects current form values into a settings payload map.
  Map<String, dynamic> collectFormData() => {
    'apiKey': apiKeyController.text.trim(),
    'model': modelController.text.trim(),
    'customUrl': urlController.text.trim(),
    'useCustomUrl': useCustomUrl.value,
    'toolsEnabled': toolsEnabled.value,
  };

  // ── Private ───────────────────────────────────────────

  void _syncFieldsFromSettings() {
    if (isClosed) return;

    final providerId = _settings.aiProviderId.value;
    if (providerId == _lastSyncedProviderId) return; // Guard: no-op if same provider
    _lastSyncedProviderId = providerId;

    final config = AiProviderConfig.fromString(providerId);

    // Load saved values; fall back to provider defaults if empty
    apiKeyController.text = _settings.aiApiKey.value;

    modelController.text = _settings.aiModel.value.isNotEmpty
        ? _settings.aiModel.value
        : config.defaultModel;

    urlController.text = _settings.aiCustomUrl.value.isNotEmpty
        ? _settings.aiCustomUrl.value
        : config.defaultBaseUrl;

    toolsEnabled.value = _settings.aiToolsEnabled.value;
    useCustomUrl.value = _settings.aiUseCustomUrl.value;

    // Clear stale validation errors when switching providers
    apiKeyError.value = null;
    modelError.value = null;
    urlError.value = null;

    talker.info('🔄 Form synced for provider: $providerId (Model: ${modelController.text})');
  }
}
