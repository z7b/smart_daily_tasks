import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TaskSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int count;

  const TaskSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color?.withValues(alpha: 0.8),
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }
}
