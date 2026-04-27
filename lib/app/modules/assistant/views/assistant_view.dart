import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';

import '../controllers/assistant_controller.dart';
import 'widgets/response_card.dart';

class AssistantView extends GetView<AssistantController> {
  const AssistantView({super.key});

  @override
  Widget build(BuildContext context) {
    final messageController = TextEditingController();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primary, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Column(
          children: [
            Text('assistant'.tr, style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            )),
            Text(
              controller.aiMode == 'url' ? 'custom_url'.tr : 'local_intelligence'.tr,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.primary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.refresh, color: AppTheme.primary, size: 20),
            onPressed: () => _showClearDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessagesList(theme)),
            _buildTypingIndicator(theme),
            _buildQuickActions(messageController),
            _buildInputArea(context, messageController),
          ],
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('clear_chat'.tr),
        content: Text('start_fresh_message'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () {
              controller.clearChat();
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ThemeData theme) {
    return Obx(() {
      if (controller.messages.isEmpty) {
        return _buildEmptyState(theme);
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        reverse: true,
        itemCount: controller.messages.length,
        itemBuilder: (context, index) {
          final reversedIndex = controller.messages.length - 1 - index;
          final message = controller.messages[reversedIndex];
          return _buildMessageBubble(message, reversedIndex, theme);
        },
      );
    });
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.1),
                  AppTheme.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(CupertinoIcons.sparkles, size: 48, color: AppTheme.primary),
          ).animate().fadeIn(duration: 600.ms).scale(duration: 600.ms),
          const SizedBox(height: 24),
          Text(
            'assistant_greeting'.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'assistant_description'.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, int index, ThemeData theme) {
    final isUser = message.isUser;
    final hasCards = !isUser &&
        message.response != null &&
        message.response!.cards.isNotEmpty;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: Get.width * 0.85),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Text Bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primary : theme.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser ? AppTheme.primary : Colors.black)
                        .withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isUser
                          ? Colors.white
                          : theme.textTheme.bodyMedium?.color,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser
                          ? Colors.white.withValues(alpha: 0.6)
                          : theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Rich Cards (below the bubble)
            if (hasCards) ...[
              const SizedBox(height: 6),
              ...message.response!.cards
                  .map((card) => ResponseCardWidget(card: card)),
            ],
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: (index * 30).clamp(0, 300)))
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.05, duration: 250.ms);
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Obx(() {
      if (!controller.isTyping.value) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(left: 20, bottom: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) => Padding(
                  padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .fadeIn(
                          delay: Duration(milliseconds: i * 150),
                          duration: 300.ms)
                      .then()
                      .fadeOut(duration: 300.ms),
                )),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQuickActions(TextEditingController messageController) {
    return Obx(() {
      final state = controller.currentState.value;
      final List<Map<String, String>> actions;

      if (state != AssistantState.idle) {
        actions = [
          {'label': 'cancel'.tr, 'text': 'الغاء'},
        ];
      } else {
        actions = [
          {'label': 'assistant_qa_tasks'.tr, 'text': 'ما هي مهامي اليوم؟'},
          {'label': 'assistant_qa_next_appt'.tr, 'text': 'الموعد القادم'},
          {'label': 'assistant_qa_overview'.tr, 'text': 'ملخص يومي'},
          {'label': 'assistant_qa_next_med'.tr, 'text': 'هل عندي علاج؟'},
          {'label': 'quick_action_task'.tr, 'text': 'أضف مهمة '},
          {'label': 'quick_action_note'.tr, 'text': 'أضف ملاحظة '},
        ];
      }

      return Container(
        height: 42,
        margin: const EdgeInsets.only(bottom: 4),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: actions.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final action = actions[index];
            final isQuery = action['text']!.contains('؟') ||
                action['text']!.contains('ملخص') ||
                action['text']!.contains('القادم');

            return ActionChip(
              label: Text(
                action['label']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isQuery ? AppTheme.primary : null,
                ),
              ),
              onPressed: () {
                if (action['text'] == 'الغاء') {
                  controller.sendMessage(action['text']!);
                  messageController.clear();
                } else if (isQuery) {
                  // Auto-submit queries
                  controller.sendMessage(action['text']!);
                } else {
                  messageController.text = action['text']!;
                  messageController.selection = TextSelection.fromPosition(
                    TextPosition(offset: messageController.text.length),
                  );
                }
              },
              backgroundColor: isQuery
                  ? AppTheme.primary.withValues(alpha: 0.08)
                  : Theme.of(context).cardColor,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildInputArea(
    BuildContext context,
    TextEditingController messageController,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: TextField(
                controller: messageController,
                decoration: InputDecoration(
                  hintText: 'type_message_hint'.tr,
                  hintStyle: TextStyle(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                style: theme.textTheme.bodyMedium,
                onSubmitted: (text) {
                  controller.sendMessage(text);
                  messageController.clear();
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {
                controller.sendMessage(messageController.text);
                messageController.clear();
              },
              icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
