import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/assistant_controller.dart';

class AssistantView extends GetView<AssistantController> {
  const AssistantView({super.key});

  @override
  Widget build(BuildContext context) {
    final messageController = TextEditingController();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('assistant'.tr),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(Icons.auto_awesome, size: 48, color: AppTheme.primary),
          ).animate().fadeIn(duration: const Duration(milliseconds: 600)).scale(),
          const SizedBox(height: 24),
          Text(
            'assistant_greeting'.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
          const SizedBox(height: 8),
          Text(
            'assistant_description'.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, int index, ThemeData theme) {
    final isUser = message.isUser;

    return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            constraints: BoxConstraints(maxWidth: Get.width * 0.8),
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
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isUser
                        ? Colors.white
                        : theme.textTheme.bodyLarge?.color,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatTime(message.timestamp),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isUser
                        ? Colors.white.withValues(alpha: 0.7)
                        : theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.7,
                          ),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: index * 50))
        .fadeIn(duration: const Duration(milliseconds: 300))
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Obx(() {
      if (!controller.isTyping.value) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(left: 20, bottom: 20),
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
                children: [
                  _buildDot(0),
                  const SizedBox(width: 4),
                  _buildDot(1),
                  const SizedBox(width: 4),
                  _buildDot(2),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDot(int index) {
    return Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .fadeIn(delay: Duration(milliseconds: index * 150), duration: const Duration(milliseconds: 300))
        .then()
        .fadeOut(duration: const Duration(milliseconds: 300));
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
          {'label': 'quick_action_task'.tr, 'text': 'أضف مهمة '},
          {'label': 'quick_action_note'.tr, 'text': 'أضف ملاحظة '},
          {'label': 'quick_action_journal'.tr, 'text': 'سجل تدوينة '},
          {'label': 'goal'.tr, 'text': 'هدفي اليومي 10000 خطوة'},
          {'label': 'calendar'.tr, 'text': 'افتح التقويم'},
        ];
      }

      return SizedBox(
        height: 40,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: actions.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final action = actions[index];
            return ActionChip(
              label: Text(action['label']!),
              onPressed: () {
                messageController.text = action['text']!;
                messageController.selection = TextSelection.fromPosition(
                  TextPosition(offset: messageController.text.length),
                );
                // Auto-submit if it's a specific action or handle manually
                if (action['text'] == 'الغاء') {
                  controller.sendMessage(action['text']!);
                  messageController.clear();
                }
              },
              backgroundColor: Theme.of(context).cardColor,
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
      padding: const EdgeInsets.all(16),
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
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.5,
                    ),
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
          const SizedBox(width: 12),
          FloatingActionButton(
            onPressed: () {
              controller.sendMessage(messageController.text);
              messageController.clear();
            },
            mini: true,
            elevation: 0,
            child: const Icon(Icons.arrow_upward, size: 20),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
