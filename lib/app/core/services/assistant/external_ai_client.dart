import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import '../../../core/helpers/log_helper.dart';
import 'ai_client_manager.dart';
import 'ai_client.dart';
import 'assistant_response.dart';
import 'ai_provider_config.dart';
import 'ai_health_tracker.dart';
import 'command_executor.dart';
import 'query_engine.dart';
import 'message_model.dart';


class ExternalAiClient implements AiClient {
  final AiProviderConfig config;
  final String apiKey;
  final String model;
  final String customBaseUrl;
  final bool toolsEnabled;
  final Duration timeout;

  ExternalAiClient({
    required this.config,
    required this.apiKey,
    required this.model,
    required this.customBaseUrl,
    required this.toolsEnabled,
    this.timeout = const Duration(seconds: 25),
  });

  // ─── Tool Definitions (JSON Schema) ────────────────
  
  static List<Map<String, dynamic>> get _toolDefinitions => [
    {
      'name': 'query_tasks',
      'description': 'Get a summary of today tasks, active and completed.',
      'parameters': {'type': 'object', 'properties': {}}
    },
    {
      'name': 'query_next_task',
      'description': 'Get the most urgent upcoming task.',
      'parameters': {'type': 'object', 'properties': {}}
    },
    {
      'name': 'create_task',
      'description': 'Create a new task in the app.',
      'parameters': {
        'type': 'object',
        'properties': {
          'title': {'type': 'string', 'description': 'The task title.'},
          'description': {'type': 'string', 'description': 'Optional note or details.'},
          'priority': {'type': 'integer', 'description': '1: Low, 2: Medium, 3: High'},
        },
        'required': ['title']
      }
    },
    {
      'name': 'query_appointments',
      'description': 'Get all upcoming doctor appointments.',
      'parameters': {'type': 'object', 'properties': {}}
    },
    {
      'name': 'query_medications',
      'description': 'Check active medications and today compliance.',
      'parameters': {'type': 'object', 'properties': {}}
    },
    {
      'name': 'query_overview',
      'description': 'Get a full overview of today (tasks, meds, and appointments).',
      'parameters': {'type': 'object', 'properties': {}}
    },
  ];

  static Future<List<String>> listAvailableModels({
    required AiProviderConfig config,
    required String apiKey,
  }) async {
    if (config.type != AiProviderType.gemini) return [];

    final manager = Get.find<AiClientManager>();
    try {
      final res = await manager.getWithRetry(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models'),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        timeout: const Duration(seconds: 10),
      );

      if (res.isSuccess) {
        final data = jsonDecode(res.data!.body);
        final List models = data['models'] ?? [];
        return models
            .where((m) => m['supportedGenerationMethods'].contains('generateContent'))
            .map<String>((m) => m['name'].toString().replaceFirst('models/', ''))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<AssistantResponse> process(List<Message> history, {String? systemContext, String? correlationId}) async {
    // 🛡️ Reliability Check: Prevent calling degraded providers
    if (!AiHealthTracker.isHealthy(config.type.name, model)) {
      final cooldown = AiHealthTracker.getRemainingCooldown(config.type.name, model);
      talker.warning('⚠️ AI Client [$correlationId]: Provider ${config.type.name} is degraded. Cooldown active.');
      return AssistantResponse.error(
        'provider_degraded'.trParams({
          'provider': config.displayName,
          'retry': '${cooldown?.inSeconds ?? 60}s'
        })
      );
    }

    try {
      final baseUrl = customBaseUrl.isNotEmpty ? customBaseUrl : config.defaultBaseUrl;
      final uri = Uri.parse(baseUrl);

      talker.info('📡 AI Client [$correlationId]: Dispatching to ${config.type.name} ($baseUrl)');

      switch (config.type) {
        case AiProviderType.openai:
        case AiProviderType.openrouter:
        case AiProviderType.lmStudio:
          final openaiUri = _buildFinalUri(uri, config.type);
          return await _processOpenAIFormat(openaiUri, history, systemContext);
        
        case AiProviderType.gemini:
          // Gemini handles its own URI construction in its format processor
          return await _processGeminiFormat(uri, history, systemContext);
        
        case AiProviderType.anthropic:
          final anthropicUri = _buildFinalUri(uri, config.type);
          return await _processAnthropicFormat(anthropicUri, history, systemContext);
          
        case AiProviderType.ollama:
          final ollamaUri = _buildFinalUri(uri, config.type);
          return await _processOllamaFormat(ollamaUri, history, systemContext);
      }
    } on TimeoutException catch (e, stack) {
      talker.handle(e, stack, '🔴 External AI Client Timeout (${config.type.name})');
      
      final baseUrl = customBaseUrl.isNotEmpty ? customBaseUrl : config.defaultBaseUrl;
      if (baseUrl.contains('10.0.2.2') || baseUrl.contains('localhost')) {
        return AssistantResponse.error(
          'فشل الاتصال بالسيرفر المحلي (Timeout). إذا كنت تستخدم جهازاً حقيقياً، يرجى تغيير 10.0.2.2 إلى عنوان الـ IP الخاص بالكمبيوتر في الشبكة المحلية (مثل 192.168.1.x).'
        );
      }
      return AssistantResponse.error('⏳ انتهى وقت الطلب (Timeout). تأكد من جودة اتصالك بالإنترنت أو حالة السيرفر.');
    } on SocketException catch (e, stack) {
      talker.handle(e, stack, '🔴 External AI Client Socket Error (${config.type.name})');
      return AssistantResponse.error('🌐 خطأ في الشبكة (SocketException). تأكد من اتصالك بالإنترنت أو من صحة رابط الـ API.');
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 External AI Client Error (${config.type.name})');
      return AssistantResponse.error('⚠️ خطأ غير متوقع: $e');
    }
  }

  // --- Adapters ---

  Future<AssistantResponse> _processOpenAIFormat(Uri uri, List<Message> history, String? systemContext) async {
    // 🛡️ Principal Architect Guard
    String modelName = model.trim();
    if (modelName.isEmpty || modelName.length < 3) {
      modelName = config.defaultModel.isNotEmpty ? config.defaultModel : 'gpt-4o';
    }

    final headers = {
      'Content-Type': 'application/json',
      if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
    };

    // 🛡️ Reasoning Model Detector (New 2026 Standard)
    final isReasoningModel = modelName.startsWith('o1') || modelName.startsWith('o3') || modelName.contains('reasoning');

    final List<Map<String, dynamic>> messages = [
      {
        'role': isReasoningModel ? 'developer' : 'system',
        'content': '${systemContext ?? ''}\n'
                  'You are a professional Life OS Assistant. Help the user manage tasks, notes, and productivity. '
                  'Be concise and support both Arabic and English.',
      },
      ...history.map((m) => {
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      }),
    ];

    final body = {
      'model': modelName,
      'messages': messages,
      if (toolsEnabled && !isReasoningModel) 'tools': _toolDefinitions.map((t) => {'type': 'function', 'function': t}).toList(),
      if (!isReasoningModel) 'temperature': 0.7,
      if (isReasoningModel) 'max_completion_tokens': 2048 else 'max_tokens': 1024,
    };

    final manager = Get.find<AiClientManager>();
    try {
      final res = await manager.postWithRetry(
        uri,
        headers: headers,
        body: jsonEncode(body),
        timeout: timeout,
      );

      if (res.isSuccess) {
        final json = jsonDecode(res.data!.body);
        final choice = json['choices'][0]['message'];
        
        // Handle Tool Calls (OpenAI Format)
        if (choice['tool_calls'] != null && (choice['tool_calls'] as List).isNotEmpty) {
           return await _handleOpenAiToolCalls(uri, choice['tool_calls']);
        }

        if (choice['content'] != null) {
          return AssistantResponse.text((choice['content'] as String).trim());
        }
        return AssistantResponse.error('🤖 OpenAI returned an empty response.');
      } else {
        return AssistantResponse.error(res.error ?? 'Unknown error');
      }
    } catch (e) {
      return AssistantResponse.error('⚠️ OpenAI Error: $e');
    }

  }

  Future<AssistantResponse> _handleOpenAiToolCalls(Uri uri, List toolCalls) async {
    final executor = Get.find<CommandExecutor>();
    final queryEngine = Get.find<QueryEngine>();
    
    final List<Map<String, dynamic>> messages = [
      {
        'role': 'system',
        'content': 'Execute tools and provide a natural summary for the user.',
      }
    ];

    final List<ResponseCard> accumulatedCards = [];
    ResponseType finalType = ResponseType.text;

    for (var call in toolCalls) {
      final function = call['function'];
      final name = function['name'];
      final args = jsonDecode(function['arguments']);
      
      talker.info('🛠️ AI calling tool: $name with $args');
      
      String resultText;
      try {
        final res = await _dispatchTool(name, args, executor, queryEngine);
        resultText = res.text;
        
        // 🛡️ HOTFIX: Preserve the graphical cards generated by the tool!
        if (res.cards.isNotEmpty) {
          accumulatedCards.addAll(res.cards);
          finalType = res.type; // Inherit the type of the last tool called
        }
      } catch (e) {
        resultText = 'Error executing tool: $e';
      }

      messages.add({
        'tool_call_id': call['id'],
        'role': 'tool',
        'name': name,
        'content': resultText,
      });
    }

    // Call OpenAI again with the results
    final body = {
      'model': model,
      'messages': messages,
    };

    final manager = Get.find<AiClientManager>();
    try {
      final res = await manager.postWithRetry(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(body),
        timeout: timeout,
      );

      if (res.isSuccess) {
        final json = jsonDecode(res.data!.body);
        final content = json['choices'][0]['message']['content'].toString().trim();
        
        // 🛡️ HOTFIX: Attach accumulated cards to the AI's final text response
        if (accumulatedCards.isNotEmpty) {
          return AssistantResponse.withCards(
            text: content,
            type: finalType,
            cards: accumulatedCards,
          );
        }
        
        return AssistantResponse.text(content);
      }
      return AssistantResponse.error(res.error ?? 'Failed to resolve tools');
    } catch (e) {
      return AssistantResponse.error('Tool resolution error: $e');
    }
  }

  Future<AssistantResponse> _processGeminiFormat(Uri baseUri, List<Message> history, String? systemContext) async {
    // 🛡️ Principal Architect Guard: Validate model name to prevent malformed endpoints
    String modelName = model.trim();
    if (modelName.length < 3) {
      talker.warning('⚠️ Invalid model name "$modelName" detected for Gemini. Falling back to default.');
      modelName = config.defaultModel.isNotEmpty ? config.defaultModel : 'gemini-1.5-pro';
    }

    // Ensure baseUri ends with a slash and construct the final generation endpoint
    String base = baseUri.toString();
    if (!base.endsWith('/')) base += '/';
    
    // 🛡️ Principal Architect Fix: Handle potential 'models/' prefix and ensure model name is valid
    if (modelName.startsWith('models/')) {
      modelName = modelName.replaceFirst('models/', '');
    }
    if (modelName.isEmpty) modelName = 'gemini-1.5-flash';
    
    // 🛡️ Principal Architect Fix: Ensure correct v1beta path structure
    final uri = baseUri.replace(
      path: '/v1beta/models/$modelName:generateContent',
      queryParameters: {'key': apiKey},
    );

    final maskedKey = apiKey.length > 8 
        ? '${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}' 
        : '***';
    talker.info('🤖 Gemini Call ($maskedKey): ${uri.toString().split('?')[0]}');

    final headers = {
      'Content-Type': 'application/json',
      'x-goog-api-key': apiKey,
    };

    final body = {
      'contents': history.map((m) => {
        'role': m.isUser ? 'user' : 'model',
        'parts': [{'text': m.text}]
      }).toList(),
      'systemInstruction': {
        'parts': [
          {
            'text': '${systemContext ?? ''}\n'
                    'You are a professional Life OS Assistant. Help the user manage their tasks, notes, and health data. '
                    'Keep responses helpful, structured, and concise. Support both Arabic and English naturally.'
          }
        ]
      },
      if (toolsEnabled) 'tools': [{'function_declarations': _toolDefinitions}],
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 1024,
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
      ],
    };

    final manager = Get.find<AiClientManager>();
    try {
      final res = await manager.postWithRetry(
        uri,
        headers: headers,
        body: jsonEncode(body),
        timeout: timeout,
      );

      if (res.isSuccess) {
        final json = jsonDecode(res.data!.body);
        if (json['candidates'] != null && (json['candidates'] as List).isNotEmpty) {
          final candidate = json['candidates'][0];
          final parts = candidate['content']['parts'] as List;
          
          // Handle Gemini Tool Calls
          final toolCalls = parts.where((p) => p['functionCall'] != null).toList();
          if (toolCalls.isNotEmpty) {
            return await _handleGeminiToolCalls(uri, toolCalls);
          }

          final textPart = parts.firstWhere((p) => p['text'] != null, orElse: () => null);
          if (textPart != null) {
             return AssistantResponse.text(textPart['text'].toString().trim());
          }
        }
        return AssistantResponse.error('🤖 Gemini returned an empty response.');
      } else {
        final errorMsg = res.error ?? 'Unknown error';
        if (errorMsg.contains('429')) {
          AiHealthTracker.markDegraded(config.type.name, model, cooldown: const Duration(minutes: 2));
        } else if (errorMsg.contains('500')) {
          AiHealthTracker.markDegraded(config.type.name, model, cooldown: const Duration(seconds: 30));
        }
        return AssistantResponse.error(errorMsg);
      }
    } catch (e) {
      return AssistantResponse.error('⚠️ Gemini Error: $e');
    }
  }

  Future<AssistantResponse> _handleGeminiToolCalls(Uri uri, List toolCalls) async {
    final executor = Get.find<CommandExecutor>();
    final queryEngine = Get.find<QueryEngine>();
    
    final List<Map<String, dynamic>> responseParts = [];

    final List<ResponseCard> accumulatedCards = [];
    ResponseType finalType = ResponseType.text;

    for (var call in toolCalls) {
      final func = call['functionCall'];
      final name = func['name'];
      final args = func['args'] as Map<String, dynamic>;
      
      talker.info('🛠️ Gemini calling tool: $name with $args');
      
      String resultText;
      try {
        final res = await _dispatchTool(name, args, executor, queryEngine);
        resultText = res.text;
        
        // 🛡️ HOTFIX: Preserve the graphical cards generated by the tool!
        if (res.cards.isNotEmpty) {
          accumulatedCards.addAll(res.cards);
          finalType = res.type; // Inherit the type of the last tool called
        }
      } catch (e) {
        resultText = 'Error executing tool: $e';
      }

      responseParts.add({
        'functionResponse': {
          'name': name,
          'response': {'content': resultText}
        }
      });
    }

    // Return tool results to Gemini
    final body = {
      'contents': [
        {
          'role': 'function',
          'parts': responseParts,
        }
      ],
      'generationConfig': {'maxOutputTokens': 1024},
    };

    final manager = Get.find<AiClientManager>();
    try {
      final res = await manager.postWithRetry(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: jsonEncode(body),
        timeout: timeout,
      );

      if (res.isSuccess) {
        final json = jsonDecode(res.data!.body);
        final text = json['candidates'][0]['content']['parts'][0]['text'].toString().trim();
        
        // 🛡️ HOTFIX: Attach accumulated cards to the AI's final text response
        if (accumulatedCards.isNotEmpty) {
          return AssistantResponse.withCards(
            text: text,
            type: finalType,
            cards: accumulatedCards,
          );
        }
        
        return AssistantResponse.text(text);
      }
      return AssistantResponse.error(res.error ?? 'Failed to resolve Gemini tools');
    } catch (e) {
      return AssistantResponse.error('Tool resolution error: $e');
    }
  }

  // ─── Dispatcher ────────────────────────────────────

  Future<AssistantResponse> _dispatchTool(String name, Map<String, dynamic> args, CommandExecutor executor, QueryEngine queryEngine) async {
    switch (name) {
      case 'query_tasks':
        return await queryEngine.queryTasks();
      case 'query_next_task':
        return await queryEngine.queryNextTask();
      case 'create_task':
        return await executor.executeCreateTask(
          title: args['title'],
          description: args['description'],
          priority: args['priority'],
        );
      case 'query_appointments':
        return await queryEngine.queryAppointments();
      case 'query_medications':
        return await queryEngine.queryMedications();
      case 'query_overview':
        return await queryEngine.queryOverview();
      default:
        return AssistantResponse.error('Tool $name not implemented');
    }
  }

  Future<AssistantResponse> _processAnthropicFormat(Uri uri, List<Message> history, String? systemContext) async {
    final headers = {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    };

    final body = {
      'model': model.isNotEmpty ? model : 'claude-3-opus-20240229',
      'system': '${systemContext ?? ''}\n'
                'You are a professional Life OS Assistant. Help the user manage tasks, notes, and productivity. '
                'Be concise and support both Arabic and English.',
      'messages': history.map((m) => {
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      }).toList(),
      'max_tokens': 1024,
      'temperature': 0.7,
    };

    final manager = Get.find<AiClientManager>();
    try {
      final res = await manager.postWithRetry(
        uri,
        headers: headers,
        body: jsonEncode(body),
        timeout: timeout,
      );

      if (res.isSuccess) {
        final json = jsonDecode(res.data!.body);
        if (json['content'] != null && (json['content'] as List).isNotEmpty) {
          final content = json['content'][0]['text'] as String;
          return AssistantResponse.text(content.trim());
        }
        return AssistantResponse.error('🤖 Anthropic returned an empty response.');
      } else {
        final errorMsg = res.error ?? 'Unknown error';
        if (errorMsg.contains('429')) {
          AiHealthTracker.markDegraded(config.type.name, model, cooldown: const Duration(minutes: 2));
        } else if (errorMsg.contains('500')) {
          AiHealthTracker.markDegraded(config.type.name, model, cooldown: const Duration(seconds: 30));
        }
        return AssistantResponse.error(errorMsg);
      }
    } catch (e) {
      return AssistantResponse.error('⚠️ Anthropic Error: $e');
    }
  }

  Future<AssistantResponse> _processOllamaFormat(Uri uri, List<Message> history, String? systemContext) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    final body = {
      'model': model.isNotEmpty ? model : 'llama3',
      'messages': [
        {
          'role': 'system',
          'content': '${systemContext ?? ''}\n'
                    'You are a professional Life OS Assistant. Help the user manage tasks, notes, and productivity. '
                    'Be concise and support both Arabic and English.'
        },
        ...history.map((m) => {
          'role': m.isUser ? 'user' : 'assistant',
          'content': m.text,
        }),
      ],
      'stream': false,
    };

    final manager = Get.find<AiClientManager>();
    try {
      final res = await manager.postWithRetry(
        uri,
        headers: headers,
        body: jsonEncode(body),
        timeout: timeout,
      );

      if (res.isSuccess) {
        final json = jsonDecode(res.data!.body);
        if (json['message'] != null && json['message']['content'] != null) {
          return AssistantResponse.text((json['message']['content'] as String).trim());
        }
        return AssistantResponse.text(res.data!.body);
      } else {
        return AssistantResponse.error(res.error ?? 'Unknown error');
      }
    } catch (e) {
      return AssistantResponse.error('⚠️ Ollama Error: $e');
    }
  }
  Uri _buildFinalUri(Uri baseUri, AiProviderType type) {
    String path = baseUri.path;
    if (path.endsWith('/')) path = path.substring(0, path.length - 1);

    switch (type) {
      case AiProviderType.openai:
      case AiProviderType.lmStudio:
        if (!path.endsWith('/chat/completions')) {
          final suffix = path.endsWith('/v1') ? '/chat/completions' : '/v1/chat/completions';
          return baseUri.replace(path: '$path$suffix');
        }
        break;
      case AiProviderType.openrouter:
        if (!path.endsWith('/chat/completions')) {
          final suffix = path.endsWith('/api/v1') ? '/chat/completions' : '/api/v1/chat/completions';
          return baseUri.replace(path: '$path$suffix');
        }
        break;
      case AiProviderType.anthropic:
        if (!path.endsWith('/messages')) {
          final suffix = path.endsWith('/v1') ? '/messages' : '/v1/messages';
          return baseUri.replace(path: '$path$suffix');
        }
        break;
      case AiProviderType.ollama:
        if (!path.endsWith('/api/chat') && !path.endsWith('/api/generate')) {
          return baseUri.replace(path: '$path/api/chat');
        }
        break;
      default:
        break;
    }
    return baseUri;
  }
}
