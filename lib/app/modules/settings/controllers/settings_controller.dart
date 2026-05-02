import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/config/settings_enums.dart';
import '../../../core/theme/theme_service.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/security_service.dart';
import '../../../core/services/app_lock_service.dart';
import 'package:smart_daily_tasks/app/core/services/notification_service.dart' as ns;
import '../../../core/helpers/log_helper.dart';
import '../../../core/config/storage_keys.dart';
import '../../../core/services/assistant/ai_provider_config.dart';
import '../../../core/services/assistant/external_ai_client.dart';
import '../../../core/services/assistant/ai_client_manager.dart';

class SettingsController extends GetxController {
  late final ThemeService _themeService;
  late final SecurityService _securityService;
  late final AppLockService _appLockService;
  final _box = GetStorage();

  RxBool isDarkMode = true.obs;
  RxString currentLanguage = 'ar'.obs;
  RxString startScreen = 'home'.obs;
  RxString fontType = 'Rubik'.obs;
  RxString fontSize = 'medium'.obs;
  RxString firstDayOfWeek = 'sunday'.obs;
  RxBool preventScreenshots = false.obs;
  RxBool appLock = false.obs;
  RxBool useArabicNumbers = false.obs;

  // AI Configuration
  RxString aiProviderId = 'gemini'.obs;
  RxString aiApiKey = ''.obs;
  RxString aiModel = ''.obs;
  RxString aiCustomUrl = ''.obs;
  RxBool aiUseCustomUrl = false.obs;
  RxBool aiToolsEnabled = true.obs;

  // AI Analytics & State
  RxInt aiTotalRequests = 0.obs;
  RxString aiLastResponseTime = '0ms'.obs;
  RxString aiLastStatus = 'idle'.obs;
  RxBool isTestingAi = false.obs;
  RxBool isSavingAi = false.obs;

  RxString notificationStatus = 'pending'.obs;

  final List<String> fontOptions = ['Rubik', 'Cairo', 'Amiri', 'Tajawal'];
  final List<String> fontSizeKeys = ['small', 'medium', 'large'];
  final List<String> startScreenKeys = StartScreen.values.map((e) => e.key).toList();
  final List<String> dayOfWeekKeys = DayOfWeek.values.map((e) => e.key).toList();

  AiProviderConfig get activeAiProvider => AiProviderConfig.fromString(aiProviderId.value);
  bool get isAiConfigured => aiApiKey.value.trim().isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _themeService = Get.find<ThemeService>();
    _securityService = Get.find<SecurityService>();
    _appLockService = Get.find<AppLockService>();
    _loadCurrentSettings();
    Future.delayed(const Duration(seconds: 5), () => checkNotificationStability(silent: true));
  }

  void _loadCurrentSettings() {
    isDarkMode.value = _themeService.isDarkMode;
    currentLanguage.value = _themeService.getLocale().languageCode;
    fontType.value = _themeService.fontTypeRx.value;
    fontSize.value = _themeService.fontSizeRx.value;
    preventScreenshots.value = _securityService.isScreenshotPrevented.value;
    appLock.value = _appLockService.isAppLockEnabled.value;
    useArabicNumbers.value = _themeService.useArabicNumbersRx.value;
    startScreen.value = _box.read(StorageKeys.startScreen) ?? 'home';
    firstDayOfWeek.value = _box.read('firstDayOfWeek') ?? 'sunday';

    final storedProviderId = _box.read('ai_provider_id') ?? 'gemini';
    aiProviderId.value = storedProviderId;
    _loadAiProviderDetails(storedProviderId);
  }

  void _loadAiProviderDetails(String providerId) {
    final typeName = AiProviderConfig.fromString(providerId).type.name;
    aiApiKey.value = _box.read('${typeName}_api_key') ?? '';
    aiModel.value = _box.read('${typeName}_model') ?? '';
    aiCustomUrl.value = _box.read('${typeName}_custom_url') ?? '';
    aiUseCustomUrl.value = _box.read('${typeName}_use_custom_url') ?? false;
    aiToolsEnabled.value = _box.read('${typeName}_tools_enabled') ?? true;
  }

  // --- Theme & General Actions ---
  void toggleTheme() {
    _themeService.switchTheme();
    isDarkMode.value = _themeService.isDarkModeRx.value;
  }

  void changeFontType() {
    _showSelectionDialog(title: 'font_type'.tr, options: fontOptions, currentValue: fontType.value, onSelected: (val) {
      fontType.value = val;
      _themeService.switchFont(val);
    });
  }

  void changeFontSize() {
    _showSelectionDialog(title: 'font_size'.tr, options: fontSizeKeys, currentValue: fontSize.value, onSelected: (val) {
      fontSize.value = val;
      _themeService.switchFontSize(val);
    });
  }

  void changeLanguage(String lang) {
    currentLanguage.value = lang;
    _themeService.saveLocale(lang);
    Get.updateLocale(lang == 'ar' ? const Locale('ar', 'SA') : const Locale('en', 'US'));
  }

  void changeFirstDayOfWeek() {
    _showSelectionDialog(title: 'first_day_of_week'.tr, options: dayOfWeekKeys, currentValue: firstDayOfWeek.value, onSelected: (val) {
      firstDayOfWeek.value = val;
      _box.write('firstDayOfWeek', val);
    });
  }

  void changeStartScreen() {
    _showSelectionDialog(title: 'start_screen'.tr, options: startScreenKeys, currentValue: startScreen.value, onSelected: (val) {
      startScreen.value = val;
      _box.write(StorageKeys.startScreen, val);
    });
  }

  void toggleAppLock([dynamic value]) async {
    await _appLockService.toggleAppLock();
    appLock.value = _appLockService.isAppLockEnabled.value;
  }

  void togglePreventScreenshots([dynamic value]) async {
    await _securityService.toggleScreenshotPrevention();
    preventScreenshots.value = _securityService.isScreenshotPrevented.value;
  }

  void toggleNumberFormat() {
    final newValue = !useArabicNumbers.value;
    useArabicNumbers.value = newValue;
    _themeService.switchNumberFormat(newValue);
  }

  String getSavedStartRoute() {
    final key = _box.read(StorageKeys.startScreen) ?? 'home';
    return '/$key';
  }

  // --- AI Actions ---
  void changeAiProvider(String newProviderId) {
    if (aiProviderId.value == newProviderId) return;
    _box.write('ai_provider_id', newProviderId);
    _loadAiProviderDetails(newProviderId);
    isTestingAi.value = false;
    aiProviderId.value = newProviderId;
    talker.info('🤖 AI Provider switched to: $newProviderId');
  }

  void resetAiCircuitBreaker() {
    AiClientManager.instance.resetFailureCount();
    _showSnackbar('success'.tr, 'circuit_breaker_reset'.tr);
  }

  Future<void> testAiConnection({required String apiKey, required String model, required String customUrl, required bool useCustomUrl}) async {
    if (isTestingAi.value) return;
    isTestingAi.value = true;
    
    await runZonedGuarded(() async {
      final apiUrl = useCustomUrl && customUrl.trim().isNotEmpty ? customUrl.trim() : activeAiProvider.defaultBaseUrl;
      final baseUri = Uri.tryParse(apiUrl);
      
      if (baseUri == null || !baseUri.hasScheme) { 
        _updateAiStatusOnFailure('invalid_url'); 
        return; 
      }
      
      talker.info('🧪 Starting AI Connection Test for: ${baseUri.host}');
      await _performTestConnection(baseUri, apiKey, model, activeAiProvider);
    }, (error, stack) {
      talker.error('🛡️ RELIABILITY SHIELD: Caught a potential native crash: $error');
      _updateAiStatusOnFailure(error.toString());
    });

    isTestingAi.value = false;
  }

  Future<void> _performTestConnection(Uri baseUri, String apiKey, String model, AiProviderConfig provider) async {
    final stopWatch = Stopwatch()..start();
    aiLastStatus.value = 'testing';
    Map<String, String> headers = {'Content-Type': 'application/json'};
    Map<String, dynamic> body = {};
    Uri requestUri = baseUri;
    final resolvedModel = model.trim().isNotEmpty ? model.trim() : provider.defaultModel;

    if (provider.type == AiProviderType.openai) {
      requestUri = baseUri.replace(path: '/v1/chat/completions');
      headers['Authorization'] = 'Bearer ${apiKey.trim()}';
      body = {'model': resolvedModel, 'messages': [{'role': 'user', 'content': 'hi'}], 'max_tokens': 1};
    } else if (provider.type == AiProviderType.gemini) {
      requestUri = baseUri.replace(path: '/v1beta/models/${resolvedModel.replaceAll('models/', '')}:generateContent').replace(queryParameters: {'key': apiKey.trim()});
      body = {'contents': [{'role': 'user', 'parts': [{'text': 'hi'}]}]};
    }

    final res = await AiClientManager.instance.postWithRetry(requestUri, headers: headers, body: jsonEncode(body));
    stopWatch.stop();
    aiLastResponseTime.value = '${stopWatch.elapsedMilliseconds}ms';
    aiTotalRequests.value++;

    if (res.isSuccess) {
      aiLastStatus.value = 'success';
      _showSnackbar('success'.tr, 'connection_successful'.tr);
    } else { _updateAiStatusOnFailure(res.error ?? 'error'); }
  }

  void _updateAiStatusOnFailure(String error) {
    aiLastStatus.value = 'error';
    _showSnackbar('error'.tr, error.contains('timeout') ? 'timeout_error'.tr : 'connection_failed'.tr, isError: true);
  }

  Future<bool> saveAiSettings({required String apiKey, required String model, required String customUrl, required bool useCustomUrl, required bool toolsEnabled}) async {
    if (isSavingAi.value) return false;
    
    final provider = activeAiProvider;
    if (provider.requiresApiKey && apiKey.trim().isEmpty) { _showSnackbar('error'.tr, 'api_key_required'.tr, isError: true); return false; }
    
    final trimmedUrl = customUrl.trim();
    if (useCustomUrl && trimmedUrl.isNotEmpty) {
      final uri = Uri.tryParse(trimmedUrl);
      if (uri == null || !uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        _showSnackbar('error'.tr, 'invalid_url'.tr, isError: true); return false;
      }
    }

    isSavingAi.value = true;
    try {
      final typeName = provider.type.name;
      aiApiKey.value = apiKey.trim();
      aiModel.value = model.trim();
      aiCustomUrl.value = trimmedUrl;
      aiUseCustomUrl.value = useCustomUrl;
      aiToolsEnabled.value = toolsEnabled;

      _box.write('${typeName}_api_key', aiApiKey.value);
      _box.write('${typeName}_model', aiModel.value);
      _box.write('${typeName}_custom_url', aiCustomUrl.value);
      _box.write('${typeName}_use_custom_url', aiUseCustomUrl.value);
      _box.write('${typeName}_tools_enabled', aiToolsEnabled.value);

      _showSnackbar('success'.tr, 'settings_saved_successfully'.tr);
      talker.info('💾 AI Settings Saved for $typeName');
      return true;
    } finally {
      isSavingAi.value = false;
    }
  }

  Future<void> discoverGeminiModels(String apiKey) async {
    if (apiKey.trim().isEmpty) return;
    isTestingAi.value = true;
    try {
      final models = await ExternalAiClient.listAvailableModels(config: activeAiProvider, apiKey: apiKey.trim());
      if (models.isNotEmpty) aiModel.value = models.first;
    } finally { isTestingAi.value = false; }
  }

  Future<void> checkNotificationStability({bool silent = false}) async {
    final isStable = await Get.find<ns.NotificationService>().isSystemStable();
    notificationStatus.value = isStable ? 'amazing' : 'pending';
  }

  Future<void> createBackup() async { await BackupService().createBackup(); _showSnackbar('success'.tr, 'data_exported_successfully'.tr); }
  Future<void> restoreBackup() async { await BackupService().restoreBackup(); Get.offAllNamed('/home'); }

  void _showSelectionDialog({required String title, required List<String> options, required String currentValue, required Function(String) onSelected}) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Get.theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...options.map((opt) => ListTile(
              title: Text(opt.tr),
              trailing: opt == currentValue ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () { onSelected(opt); Get.back(); },
            )),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(String title, String message, {bool isError = false}) {
    Get.rawSnackbar(title: title, message: message, backgroundColor: isError ? Colors.red : Colors.green);
  }
}
