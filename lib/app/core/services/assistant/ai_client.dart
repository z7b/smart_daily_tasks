import 'message_model.dart';
import 'assistant_response.dart';

/// Abstract interface for AI processing.
abstract class AiClient {
  Future<AssistantResponse> process(List<Message> history, {String? systemContext});
}
