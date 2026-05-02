import 'dart:convert';
import 'dart:async';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'ai_client_manager.dart';
import 'ai_provider_config.dart';
import 'package:smart_daily_tasks/app/modules/settings/controllers/settings_controller.dart';
import 'package:smart_daily_tasks/app/core/helpers/log_helper.dart';
import 'package:smart_daily_tasks/app/data/models/attendance_log_model.dart';
import 'package:smart_daily_tasks/app/data/models/task_model.dart';

/// 🤖 AI Backend Service (2026 Agentic Protocol)
/// 
/// This service acts as the Brain of the application, implementing the Agentic Loop,
/// Tool Calling (Functions), and Structured Outputs using JSON Schema.
class AiBackendService extends GetxService {
  final Isar isar;
  final SettingsController _settings = Get.find<SettingsController>();
  final AiClientManager _clientManager = Get.find<AiClientManager>();

  // 🛡️ M1 Fix: Processing lock to prevent concurrent command corruption
  Completer<void>? _processingLock;

  AiBackendService({required this.isar});

  /// 🚀 Main Agentic Loop Entry Point
  Future<String> processUserCommand(String prompt) async {
    // 🛡️ M1: Serialize concurrent requests — wait for any in-flight command
    while (_processingLock != null) {
      await _processingLock!.future;
    }
    _processingLock = Completer<void>();

    talker.info('🧠 AI Backend: Processing Agentic Loop for prompt: "$prompt"');

    try {
      // 1. Prepare Tools Definition (2026 JSON Schema Standard)
      final List<Map<String, dynamic>> tools = _defineTools();

      // 2. Build Context Bridging (Minimalist Context)
      final context = await _buildMinimalContext();

      // 3. Dispatch to AI with Structured Output Requirement
      // Using 2026 "Responses API" style logic via our hardened Manager
      final result = await _dispatchAgenticCall(prompt, context, tools);

      return result;
    } catch (e, stack) {
      talker.handle(e, stack, '🔥 AI Backend Loop Failed');
      return 'عذراً، واجهت مشكلة في معالجة طلبك حالياً.';
    } finally {
      // 🛡️ M1: Always release the lock
      _processingLock?.complete();
      _processingLock = null;
    }
  }

  /// 🛠️ Define available tools for the Agent
  List<Map<String, dynamic>> _defineTools() {
    return [
      {
        'type': 'function',
        'function': {
          'name': 'log_attendance',
          'description': 'تسجيل حالة الحضور اليومية للمستخدم في قاعدة البيانات.',
          'parameters': {
            'type': 'object',
            'properties': {
              'status': {
                'type': 'string',
                'enum': ['present', 'absent', 'sick', 'leave'],
                'description': 'حالة الحضور'
              },
              'note': {'type': 'string', 'description': 'ملاحظة إضافية'}
            },
            'required': ['status']
          }
        }
      },
      {
        'type': 'function',
        'function': {
          'name': 'analyze_weekly_performance',
          'description': 'تحليل أداء المستخدم الأسبوعي بناءً على المهام المنجزة.',
          'parameters': {
            'type': 'object',
            'properties': {
              'week_start': {'type': 'string', 'format': 'date'}
            }
          }
        }
      }
    ];
  }

  /// ⚡ Dispatch Agentic Call (Handles Tool Execution Loop)
  Future<String> _dispatchAgenticCall(String userPrompt, Map<String, dynamic> context, List<Map<String, dynamic>> tools) async {
    final provider = _settings.activeAiProvider;
    final isGeminiNative = provider.type == AiProviderType.gemini && !_settings.aiUseCustomUrl.value;
    final correlationId = 'ai-loop-${DateTime.now().millisecondsSinceEpoch}';
    
    final url = _settings.aiUseCustomUrl.value 
        ? Uri.parse(_settings.aiCustomUrl.value) 
        : Uri.parse(provider.defaultBaseUrl);

    int loopCount = 0;
    const maxLoops = 3;
    final stopWatch = Stopwatch()..start();
    
    talker.info('📡 AI Link [$correlationId]: Starting Agentic Loop (Provider: ${provider.type.name})');

    // Initial State
    List<Map<String, dynamic>> history = [];
    String systemMessage = 'You are a minimalist Life OS assistant. Current Context: ${jsonEncode(context)}. Answer in ${Get.locale?.languageCode == 'ar' ? 'Arabic' : 'English'}. BE EXTREMELY CONCISE.';

    if (isGeminiNative) {
      // Gemini system instruction is handled separately
      history.add({'role': 'user', 'parts': [{'text': userPrompt}]});
    } else {
      // Only add system message once at the very top
      history.add({'role': 'system', 'content': systemMessage});
      history.add({'role': 'user', 'content': userPrompt});
    }
    
    while (loopCount < maxLoops) {
      loopCount++;
      
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'X-Correlation-ID': correlationId,
        'X-Client-Version': '2026.1.0-LifeOS',
      };
      Map<String, dynamic> requestBody = {};
      Uri finalUri = url;

      if (isGeminiNative) {
        final model = _settings.aiModel.value.isEmpty ? 'gemini-1.5-flash' : _settings.aiModel.value;
        // Ensure path starts correctly
        finalUri = url.replace(path: '/v1beta/models/$model:generateContent', queryParameters: {'key': _settings.aiApiKey.value});
        
        requestBody = {
          'contents': history,
          'system_instruction': {'parts': [{'text': systemMessage}]},
          'tools': [{'function_declarations': tools.map((t) => t['function']).toList()}],
          'generationConfig': {'response_mime_type': 'application/json'}
        };
      } else {
        final urlStr = _settings.aiUseCustomUrl.value && _settings.aiCustomUrl.value.isNotEmpty 
            ? _settings.aiCustomUrl.value.trim() 
            : provider.defaultBaseUrl;
        
        Uri rawUri = Uri.tryParse(urlStr) ?? Uri.parse(provider.defaultBaseUrl);
        String path = rawUri.path;
        if (path.endsWith('/')) {
          path = path.substring(0, path.length - 1);
          rawUri = rawUri.replace(path: path);
        }

        headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_settings.aiApiKey.value}',
        };

        // 🛡️ Always append the correct endpoint path if it's missing
        switch (provider.type) {
          case AiProviderType.openai:
          case AiProviderType.lmStudio:
            if (!path.endsWith('/chat/completions')) {
              final suffix = path.endsWith('/v1') ? '/chat/completions' : '/v1/chat/completions';
              finalUri = rawUri.replace(path: '$path$suffix');
            } else {
              finalUri = rawUri;
            }
            break;
          case AiProviderType.openrouter:
            if (!path.endsWith('/chat/completions')) {
              final suffix = path.endsWith('/api/v1') ? '/chat/completions' : '/api/v1/chat/completions';
              finalUri = rawUri.replace(path: '$path$suffix');
            } else {
              finalUri = rawUri;
            }
            break;
          case AiProviderType.anthropic:
            if (!path.endsWith('/messages')) {
              final suffix = path.endsWith('/v1') ? '/messages' : '/v1/messages';
              finalUri = rawUri.replace(path: '$path$suffix');
            } else {
              finalUri = rawUri;
            }
            headers['x-api-key'] = _settings.aiApiKey.value;
            headers['anthropic-version'] = '2023-06-01';
            headers.remove('Authorization'); 
            break;
          case AiProviderType.ollama:
            if (!path.endsWith('/api/chat') && !path.endsWith('/api/generate')) {
              finalUri = rawUri.replace(path: '$path/api/chat');
            } else {
              finalUri = rawUri;
            }
            break;
          default:
            finalUri = rawUri;
            break;
        }

        // 🛡️ C5 Fix: Provider-specific request body construction
        switch (provider.type) {
          case AiProviderType.anthropic:
            // Anthropic uses its own tool format and doesn't support response_format
            final anthropicTools = tools.map((t) {
              final fn = t['function'] as Map<String, dynamic>;
              return <String, dynamic>{
                'name': fn['name'],
                'description': fn['description'],
                'input_schema': fn['parameters'],
              };
            }).toList();
            // Extract system message from history (Anthropic uses top-level 'system')
            final userMessages = history.where((m) => m['role'] != 'system').toList();
            requestBody = {
              'model': _settings.aiModel.value,
              'system': systemMessage,
              'messages': userMessages,
              'tools': anthropicTools,
              'max_tokens': 4096,
            };
            break;
          case AiProviderType.ollama:
            // Ollama doesn't support tools, tool_choice, or response_format
            requestBody = {
              'model': _settings.aiModel.value,
              'messages': history,
              'stream': false,
            };
            break;
          default:
            // OpenAI, OpenRouter, LM Studio — standard OpenAI format
            requestBody = {
              'model': _settings.aiModel.value,
              'messages': history,
              'tools': tools,
              'tool_choice': 'auto',
              'response_format': {'type': 'json_object'},
            };
            break;
        }
      }

      talker.debug('📤 AI Link [$correlationId]: Dispatching request (Loop $loopCount)');
      final stepWatch = Stopwatch()..start();
      
      if (requestBody.toString().length > 100000) {
        throw Exception('Payload size too large for safe transmission.');
      }

      final res = await _clientManager.postWithRetry(
        finalUri,
        headers: headers,
        body: jsonEncode(requestBody),
        timeout: const Duration(seconds: 25),
      );

      stepWatch.stop();
      if (res.isFailure) {
        talker.error('🔴 AI Link [$correlationId]: Step failed in ${stepWatch.elapsedMilliseconds}ms: ${res.error}');
        throw Exception(res.error);
      }

      talker.info('📥 AI Link [$correlationId]: Response received in ${stepWatch.elapsedMilliseconds}ms');

      final data = await _clientManager.parseJsonSafe(res.data!.body);
      
      if (isGeminiNative) {
        if (data['candidates'] == null || (data['candidates'] as List).isEmpty) {
          throw Exception('Gemini returned no candidates. Safety block or API error.');
        }
        
        final candidate = data['candidates'][0];
        final message = candidate['content'];
        final parts = message['parts'] as List;
        
        // Check for Tool Calls (Function Calls)
        final toolCalls = parts.where((p) => p['functionCall'] != null).toList();
        if (toolCalls.isNotEmpty) {
          history.add(message);
          
          for (var call in toolCalls) {
            final functionCall = call['functionCall'];
            final toolResult = await _executeTool(functionCall['name'], functionCall['args']);
            
            history.add({
              'role': 'function',
              'parts': [{
                'functionResponse': {
                  'name': functionCall['name'],
                  'response': toolResult
                }
              }]
            });
          }
          continue;
        }
        stopWatch.stop();
        talker.info('✅ AI Link [$correlationId]: Loop completed in ${stopWatch.elapsed.inSeconds}s');
        return parts.firstWhere((p) => p['text'] != null)['text'] ?? '';
      } else if (provider.type == AiProviderType.anthropic) {
        // 🛡️ Anthropic Response Parsing (uses content blocks, not choices)
        final contentBlocks = data['content'] as List?;
        if (contentBlocks == null || contentBlocks.isEmpty) {
          throw Exception('Anthropic returned no content blocks.');
        }

        // Check for tool_use blocks
        final toolUseBlocks = contentBlocks.where((b) => b['type'] == 'tool_use').toList();
        if (toolUseBlocks.isNotEmpty) {
          // Add assistant message to history
          history.add({'role': 'assistant', 'content': contentBlocks});
          
          List<Map<String, dynamic>> toolResults = [];
          for (var block in toolUseBlocks) {
            final toolResult = await _executeTool(block['name'], Map<String, dynamic>.from(block['input'] ?? {}));
            toolResults.add({
              'type': 'tool_result',
              'tool_use_id': block['id'],
              'content': jsonEncode(toolResult),
            });
          }
          history.add({'role': 'user', 'content': toolResults});
          continue;
        }

        // Extract text content
        stopWatch.stop();
        talker.info('✅ AI Link [$correlationId]: Loop completed in ${stopWatch.elapsed.inSeconds}s');
        final textBlock = contentBlocks.firstWhere((b) => b['type'] == 'text', orElse: () => {'text': ''});
        return textBlock['text'] ?? '';
      } else if (provider.type == AiProviderType.ollama) {
        // 🛡️ Ollama Response Parsing (simple message.content)
        final message = data['message'];
        if (message == null) {
          throw Exception('Ollama returned no message.');
        }
        stopWatch.stop();
        talker.info('✅ AI Link [$correlationId]: Loop completed in ${stopWatch.elapsed.inSeconds}s');
        return message['content'] ?? '';
      } else {
        // 🛡️ OpenAI / OpenRouter / LM Studio Response Parsing
        if (data['choices'] == null || (data['choices'] as List).isEmpty) {
          throw Exception('OpenAI returned no choices.');
        }

        final choice = data['choices'][0]['message'];
        if (choice['tool_calls'] != null) {
          history.add(choice);
          for (var toolCall in choice['tool_calls']) {
            final function = toolCall['function'];
            final toolResult = await _executeTool(function['name'], jsonDecode(function['arguments']));
            history.add({
              'role': 'tool',
              'tool_call_id': toolCall['id'],
              'content': jsonEncode(toolResult)
            });
          }
          continue;
        }
        stopWatch.stop();
        talker.info('✅ AI Link [$correlationId]: Loop completed in ${stopWatch.elapsed.inSeconds}s');
        return choice['content'] ?? '';
      }
    }
    stopWatch.stop();
    return 'تجاوز الوكيل الحد الأقصى لدورات المعالجة.';
  }

  /// 🔨 Execute Tool in Isar (ACID Transactions + Timeout Protection)
  Future<Map<String, dynamic>> _executeTool(String name, Map<String, dynamic> args) async {
    talker.info('🔧 Executing Tool: $name with args: $args');
    
    try {
      // 🛡️ Standard: Prevent tool execution from hanging the agent
      return await Future.any([
        _runToolLogic(name, args),
        Future.delayed(const Duration(seconds: 10), () => {'error': 'tool_timeout'})
      ]);
    } catch (e) {
      talker.error('🔴 Tool Execution Crash: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _runToolLogic(String name, Map<String, dynamic> args) async {
    switch (name) {
      case 'log_attendance':
        return await _toolLogAttendance(args);
      case 'analyze_weekly_performance':
        return await _toolAnalyzePerformance(args);
      default:
        return {'error': 'Tool not found'};
    }
  }

  /// 📝 Tool: Log Attendance
  Future<Map<String, dynamic>> _toolLogAttendance(Map<String, dynamic> args) async {
    final statusStr = args['status'] as String;
    final note = args['note'] as String?;
    
    final status = AttendanceStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => AttendanceStatus.present,
    );

    // 🛡️ Isar ACID Transaction
    await isar.writeTxn(() async {
      final log = AttendanceLog(
        date: DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0),
        status: status,
        checkInTime: DateTime.now(),
        note: note,
      );
      await isar.attendanceLogs.put(log);
    });

    return {'success': true, 'message': 'Attendance logged successfully as $statusStr'};
  }

  /// 📊 Tool: Analyze Performance
  Future<Map<String, dynamic>> _toolAnalyzePerformance(Map<String, dynamic> args) async {
    // Implementation for weekly analysis logic
    final tasks = await isar.tasks.where().findAll();
    final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
    
    return {
      'total_tasks': tasks.length,
      'completed': completed,
      'efficiency': tasks.isEmpty ? 0 : (completed / tasks.length * 100).toStringAsFixed(1),
    };
  }

  /// 🌉 Context Bridging (Minimalist Isar -> JSON)
  Future<Map<String, dynamic>> _buildMinimalContext() async {
    final now = DateTime.now();
    
    // Get recent tasks summary
    final recentTasks = await isar.tasks.where().limit(10).findAll();

    return {
      'time': now.toIso8601String().split('T')[1].substring(0, 5), // Only HH:mm
      'tasks_summary': '${recentTasks.where((t) => t.status == TaskStatus.completed).length}/${recentTasks.length} done',
      'lang': Get.locale?.languageCode ?? 'ar',
    };
  }
}
