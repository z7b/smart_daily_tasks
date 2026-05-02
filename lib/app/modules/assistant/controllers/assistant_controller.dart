import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/assistant/message_model.dart';
import '../../../core/services/assistant/assistant_response.dart';
import '../../../core/services/assistant/orchestrator/ai_orchestrator.dart';
import '../../../core/helpers/log_helper.dart';
import '../../settings/controllers/settings_controller.dart';

/// 🏗️ Production-Grade AI Assistant Controller
/// 
/// Architecture:
/// - FIFO Message Queue with status tracking
/// - Auto-retry on network failure (max 3 attempts)
/// - Zero main-thread blocking
/// - runZonedGuarded for crash isolation
/// - Trace IDs for full observability
class AssistantController extends GetxController {
  final messages = <Message>[].obs;
  
  final messageController = TextEditingController();
  final settingsController = Get.find<SettingsController>();
  
  // Intelligence Core
  final _orchestrator = AiOrchestrator();

  // Queue System
  final List<_QueueEntry> _queue = [];
  bool _isProcessing = false;
  static const int _maxRetries = 3;

  @override
  void onInit() {
    super.onInit();
    talker.info('🤖 AssistantController initialized (Production Queue Mode)');
    _addWelcomeMessage();
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }

  bool get isConfigured => settingsController.isAiConfigured;

  // ─── Public API ──────────────────────────────────────

  /// Send a message. Never drops, never blocks.
  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    if (!isConfigured) {
      talker.warning('⚠️ Attempted to send message without AI configuration');
      _showWarning('ai_not_configured'.tr);
      return;
    }

    final userMsg = Message.user(text.trim());
    userMsg.status = MessageStatus.success; // User messages are always "sent"
    messages.add(userMsg);

    // Enqueue for AI processing
    final entry = _QueueEntry(
      text: text.trim(),
      traceId: userMsg.traceId,
    );
    _queue.add(entry);

    talker.info('📬 [${entry.traceId}] Message queued (queue depth: ${_queue.length})');

    if (!_isProcessing) {
      _drainQueue();
    }
  }

  /// Retry a failed message
  void retryMessage(String traceId) {
    final idx = messages.indexWhere((m) => m.traceId == traceId && m.isFailed && !m.isUser);
    if (idx == -1) return;

    // Find the original user message to get the text
    final userIdx = messages.lastIndexWhere((m) => m.isUser, idx);
    if (userIdx == -1) return;

    final userText = messages[userIdx].text;

    // Remove the failed bot response
    messages.removeAt(idx);

    // Re-enqueue
    final entry = _QueueEntry(text: userText, traceId: 'retry_${DateTime.now().millisecondsSinceEpoch}');
    _queue.add(entry);
    talker.info('🔄 [${entry.traceId}] Message re-queued for retry');

    if (!_isProcessing) {
      _drainQueue();
    }
  }

  void clearChat() {
    messages.clear();
    _queue.clear();
    _isProcessing = false;
    _addWelcomeMessage();
    talker.info('🧹 Assistant chat cleared');
  }

  void refreshInsights() {
    Get.snackbar(
      'daily_insights'.tr,
      'insights_updated'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withValues(alpha: 0.1),
      colorText: Colors.green,
    );
  }

  // ─── Queue Processor ─────────────────────────────────

  /// 🛡️ FIX #1: `runZonedGuarded` returns void, not Future.
  /// We must use a Completer to properly await the guarded async work.
  /// 
  /// 🛡️ FIX #2: Wrap the entire drain loop in try/finally to guarantee
  /// `_isProcessing` is always reset, even on unexpected errors.
  Future<void> _drainQueue() async {
    if (_queue.isEmpty) {
      _isProcessing = false;
      return;
    }

    _isProcessing = true;

    final entry = _queue.removeAt(0);

    // 🛡️ FIX #3: Use the message's own identity (traceId) to find its
    // placeholder instead of a brittle integer index that can shift
    // when new messages are added concurrently.
    final pendingMsg = Message.pending(entry.traceId);
    messages.add(pendingMsg);

    try {
      // 🛡️ FIX #1: Use a Completer so `await` actually waits for
      // the async work inside runZonedGuarded to finish.
      final completer = Completer<void>();

      runZonedGuarded(() async {
        try {
          await _processEntry(entry);
        } finally {
          if (!completer.isCompleted) completer.complete();
        }
      }, (error, stack) {
        talker.error('🛡️ [${entry.traceId}] Queue Guard caught crash: $error');
        _replacePendingByTraceId(entry.traceId, Message.error(
          'unexpected_error'.tr,
          traceId: entry.traceId,
        ));
        if (!completer.isCompleted) completer.complete();
      });

      await completer.future;
    } catch (e) {
      // 🛡️ FIX #2: Catch-all for anything the Completer itself might throw
      talker.error('🛡️ [${entry.traceId}] Drain loop safety net: $e');
    }

    // Small cooldown between messages to prevent API flooding
    await Future.delayed(const Duration(milliseconds: 200));

    // Process next item (tail call — will return immediately if queue is empty)
    _drainQueue();
  }

  Future<void> _processEntry(_QueueEntry entry) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        talker.info('🤖 [${entry.traceId}] Processing (attempt $attempt/$_maxRetries)');
        
        if (attempt > 1) {
          _updatePendingStatusByTraceId(entry.traceId, MessageStatus.retrying);
        }

        // 60s safety net — the actual timeout is handled by postWithRetry
        // (15s per compute × 2 retries + backoffs ≈ 35s max)
        // This only fires if something truly catastrophic hangs.
        final response = await _orchestrator
            .processMessage(entry.text, _buildHistory(), correlationId: entry.traceId)
            .timeout(const Duration(seconds: 60));

        // Success — check if the response itself is an error type
        if (response.type == ResponseType.error) {
          talker.warning('⚠️ [${entry.traceId}] AI returned error response: ${response.text}');
          _replacePendingByTraceId(entry.traceId, Message.error(
            response.text,
            traceId: entry.traceId,
          ));
        } else {
          talker.info('✅ [${entry.traceId}] Response received');
          _replacePendingByTraceId(entry.traceId, Message.bot(
            response.text,
            response: response,
          ));
        }
        return;

      } on TimeoutException {
        talker.warning('⏳ [${entry.traceId}] Timeout on attempt $attempt/$_maxRetries');
        if (attempt >= _maxRetries) {
          _replacePendingByTraceId(entry.traceId, Message.error(
            'timeout_error'.tr,
            traceId: entry.traceId,
          ));
          _showWarning('timeout_error'.tr);
        } else {
          await Future.delayed(Duration(seconds: attempt * 2)); // Exponential backoff
        }
      } catch (e) {
        talker.error('🔴 [${entry.traceId}] Error on attempt $attempt: $e');
        if (attempt >= _maxRetries) {
          _replacePendingByTraceId(entry.traceId, Message.error(
            '${'error'.tr}: $e',
            traceId: entry.traceId,
          ));
          _showWarning('connection_failed'.tr);
        } else {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
  }

  // ─── Helpers ─────────────────────────────────────────

  List<Message> _buildHistory() {
    // Only include successful messages for context
    return messages
        .where((m) => m.status == MessageStatus.success && m.text.isNotEmpty)
        .toList();
  }

  /// 🛡️ FIX #3: Find message by traceId instead of brittle integer index.
  /// This is safe even when new messages are added/removed concurrently.
  void _replacePendingByTraceId(String traceId, Message replacement) {
    final idx = messages.indexWhere((m) => m.traceId == traceId && !m.isUser);
    if (idx != -1) {
      messages[idx] = replacement;
      messages.refresh();
    }
  }

  void _updatePendingStatusByTraceId(String traceId, MessageStatus status) {
    final idx = messages.indexWhere((m) => m.traceId == traceId && !m.isUser);
    if (idx != -1) {
      messages[idx].status = status;
      messages.refresh();
    }
  }

  void _addWelcomeMessage() {
    if (!settingsController.isAiConfigured) return;
    final greeting = _getGreeting();
    messages.add(Message.bot('$greeting\n${'assistant_welcome'.tr}'));
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'good_morning'.tr;
    if (hour < 17) return 'good_afternoon'.tr;
    return 'good_evening'.tr;
  }

  void _showWarning(String message) {
    Get.rawSnackbar(
      message: message,
      backgroundColor: Colors.orange.shade800,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
    );
  }
}

/// Internal queue entry — separate from UI Message
class _QueueEntry {
  final String text;
  final String traceId;

  _QueueEntry({
    required this.text,
    required this.traceId,
  });
}
