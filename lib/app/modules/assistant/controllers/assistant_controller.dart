import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/assistant/message_model.dart';
import '../../../core/services/assistant/orchestrator/ai_orchestrator.dart';
import '../../../core/helpers/log_helper.dart';
import '../../settings/controllers/settings_controller.dart';

class AssistantController extends GetxController {
  final messages = <Message>[].obs;
  final isTyping = false.obs;
  
  final messageController = TextEditingController();
  final settingsController = Get.find<SettingsController>();
  
  // Intelligence Core
  final _orchestrator = AiOrchestrator();

  // 🛡️ Debounce guard
  DateTime? _lastActionTime;

  @override
  void onInit() {
    super.onInit();
    talker.info('🤖 AssistantController initialized (Orchestrator Mode)');
    _addWelcomeMessage();
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }

  void _addWelcomeMessage() {
    if (!settingsController.isAiConfigured) return;

    final greeting = _getGreeting();
    messages.add(Message(
      text: '$greeting\n${'assistant_welcome'.tr}',
      isUser: false,
    ));
  }

  bool get isConfigured => settingsController.isAiConfigured;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (!isConfigured) {
      talker.warning('⚠️ Attempted to send message without AI configuration');
      return;
    }

    // 🛡️ 2-second cooldown
    final now = DateTime.now();
    if (_lastActionTime != null &&
        now.difference(_lastActionTime!) < const Duration(seconds: 2)) {
      return;
    }
    
    // 🛡️ Concurrency Guard
    if (isTyping.value) return;

    _lastActionTime = now;

    messages.add(Message(text: text, isUser: true));
    isTyping.value = true;

    try {
      final response = await _orchestrator.processMessage(text, messages.toList());
      messages.add(Message(text: response.text, isUser: false, response: response));
    } catch (e, stack) {
      talker.handle(e, stack, '🤖 Assistant processing error');
      messages.add(Message(
        text: '${'error'.tr}: $e',
        isUser: false,
      ));
    }

    isTyping.value = false;
  }

  void refreshInsights() {
    talker.info('🔄 Refreshing insights...');
    // In a future version, this could fetch dynamic insights from a service
    Get.snackbar(
      'daily_insights'.tr,
      'insights_updated'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withValues(alpha: 0.1),
      colorText: Colors.green,
    );
  }

  void clearChat() {
    messages.clear();
    _addWelcomeMessage();
    talker.info('🧹 Assistant chat cleared');
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'good_morning'.tr;
    if (hour < 17) return 'good_afternoon'.tr;
    return 'good_evening'.tr;
  }
}
