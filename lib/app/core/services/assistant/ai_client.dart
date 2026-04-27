import 'assistant_response.dart';

/// Abstract interface for AI processing.
/// Both Local and URL implementations conform to this contract.
abstract class AiClient {
  Future<AssistantResponse> process(String userMessage);
}
