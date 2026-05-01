import 'assistant_response.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final AssistantResponse? response;

  Message({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.response,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };
}
