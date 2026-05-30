import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';


import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/book_model.dart';

import '../../../../core/helpers/number_extension.dart';
import '../../../../widgets/glassy_pin_button.dart';

class BookTile extends StatelessWidget {
  final Book book;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onRead;
  final Function(bool) onStatusChange;

  const BookTile({
    super.key,
    required this.book,
    required this.index,
    required this.onDelete,
    required this.onEdit,
    required this.onRead,
    required this.onStatusChange,
  });

  static const _moodEmojis = {
    'amazing': '🤩',
    'good': '😊',
    'neutral': '😐',
    'bad': '😢',
    'terrible': '😤',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AspectRatio(
      aspectRatio: 0.72,
      child: GestureDetector(
        onTap: onRead, // Typically opens book details
      onLongPress: () {
        HapticFeedback.mediumImpact();
        // Typically opens book options. Handled by parent.
        onEdit();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? theme.cardColor.withValues(alpha: 0.7) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: book.isCompleted
              ? Border.all(color: const Color(0xFF34C759).withValues(alpha: 0.4), width: 2)
              : Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.07 : 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mood + favorite
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _moodEmojis[book.readingMood.name] ?? '😐',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        const Spacer(),
                        GlassyPinButton(itemType: 'book', itemId: book.id, size: 24),
                        if (book.isFavorite) ...[
                          const SizedBox(width: 6),
                          const Icon(CupertinoIcons.heart_fill,
                              color: Color(0xFFFF2D55), size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Title
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.3,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Star rating
                    Row(
                      children: List.generate(
                          5,
                          (i) => Icon(
                                i < book.rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: const Color(0xFFFFCC00),
                                size: 13,
                              )),
                    ),

                    const Spacer(),

                    // Page count
                    if (book.totalPages > 0) ...[
                      Text(
                        '${book.currentPage.f} / ${book.totalPages.f} ${'pages'.tr}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Completion / progress
                    if (book.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.checkmark_alt,
                                color: Color(0xFF34C759), size: 12),
                            const SizedBox(width: 4),
                            Text('task_completed'.tr,
                                style: const TextStyle(
                                    color: Color(0xFF34C759),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: book.progress,
                              backgroundColor:
                                  AppTheme.primary.withValues(alpha: 0.1),
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                      AppTheme.primary),
                              minHeight: 5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(book.progress * 100).toInt().f}%',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
      ),
    );
  }
}
