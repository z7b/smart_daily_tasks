import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
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
  Future<AssistantResponse> process(List<Message> history, {String? systemContext}) async {
    // 🛡️ Reliability Check: Prevent calling degraded providers
    if (!AiHealthTracker.isHealthy(config.type.name, model)) {
      final cooldown = AiHealthTracker.getRemainingCooldown(config.type.name, model);
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

      switch (config.type) {
        case AiProviderType.openai:
        case AiProviderType.openrouter:
        case AiProviderType.lmStudio:
          return await _processOpenAIFormat(uri, history, systemContext);
        
        case AiProviderType.gemini:
          return await _processGeminiFormat(uri, history, systemContext);
        
        case AiProviderType.anthropic:
          return await _processAnthropicFormat(uri, history, systemContext);
          
        case AiProviderType.ollama:
          return await _processOllamaFormat(uri, history, systemContext);
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
       rethrow;
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

    for (var call in toolCalls) {
      final function = call['function'];
      final name = function['name'];
      final args = jsonDecode(function['arguments']);
      
      talker.info('🛠️ AI calling tool: $name with $args');
      
      String resultText;
      try {
        final res = await _dispatchTool(name, args, executor, queryEngine);
        resultText = res.text;
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
        return AssistantResponse.text(json['choices'][0]['message']['content'].toString().trim());
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
    
    // Some users might include 'models/' in the model name field, handle that
    String finalModelName = modelName;
    if (finalModelName.startsWith('models/')) {
      finalModelName = finalModelName.replaceFirst('models/', '');
    }
    
    final String urlStr = '$base$finalModelName:generateContent';
    final uri = Uri.parse(urlStr);

    final maskedKey = apiKey.length > 8 
        ? '${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}' 
        : '***';
    talker.info('🤖 Gemini Call ($maskedKey): $urlStr');

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
        if (res.error!.contains('429')) {
          AiHealthTracker.markDegraded(config.type.name, model, cooldown: const Duration(minutes: 2));
        } else if (res.error!.contains('500')) {
          AiHealthTracker.markDegraded(config.type.name, model, cooldown: const Duration(seconds: 30));
        }
        return AssistantResponse.error(res.error ?? 'Unknown error');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<AssistantResponse> _handleGeminiToolCalls(Uri uri, List toolCalls) async {
    final executor = Get.find<CommandExecutor>();
    final queryEngine = Get.find<QueryEngine>();
    
    final List<Map<String, dynamic>> responseParts = [];

    for (var call in toolCalls) {
      final func = call['functionCall'];
      final name = func['name'];
      final args = func['args'] as Map<String, dynamic>;
      
      talker.info('🛠️ Gemini calling tool: $name with $args');
      
      String resultText;
      try {
        final res = await _dispatchTool(name, args, executor, queryEngine);
        resultText = res.text;
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
        final text = json['candidates'][0]['content']['parts'][0]['text'];
        return AssistantResponse.text(text.toString().trim());
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
        throw 'Tool $name not implemented';
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
        if (res.error!.contains('429')) {
          AiHealthTracker.markDegraded(config.type.name, model, cooldown: const Duration(minutes: 2));
        } else if (res.error!.contains('500')) {
          AiHealthTracker.markDegraded(config.type.name, model, cooldown: const Duration(seconds: 30));
        }
        return AssistantResponse.error(res.error ?? 'Unknown error');
      }
    } catch (e) {
      rethrow;
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
      rethrow;
    }
  }
}
