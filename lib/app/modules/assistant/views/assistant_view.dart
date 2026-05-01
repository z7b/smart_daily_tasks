import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/assistant_controller.dart';
import '../../../core/services/assistant/message_model.dart';
import 'widgets/response_card.dart';
import 'widgets/assistant_status_header.dart';
import 'widgets/assistant_dashboard.dart';
import 'assistant_settings_view.dart';

class AssistantView extends GetView<AssistantController> {
  const AssistantView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: SafeArea(
        child: Obx(() {
          if (!controller.isConfigured) {
            return _buildSetupRequired(theme);
          }

          return Column(
            children: [
              const AssistantStatusHeader(),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: AssistantDashboard()),
                    const _ChatSliverList(),
                  ],
                ),
              ),
              const _TypingIndicator(),
              const _QuickActionsArea(),
              const _AssistantInputArea(),
            ],
          );
        }),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primary, size: 20),
        onPressed: () => Get.back(),
      ),
      title: Text('assistant'.tr, style: TextStyle(
        fontWeight: FontWeight.bold,
        color: theme.textTheme.titleLarge?.color,
      )),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(CupertinoIcons.settings, color: AppTheme.primary, size: 20),
          onPressed: () => Get.to(() => const AssistantSettingsView()),
        ),
        Obx(() => controller.isConfigured 
          ? IconButton(
              icon: Icon(CupertinoIcons.refresh, color: AppTheme.primary, size: 20),
              onPressed: () => _showClearDialog(Get.context!),
            )
          : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildSetupRequired(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded, size: 64, color: Colors.white),
            ).animate().scale(duration: const Duration(milliseconds: 600), curve: Curves.easeOutBack).shimmer(delay: const Duration(seconds: 1), duration: const Duration(seconds: 2)),
            
            const SizedBox(height: 48),
            
            Text(
              'ai_setup_required_title'.tr,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(duration: const Duration(milliseconds: 200)).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 16),
            
            Text(
              'ai_setup_required_desc'.tr,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                height: 1.6,
              ),
            ).animate().fadeIn(duration: const Duration(milliseconds: 400)).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 48),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.to(() => const AssistantSettingsView()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.settings_suggest_rounded),
                    const SizedBox(width: 12),
                    Text('go_to_settings'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: const Duration(milliseconds: 600)).slideY(begin: 0.3, end: 0),
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
}

class _ChatSliverList extends GetWidget<AssistantController> {
  const _ChatSliverList();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.messages.isEmpty) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }

      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        sliver: SliverList.builder(
          itemCount: controller.messages.length,
          itemBuilder: (context, index) {
            final message = controller.messages[index];
            return _MessageBubble(message: message);
          },
        ),
      );
    });
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final hasCards = !isUser && message.response != null && message.response!.cards.isNotEmpty;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: Get.width * 0.85),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primary : theme.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser ? AppTheme.primary : Colors.black).withValues(alpha: 0.06),
                    blurRadius: 12, offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUser ? Colors.white : theme.textTheme.bodyMedium?.color,
                  height: 1.5,
                ),
              ),
            ),
            if (hasCards) ...[
              const SizedBox(height: 6),
              ...message.response!.cards.map((card) => ResponseCardWidget(card: card)),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 200)).slideY(begin: 0.05, duration: const Duration(milliseconds: 200));
  }
}

class _TypingIndicator extends GetWidget<AssistantController> {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                children: List.generate(3, (i) => Padding(
                  padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
                  child: Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.3, 1.3), duration: const Duration(milliseconds: 500), delay: Duration(milliseconds: i * 150)),
                )),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _QuickActionsArea extends GetWidget<AssistantController> {
  const _QuickActionsArea();

  @override
  Widget build(BuildContext context) {
    final actions = [
      {'label': 'assistant_qa_tasks'.tr, 'text': 'ما هي مهامي اليوم؟'},
      {'label': 'assistant_qa_next_appt'.tr, 'text': 'الموعد القادم'},
      {'label': 'assistant_qa_overview'.tr, 'text': 'ملخص يومي'},
    ];

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
          return ActionChip(
            label: Text(action['label']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
            onPressed: () => controller.sendMessage(action['text']!),
            backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }
}

class _AssistantInputArea extends GetWidget<AssistantController> {
  const _AssistantInputArea();

  @override
  Widget build(BuildContext context) {
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
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: controller.messageController,
                decoration: InputDecoration(
                  hintText: 'type_message_hint'.tr,
                  hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onSubmitted: (text) {
                  controller.sendMessage(text);
                  controller.messageController.clear();
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          _SendButton(controller: controller),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final AssistantController controller;
  const _SendButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)]),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: IconButton(
        onPressed: () {
          controller.sendMessage(controller.messageController.text);
          controller.messageController.clear();
        },
        icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
