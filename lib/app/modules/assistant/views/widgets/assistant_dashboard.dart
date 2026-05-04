import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_daily_tasks/app/modules/assistant/controllers/assistant_controller.dart';
import 'insight_card.dart';

class AssistantDashboard extends GetWidget<AssistantController> {
  const AssistantDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'daily_insights'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: () => controller.refreshInsights(),
                child: Text('refresh'.tr, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              InsightCard(
                title: 'today_focus'.tr,
                subtitle: 'focus_desc'.tr,
                icon: Icons.track_changes_rounded,
                onTap: () => controller.sendMessage('today_focus'.tr),
              ),
              InsightCard(
                title: 'health_check'.tr,
                subtitle: 'health_desc'.tr,
                icon: Icons.favorite_rounded,
                color: Colors.redAccent,
                onTap: () => controller.sendMessage('health_check'.tr),
              ),
              InsightCard(
                title: 'day_summary'.tr,
                subtitle: 'summary_desc'.tr,
                icon: Icons.wb_sunny_rounded,
                color: Colors.orange,
                onTap: () => controller.sendMessage('day_summary'.tr),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
