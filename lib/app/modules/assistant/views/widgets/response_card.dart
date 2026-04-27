import 'package:flutter/material.dart';

import '../../../../core/services/assistant/assistant_response.dart';

/// Premium card widget for displaying task/appointment/medication info
/// inside chat bubbles with status colors and countdown info.
class ResponseCardWidget extends StatelessWidget {
  final ResponseCard card;

  const ResponseCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = card.statusColor ?? const Color(0xFF6B7280);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Status Badge
          Row(
            children: [
              Expanded(
                child: Text(
                  card.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleMedium?.color,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (card.statusLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    card.statusLabel!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),

          // Subtitle
          if (card.subtitle != null && card.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              card.subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],

          // Time info + Countdown
          if (card.timeInfo != null || card.countdown != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (card.timeInfo != null) ...[
                    Icon(Icons.access_time_rounded, size: 12, color: color.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      card.timeInfo!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                  if (card.timeInfo != null && card.countdown != null)
                    const SizedBox(width: 12),
                  if (card.countdown != null)
                    Text(
                      card.countdown!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
