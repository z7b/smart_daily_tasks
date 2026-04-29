import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/config/settings_enums.dart';
import '../../../core/theme/theme_service.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/security_service.dart';
import '../../../core/services/app_lock_service.dart';
import 'package:smart_daily_tasks/app/core/services/notification_service.dart'
    as ns;
import '../../../core/helpers/bottom_sheet_helper.dart';
import '../../../core/helpers/log_helper.dart';
import '../../../core/config/storage_keys.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/assistant/ai_provider_config.dart';
import '../../../core/services/assistant/external_ai_client.dart';

class SettingsController extends GetxController {
  late final ThemeService _themeService;
  late final SecurityService _securityService;
  late final AppLockService _appLockService;
  final _box = GetStorage();

  RxBool isDarkMode = true.obs;
  RxString currentLanguage = 'ar'.obs;

  // Settings Observables
  RxString startScreen = 'home'.obs;
  RxString fontType = 'Rubik'.obs;
  RxString fontSize = 'medium'.obs;
  RxString firstDayOfWeek = 'sunday'.obs;
  RxBool preventScreenshots = false.obs;
  RxBool appLock = false.obs;
  RxBool useArabicNumbers = false.obs;

  // ✅ Smart Assistant AI Provider Configuration
  RxString aiProviderId = 'gemini'.obs;
  RxString aiApiKey = ''.obs;
  RxString aiModel = ''.obs;
  RxString aiCustomUrl = ''.obs;
  RxBool aiUseCustomUrl = false.obs;
  RxBool aiToolsEnabled = true.obs;

  AiProviderConfig get activeAiProvider =>
      AiProviderConfig.fromString(aiProviderId.value);

  bool get isAiConfigured {
    final provider = activeAiProvider;
    if (provider.requiresApiKey && aiApiKey.value.trim().isEmpty) return false;
    if (provider.requiresModel && aiModel.value.trim().isEmpty) return false;
    return true;
  }

  // ✅ Notification Stability Governance
  RxString notificationStatus = 'pending'.obs; // pending, amazing, error

  // Biometrics Governance
  RxBool get isBiometricAvailable => _appLockService.isBiometricAvailable;
  RxBool get isBiometricEnabled => _appLockService.isBiometricEnabled;

  final List<String> fontOptions = ['Rubik', 'Cairo', 'Amiri', 'Tajawal'];
  final List<String> fontSizeKeys = ['small', 'medium', 'large'];
  final List<String> startScreenKeys = StartScreen.values
      .map((e) => e.key)
      .toList();
  final List<String> dayOfWeekKeys = DayOfWeek.values
      .map((e) => e.key)
      .toList();

  @override
  void onInit() {
    super.onInit();
    _themeService = Get.find<ThemeService>();
    _securityService = Get.find<SecurityService>();
    _appLockService = Get.find<AppLockService>();

    talker.info('⚙️ SettingsController initialized');
    _loadCurrentSettings();
    // ✅ Phase 4: Defer non-critical stability checks to avoid racing with startup/Isar
    Future.delayed(
      const Duration(seconds: 5),
      () => checkNotificationStability(silent: true),
    );
  }

  void _loadCurrentSettings() {
    try {
      isDarkMode.value = _themeService.isDarkMode;
      currentLanguage.value = _themeService.getLocale().languageCode;

      fontType.value = _themeService.fontTypeRx.value;
      fontSize.value = _themeService.fontSizeRx.value;

      preventScreenshots.value = _securityService.isScreenshotPrevented.value;
      appLock.value = _appLockService.isAppLockEnabled.value;
      useArabicNumbers.value = _themeService.useArabicNumbersRx.value;

      startScreen.value = _box.read(StorageKeys.startScreen) ?? 'home';
      firstDayOfWeek.value = _box.read('firstDayOfWeek') ?? 'sunday';

      appLock.value = _appLockService.isAppLockEnabled.value;
      useArabicNumbers.value = _box.read('useArabicNumbers') ?? false;

      // Load AI Provider configs
      final storedProviderId = _box.read('ai_provider_id') ?? 'gemini';
      // Ensure the stored ID still exists in our provider list
      if (AiProviderConfig.providers.any(
        (p) => p.type.name == storedProviderId,
      )) {
        aiProviderId.value = storedProviderId;
      } else {
        aiProviderId.value = 'gemini';
        _box.write('ai_provider_id', 'gemini');
      }
      _loadAiProviderDetails(aiProviderId.value);
    } catch (e) {
      talker.error('⚠️ Settings Load Error: $e');
    }
  }

  void _loadAiProviderDetails(String providerId) {
    final config = AiProviderConfig.fromString(providerId);
    aiApiKey.value = _box.read('${providerId}_api_key') ?? '';
    aiModel.value = _box.read('${providerId}_model') ?? config.defaultModel;
    aiCustomUrl.value =
        _box.read('${providerId}_custom_url') ?? config.defaultBaseUrl;
    aiUseCustomUrl.value = _box.read('${providerId}_use_custom_url') ?? false;
    aiToolsEnabled.value = _box.read('${providerId}_tools_enabled') ?? true;
  }

  static String getSavedStartRoute() {
    try {
      final box = GetStorage();
      final String? key = box.read(StorageKeys.startScreen);
      return StartScreen.fromKey(key).routePath;
    } catch (e) {
      return StartScreen.home.routePath;
    }
  }

  void toggleTheme() {
    _themeService.switchTheme();
    isDarkMode.value = _themeService.isDarkMode;
  }

  void changeLanguage(String languageCode) {
    currentLanguage.value = languageCode;
    _themeService.saveLocale(languageCode);
    Get.updateLocale(Locale(languageCode));
    talker.info('🌐 Language UI Updated: $languageCode');
  }

  void changeFontSize() {
    _showOptionsSheet(
      options: fontSizeKeys,
      current: fontSize,
      // ✅ Expert Preview Logic: Scaling text in the sheet to match the actual size
      textStyleBuilder: (option) =>
          TextStyle(fontSize: 16 * AppTheme.fontSizeScale(option)),
      onSelected: (value) {
        fontSize.value = value;
        _themeService.switchFontSize(value);
      },
    );
  }

  void changeFontType() {
    _showFontSheet();
  }

  Future<void> togglePreventScreenshots() async {
    await _securityService.toggleScreenshotPrevention();
    preventScreenshots.value = _securityService.isScreenshotPrevented.value;

    Get.snackbar(
      'security'.tr, // ✅ Fixed: Showing "الأمان"
      preventScreenshots.value
          ? 'screenshots_enabled'.tr
          : 'screenshots_disabled'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> toggleAppLock() async {
    await _appLockService.toggleAppLock();
    appLock.value = _appLockService.isAppLockEnabled.value;
  }

  void toggleNumberFormat() {
    bool newValue = !useArabicNumbers.value;
    useArabicNumbers.value = newValue;
    _themeService.switchNumberFormat(newValue);
  }

  void toggleBiometric() {
    // Removed as per expert design request: System handles fallback automatically
  }

  void changeStartScreen() {
    _showOptionsSheet(
      options: startScreenKeys,
      current: startScreen,
      onSelected: (value) {
        startScreen.value = value;
        _box.write(StorageKeys.startScreen, value);
      },
    );
  }

  void changeFirstDayOfWeek() {
    _showOptionsSheet(
      options: dayOfWeekKeys,
      current: firstDayOfWeek,
      onSelected: (value) {
        firstDayOfWeek.value = value;
        _box.write('firstDayOfWeek', value);
      },
    );
  }

  // ─── Smart Assistant AI Config ─────────────────────

  void changeAiProvider(String newProviderId) {
    if (aiProviderId.value == newProviderId) return;

    _box.write('ai_provider_id', newProviderId);

    // ⚡ Architectural Fix: Load new provider's data AND clear volatile state
    _loadAiProviderDetails(newProviderId);
    isTestingAi.value = false;

    // NOW trigger reactive updates — form controller will read correct new values
    aiProviderId.value = newProviderId;

    talker.info('🤖 AI Provider switched to: $newProviderId');
  }

  bool saveAiSettings({
    required String apiKey,
    required String model,
    required String customUrl,
    required bool useCustomUrl,
    required bool toolsEnabled,
  }) {
    final provider = activeAiProvider;

    // 🛡️ Validation Layer
    if (provider.requiresApiKey && apiKey.trim().isEmpty) {
      _showSnackbar('error'.tr, 'api_key_required'.tr, isError: true);
      return false;
    }

    if (provider.requiresModel && model.trim().isEmpty) {
      _showSnackbar('error'.tr, 'model_required'.tr, isError: true);
      return false;
    }

    // Update Reactive State
    aiApiKey.value = apiKey.trim();
    aiModel.value = model.trim();
    aiCustomUrl.value = customUrl.trim();
    aiUseCustomUrl.value = useCustomUrl;
    aiToolsEnabled.value = toolsEnabled;

    // Persist to Storage with Provider-Specific Keys
    final typeName = provider.type.name;
    _box.write('${typeName}_api_key', aiApiKey.value);
    _box.write('${typeName}_model', aiModel.value);
    _box.write('${typeName}_custom_url', aiCustomUrl.value);
    _box.write('${typeName}_use_custom_url', aiUseCustomUrl.value);
    _box.write('${typeName}_tools_enabled', aiToolsEnabled.value);

    _showSnackbar('success'.tr, 'settings_saved_successfully'.tr);
    talker.info('💾 AI Settings Saved for $typeName');
    return true;
  }

  RxBool isTestingAi = false.obs;

  Future<void> testAiConnection({
    required String apiKey,
    required String model,
    required String customUrl,
    required bool useCustomUrl,
  }) async {
    final provider = activeAiProvider;

    // 🛑 Prevent Button Spam
    if (isTestingAi.value) return;

    // Quick validation
    if (provider.requiresApiKey && apiKey.trim().isEmpty) {
      _showSnackbar('error'.tr, 'api_key_required'.tr, isError: true);
      return;
    }

    final apiUrl = useCustomUrl && customUrl.trim().isNotEmpty
        ? customUrl.trim()
        : provider.defaultBaseUrl;

    // 🌐 Phase 1: Structural URL Validation (no DNS probing here)
    final baseUri = Uri.tryParse(apiUrl);
    if (baseUri == null ||
        !baseUri.hasScheme ||
        (baseUri.scheme != 'http' && baseUri.scheme != 'https') ||
        baseUri.host.isEmpty) {
      _showSnackbar('error'.tr, 'invalid_url'.tr, isError: true);
      return;
    }

    isTestingAi.value = true;
    _showSnackbar('info'.tr, 'testing_connection'.tr);
    talker.info(
      '🧪 Starting professional connection test for ${provider.type.name}...',
    );

    try {
      Map<String, String> headers = {'Content-Type': 'application/json'};
      Map<String, dynamic> body = {};
      late final Uri requestUri;
      final normalizedBase = _normalizeBaseUri(baseUri, provider.type);
      final resolvedModel = model.trim().isNotEmpty
          ? model.trim()
          : provider.defaultModel;

      // 🔌 Phase 3: Provider-Specific Endpoint Construction
      switch (provider.type) {
        case AiProviderType.openai:
          requestUri = _withPath(normalizedBase, '/v1/chat/completions');
          if (provider.requiresApiKey) {
            headers['Authorization'] = 'Bearer ${apiKey.trim()}';
          }
          body = {
            'model': resolvedModel,
            'messages': [
              {'role': 'user', 'content': 'hi'},
            ],
            'max_tokens': 1,
          };
          break;
        case AiProviderType.openrouter:
          requestUri = _withPath(normalizedBase, '/api/v1/chat/completions');
          headers['Authorization'] = 'Bearer ${apiKey.trim()}';
          body = {
            'model': resolvedModel,
            'messages': [
              {'role': 'user', 'content': 'hi'},
            ],
            'max_tokens': 1,
          };
          break;
        case AiProviderType.lmStudio:
          requestUri = _withPath(normalizedBase, '/v1/chat/completions');
          body = {
            'messages': [
              {'role': 'user', 'content': 'hi'},
            ],
            'max_tokens': 1,
          };
          if (resolvedModel.isNotEmpty) {
            body['model'] = resolvedModel;
          }
          break;

        case AiProviderType.gemini:
          String modelName = resolvedModel;
          if (modelName.startsWith('models/')) {
            modelName = modelName.replaceFirst('models/', '');
          }
          if (modelName.isEmpty) {
            modelName = 'gemini-1.5-flash';
          }
          requestUri = _withPath(
            normalizedBase,
            '/v1beta/models/$modelName:generateContent',
          ).replace(queryParameters: {'key': apiKey.trim()});
          body = {
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': 'hi'},
                ],
              },
            ],
            'generationConfig': {'maxOutputTokens': 1},
          };
          break;

        case AiProviderType.anthropic:
          requestUri = _withPath(normalizedBase, '/v1/messages');
          headers['x-api-key'] = apiKey.trim();
          headers['anthropic-version'] = '2023-06-01';
          body = {
            'model': resolvedModel.isNotEmpty
                ? resolvedModel
                : 'claude-3-haiku-20240307',
            'messages': [
              {'role': 'user', 'content': 'hi'},
            ],
            'max_tokens': 1,
          };
          break;

        case AiProviderType.ollama:
          requestUri = _withPath(normalizedBase, '/api/generate');
          body = {
            'model': resolvedModel.isNotEmpty ? resolvedModel : 'llama3',
            'prompt': 'hi',
            'stream': false,
          };
          break;
      }

      talker.info('📡 Dispatching request to: $requestUri');

      // ⏱️ Phase 4: Secure Request Execution
      final response = await http
          .post(requestUri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      // ✅ Phase 5: Response Interpretation
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showSnackbar('success'.tr, 'connection_successful'.tr);
        talker.info('✅ AI Connection Test Passed: ${provider.type.name}');
      } else {
        String errorMsg = 'HTTP ${response.statusCode}';
        try {
          final errorJson = jsonDecode(response.body);
          errorMsg =
              errorJson['error']?['message'] ??
              errorJson['message'] ??
              errorMsg;
        } catch (_) {}

        _showSnackbar('error'.tr, errorMsg, isError: true);
        talker.error(
          '🔴 AI Test Failed [${response.statusCode}]: ${response.body}',
        );
      }
    } on SocketException catch (e) {
      talker.error('🔴 Socket Error (DNS/Offline): $e');
      _showSnackbar('error'.tr, 'network_error'.tr, isError: true);
    } on TimeoutException catch (e) {
      talker.error('🔴 Timeout Error: $e');
      _showSnackbar('error'.tr, 'timeout_error'.tr, isError: true);
    } on FormatException catch (e) {
      talker.error('🔴 JSON/URL Format Error: $e');
      _showSnackbar('error'.tr, 'Invalid format', isError: true);
    } on http.ClientException catch (e) {
      talker.error('🔴 HTTP Client Exception: $e');
      _showSnackbar('error'.tr, 'Connection failed', isError: true);
    } catch (e) {
      talker.error('🔴 Unhandled Connection Error: $e');
      _showSnackbar('error'.tr, 'error'.tr, isError: true);
    } finally {
      isTestingAi.value = false;
    }
  }

  Uri _normalizeBaseUri(Uri rawUri, AiProviderType type) {
    final path = rawUri.path.toLowerCase();
    switch (type) {
      case AiProviderType.openai:
      case AiProviderType.lmStudio:
        if (path.endsWith('/chat/completions')) {
          return rawUri.replace(path: '/v1');
        }
        if (path.endsWith('/v1')) {
          return rawUri.replace(path: '/v1');
        }
        return rawUri.replace(path: '');
      case AiProviderType.openrouter:
        if (path.endsWith('/chat/completions')) {
          return rawUri.replace(path: '/api/v1');
        }
        if (path.endsWith('/api/v1')) {
          return rawUri.replace(path: '/api/v1');
        }
        return rawUri.replace(path: '');
      case AiProviderType.gemini:
        return rawUri.replace(path: '');
      case AiProviderType.anthropic:
        if (path.endsWith('/messages')) {
          return rawUri.replace(path: '/v1');
        }
        if (path.endsWith('/v1')) {
          return rawUri.replace(path: '/v1');
        }
        return rawUri.replace(path: '');
      case AiProviderType.ollama:
        if (path.endsWith('/api/generate') || path.endsWith('/api/chat')) {
          return rawUri.replace(path: '');
        }
        return rawUri.replace(path: '');
    }
  }

  Uri _withPath(Uri baseUri, String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return baseUri.replace(path: normalizedPath);
  }

  /// ✅ Expert Discovery: Automatically finds and selects the best model for the user
  Future<void> discoverGeminiModels(String apiKey) async {
    if (apiKey.trim().isEmpty) {
      _showSnackbar('error'.tr, 'api_key_required'.tr, isError: true);
      return;
    }

    if (isTestingAi.value) return;
    isTestingAi.value = true;

    _showSnackbar('info'.tr, 'discovering_models'.tr);
    talker.info('🔍 Starting AI Model Discovery...');

    try {
      final models = await ExternalAiClient.listAvailableModels(
        config: activeAiProvider,
        apiKey: apiKey.trim(),
      );

      if (models.isEmpty) {
        _showSnackbar('error'.tr, 'no_models_found'.tr, isError: true);
        return;
      }

      // Logic: Prefer 2.0 Pro -> 2.0 Flash -> 1.5 Pro -> 1.5 Flash
      String? bestModel;
      final priorities = [
        'gemini-2.0-pro',
        'gemini-2.0-flash',
        'gemini-1.5-pro',
        'gemini-1.5-flash',
      ];

      for (var p in priorities) {
        if (models.any((m) => m.contains(p))) {
          bestModel = models.firstWhere((m) => m.contains(p));
          break;
        }
      }

      bestModel ??= models.first; // Fallback to first available

      aiModel.value = bestModel;
      _showSnackbar(
        'success'.tr,
        'model_discovered'.trParams({'model': bestModel}),
      );
      talker.info('✅ Auto-Selected Best Model: $bestModel');
    } catch (e) {
      talker.error('🔴 Model Discovery Failed: $e');
      _showSnackbar('error'.tr, 'discovery_failed'.tr, isError: true);
    } finally {
      isTestingAi.value = false;
    }
  }

  /// ✅ Notification Stability Check: Verifies and requests necessary background permissions
  Future<void> checkNotificationStability({bool silent = false}) async {
    if (GetPlatform.isAndroid) {
      final ns.NotificationService notificationService =
          Get.find<ns.NotificationService>();

      if (!silent) {
        _showSnackbar(
          'security'.tr,
          'system_auth_required'.tr,
        ); // Changed to system_auth_required for professional feel
      }

      // 1. Request/Verify Permissions
      await notificationService.requestBatteryExemption();
      await notificationService.checkExactAlarmPermission();
      final isStable = await notificationService.isSystemStable();

      // 2. Update Status Reactive UI
      notificationStatus.value = isStable ? 'amazing' : 'pending';

      if (!silent) {
        if (isStable) {
          _showSnackbar(
            'success'.tr,
            '${'notification_stability'.tr}: ${'amazing'.tr}',
          );
          // 3. Fire Test Signal to prove it works
          await Future.delayed(const Duration(milliseconds: 500));
          await notificationService.sendTestNotification();
        } else {
          _showSnackbar(
            'warning'.tr,
            '${'notification_stability'.tr}: ${'pending'.tr}',
          );
        }
      }
    } else {
      if (!silent) {
        _showSnackbar('security'.tr, 'system_auth_required'.tr);
      }
    }
  }

  // --- Helpers with Pro Translation Logic ---

  void _showOptionsSheet({
    required List<String> options,
    required RxString current,
    required void Function(String) onSelected,
    TextStyle Function(String)?
    textStyleBuilder, // ✅ Added for dynamic previews
  }) {
    BottomSheetHelper.showSafeBottomSheet(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Wrap(
            children: options.map((option) {
              return Obx(
                () => ListTile(
                  title: Text(
                    option.tr,
                    style:
                        (textStyleBuilder?.call(option) ??
                                const TextStyle(fontSize: 16))
                            .copyWith(
                              fontWeight: current.value == option
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                  ),
                  trailing: current.value == option
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                  onTap: () {
                    onSelected(option);
                    Get.back();
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showFontSheet() {
    BottomSheetHelper.showSafeBottomSheet(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Wrap(
            children: fontOptions.map((font) {
              return Obx(
                () => ListTile(
                  title: Text(
                    font,
                    style: GoogleFonts.getFont(
                      font,
                      fontWeight: fontType.value == font
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: fontType.value == font
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                  onTap: () {
                    fontType.value = font;
                    _themeService.switchFont(font);
                    Get.back();
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> createBackup() async {
    try {
      await BackupService().createBackup();
      _showSnackbar('success'.tr, 'data_exported_successfully'.tr);
    } catch (e) {
      talker.error('Error creating backup: $e');
      _showSnackbar('error'.tr, 'failed_to_export_data'.tr, isError: true);
    }
  }

  Future<void> restoreBackup() async {
    try {
      await BackupService().restoreBackup();
      _showSnackbar('success'.tr, 'data_imported_successfully'.tr);
      // ✅ Phase 3: Force Re-initialization of core data so UI reflects backup changes instantly
      talker.info('🔄 Restarting UI Stack to reflect restored Backup...');
      await Future.delayed(const Duration(milliseconds: 800));
      Get.offAllNamed(
        '/home',
      ); // Routing to home wipes the nav stack and forces fresh OnInit logic
    } catch (e) {
      talker.error('Error restoring backup: $e');
      _showSnackbar('error'.tr, 'failed_to_import_data'.tr, isError: true);
    }
  }

  void _showSnackbar(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: isError ? SnackPosition.BOTTOM : SnackPosition.TOP,
      backgroundColor: (isError ? Colors.redAccent : Colors.green).withValues(
        alpha: 0.1,
      ),
      colorText: isError ? Colors.redAccent : Colors.green,
      duration: const Duration(seconds: 2),
    );
  }
}
