import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/assistant/message_model.dart';
import '../../../core/services/assistant/assistant_response.dart';
import '../../../core/services/assistant/orchestrator/ai_orchestrator.dart';
import '../../../core/helpers/log_helper.dart';

/// 🏗️ Local-Only Assistant Controller
///
/// All requests are handled by the local QueryEngine via AiOrchestrator.
/// No external API calls. No queue needed — local queries complete instantly.
class AssistantController extends GetxController {
  final messages = <Message>[].obs;

  final _orchestrator = AiOrchestrator();

  @override
  void onInit() {
    super.onInit();
    talker.info('🤖 AssistantController initialized (Local Mode)');
    _addWelcomeMessage();
  }

  // ─── Public API ──────────────────────────────────────

  /// Send a command — resolved locally, never hits a network.
  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMsg = Message.user(text.trim());
    userMsg.status = MessageStatus.success;
    messages.add(userMsg);

    talker.info('📬 Command received: "${text.trim()}"');
    _processLocally(text.trim());
  }

  void clearChat() {
    messages.clear();
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

  // ─── Local Processing ─────────────────────────────────

  Future<void> _processLocally(String text) async {
    // Show a brief pending indicator
    final pending = Message.pending('local_${DateTime.now().millisecondsSinceEpoch}');
    messages.add(pending);

    try {
      final response = await _orchestrator.processMessage(text, _buildHistory());
      _replaceLast(response);
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Local processing error');
      _replaceLast(AssistantResponse.error('${'error'.tr}: $e'));
    }
  }

  void _replaceLast(AssistantResponse response) {
    final idx = messages.lastIndexWhere((m) => !m.isUser && m.isPending);
    if (idx != -1) {
      if (response.type == ResponseType.error) {
        messages[idx] = Message.error(response.text);
      } else {
        messages[idx] = Message.bot(response.text, response: response);
      }
      messages.refresh();
    }
  }

  // ─── Helpers ─────────────────────────────────────────

  List<Message> _buildHistory() {
    return messages
        .where((m) => m.status == MessageStatus.success && m.text.isNotEmpty)
        .toList();
  }

  void _addWelcomeMessage() {
    final greeting = _getGreeting();
    messages.add(Message.bot('$greeting\n${'assistant_welcome'.tr}'));
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'good_morning'.tr;
    if (hour < 17) return 'good_afternoon'.tr;
    return 'good_evening'.tr;
  }
}
