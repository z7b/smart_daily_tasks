import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:smart_daily_tasks/app/modules/settings/controllers/settings_controller.dart';
import '../../../../core/services/assistant/ai_health_tracker.dart';

class AssistantStatusHeader extends StatelessWidget {
  const AssistantStatusHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          _buildHealthIndicator(settings),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'assistant_active'.tr,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  letterSpacing: 0.5,
                ),
              ),
              Obx(() => Text(
                settings.activeAiProvider.displayName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                ),
              )),
            ],
          ),
          const Spacer(),
          _buildModelBadge(settings, theme),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(SettingsController settings) {
    return Obx(() {
      final isHealthy = AiHealthTracker.isHealthy(
        settings.activeAiProvider.type.name,
        settings.aiModel.value,
      );

      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isHealthy ? Colors.green : Colors.orange,
          boxShadow: [
            BoxShadow(
              color: (isHealthy ? Colors.green : Colors.orange).withValues(alpha: 0.4),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildModelBadge(SettingsController settings, ThemeData theme) {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        settings.aiModel.value.split('/').last.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
    ));
  }
}
