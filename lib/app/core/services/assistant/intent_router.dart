import 'package:get_storage/get_storage.dart';

import '../../../core/helpers/log_helper.dart';
import 'ai_client.dart';
import 'assistant_response.dart';
import 'local_ai_client.dart';
import 'url_ai_client.dart';

/// Routes between Local and URL AI clients based on user settings.
class IntentRouter {
  final LocalAiClient _localClient;
  final GetStorage _storage = GetStorage();

  IntentRouter({required LocalAiClient localClient})
      : _localClient = localClient;

  /// The currently active AI mode: 'local' or 'url'
  String get activeMode => _storage.read<String>('ai_mode') ?? 'local';

  /// The saved custom URL endpoint
  String get savedUrl => _storage.read<String>('ai_endpoint_url') ?? '';

  /// Get the active AI client based on settings
  AiClient get _activeClient {
    if (activeMode == 'url' && savedUrl.isNotEmpty) {
      return UrlAiClient(baseUrl: savedUrl);
    }
    return _localClient;
  }

  /// Process a user message through the active AI client
  Future<AssistantResponse> process(String message) async {
    talker.info('🤖 IntentRouter: Processing via $activeMode mode');
    return _activeClient.process(message);
  }
}
