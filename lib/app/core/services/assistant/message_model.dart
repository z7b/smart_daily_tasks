import 'assistant_response.dart';

/// Message delivery status for queue tracking
enum MessageStatus {
  queued,
  processing,
  success,
  failed,
  retrying,
}

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String traceId;
  final AssistantResponse? response;

  /// Mutable status for queue system to update
  MessageStatus status;
  int retryCount;

  Message({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    String? traceId,
    this.response,
    this.status = MessageStatus.success,
    this.retryCount = 0,
  })  : timestamp = timestamp ?? DateTime.now(),
        traceId = traceId ?? 'msg_${DateTime.now().millisecondsSinceEpoch}';

  /// Create a user message (always starts as queued)
  factory Message.user(String text) => Message(
        text: text,
        isUser: true,
        status: MessageStatus.queued,
      );

  /// Create a bot response
  factory Message.bot(String text, {AssistantResponse? response}) => Message(
        text: text,
        isUser: false,
        response: response,
        status: MessageStatus.success,
      );

  /// Create a pending bot placeholder (shown while processing)
  factory Message.pending(String traceId) => Message(
        text: '',
        isUser: false,
        traceId: traceId,
        status: MessageStatus.processing,
      );

  /// Create an error response
  factory Message.error(String errorText, {String? traceId}) => Message(
        text: errorText,
        isUser: false,
        traceId: traceId,
        status: MessageStatus.failed,
      );

  bool get isPending => status == MessageStatus.processing;
  bool get isFailed => status == MessageStatus.failed;
  bool get isRetrying => status == MessageStatus.retrying;

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'traceId': traceId,
        'status': status.name,
      };
}
