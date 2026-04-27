import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/helpers/log_helper.dart';
import 'ai_client.dart';
import 'assistant_response.dart';

/// Remote AI client that sends user messages to a custom URL endpoint.
/// Compatible with OpenAI-style chat completions API format.
class UrlAiClient implements AiClient {
  final String baseUrl;

  UrlAiClient({required this.baseUrl});

  @override
  Future<AssistantResponse> process(String userMessage) async {
    try {
      final uri = Uri.parse(baseUrl);
      
      final body = jsonEncode({
        'model': 'default',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a helpful assistant for a productivity app called Life OS. '
                'Respond in the same language the user uses (Arabic or English). '
                'Keep responses concise and helpful.',
          },
          {
            'role': 'user',
            'content': userMessage,
          },
        ],
        'max_tokens': 500,
        'temperature': 0.7,
      });

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        // OpenAI-compatible response format
        if (json['choices'] != null && (json['choices'] as List).isNotEmpty) {
          final content = json['choices'][0]['message']['content'] as String;
          return AssistantResponse.text(content.trim());
        }
        
        // Simple response format: { "response": "..." }
        if (json['response'] != null) {
          return AssistantResponse.text(json['response'] as String);
        }

        // Raw text fallback
        return AssistantResponse.text(response.body);
      } else {
        talker.error('🔴 AI URL Error: ${response.statusCode} ${response.body}');
        return AssistantResponse.error(
          '⚠️ API Error: ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 AI URL Client Error');
      return AssistantResponse.error('⚠️ Connection error: $e');
    }
  }
}
