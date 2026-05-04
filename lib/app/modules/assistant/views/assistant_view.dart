import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/assistant_controller.dart';
import '../../../core/services/assistant/message_model.dart';
import 'widgets/response_card.dart';
import 'widgets/assistant_status_header.dart';
import 'widgets/assistant_dashboard.dart';

class AssistantView extends GetView<AssistantController> {
  const AssistantView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: SafeArea(
        child: Column(
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
            const _QuickActionsArea(),
          ],
        ),
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
        Obx(() => controller.messages.length > 1
          ? IconButton(
              icon: Icon(Icons.delete_sweep_outlined, color: AppTheme.primary, size: 22),
              onPressed: () => _showClearDialog(Get.context!),
            )
          : const SizedBox.shrink()),
      ],
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

// ─── Chat List ─────────────────────────────────────────

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

// ─── Message Bubble ────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Message message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final hasCards = !isUser && message.response != null && message.response!.cards.isNotEmpty;

    if (message.isPending) {
      return _PendingBubble(isRetrying: false);
    }

    return Align(
      alignment: isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: Get.width * 0.85),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: _getBubbleColor(theme, isUser, message.isFailed),
                borderRadius: BorderRadiusDirectional.only(
                  topStart: const Radius.circular(20),
                  topEnd: const Radius.circular(20),
                  bottomStart: Radius.circular(isUser ? 20 : 4),
                  bottomEnd: Radius.circular(isUser ? 4 : 20),
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
                  color: isUser ? Colors.white : (message.isFailed ? Colors.red.shade300 : theme.textTheme.bodyMedium?.color),
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

  Color _getBubbleColor(ThemeData theme, bool isUser, bool isFailed) {
    if (isFailed) return Colors.red.withValues(alpha: 0.1);
    return isUser ? AppTheme.primary : theme.cardColor;
  }
}

// ─── Pending Bubble (StatefulWidget — lifecycle-safe animation) ──────

/// Uses AnimationController directly to avoid flutter_animate onPlay+repeat
/// causing _AssertionError when widget is disposed mid-animation.
class _PendingBubble extends StatefulWidget {
  final bool isRetrying;
  const _PendingBubble({required this.isRetrying});

  @override
  State<_PendingBubble> createState() => _PendingBubbleState();
}

class _PendingBubbleState extends State<_PendingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(20),
              topEnd: Radius.circular(20),
              bottomEnd: Radius.circular(20),
              bottomStart: Radius.circular(4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Text(
                'thinking'.tr,
                style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick Actions (الأوامر السريعة) ───────────────────

class _QuickActionsArea extends GetWidget<AssistantController> {
  const _QuickActionsArea();

  @override
  Widget build(BuildContext context) {
    final actions = [
      {'label': 'assistant_qa_tasks'.tr},
      {'label': 'assistant_qa_next_appt'.tr},
      {'label': 'assistant_qa_overview'.tr},
    ];

    return Container(
      height: 52,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final action = actions[index];
          return ActionChip(
            label: Text(action['label']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
            onPressed: () => controller.sendMessage(action['label']!),
            backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }
}
