import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/book_controller.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/journal_model.dart';
import '../../../core/helpers/log_helper.dart';
import '../../../core/helpers/bottom_sheet_helper.dart';

class BookView extends GetView<BookController> {
  const BookView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('my_library'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add_circled_solid, color: AppTheme.primary, size: 28),
            onPressed: () => controller.pickAndAddBook(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.books.isEmpty) {
          return _buildEmptyState(theme);
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: controller.books.length,
          itemBuilder: (context, index) {
            final book = controller.books[index];
            return _buildBookCard(context, book, index);
          },
        );
      }),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.book, size: 80, color: theme.dividerColor.withAlpha(50)),
          const SizedBox(height: 16),
          Text('add_book'.tr, style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildBookCard(BuildContext context, Book book, int index) {
    final theme = Theme.of(context);
    final moodEmojis = {'amazing': '🤩', 'good': '😊', 'neutral': '😐', 'bad': '😢', 'terrible': '😤'};
    
    return GestureDetector(
      onTap: () => _showBookDetails(context, book.id),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: book.isCompleted ? Border.all(color: Colors.green.withAlpha(100), width: 2) : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, shape: BoxShape.circle),
                      child: Text(moodEmojis[book.readingMood.name] ?? '😐', style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < book.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.orange,
                        size: 14,
                      )),
                    ),
                    const Spacer(),
                    if (book.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 12),
                            const SizedBox(width: 4),
                            Text('task_completed'.tr, style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: book.progress,
                            backgroundColor: AppTheme.primary.withAlpha(30),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                            minHeight: 4,
                          ),
                          const SizedBox(height: 4),
                          Text('${(book.progress * 100).toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        ],
                      ),
                  ],
                ),
              ),
              if (book.isFavorite)
                Positioned(top: 12, right: 12, child: const Icon(CupertinoIcons.heart_fill, color: Colors.red, size: 16)),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().scale();
  }

  void _showBookDetails(BuildContext context, int bookId) {
    final theme = Theme.of(context);
    final moodEmojis = ['🤩', '😊', '😐', '😢', '😤'];
    final moodLabels = ['amazing', 'good', 'neutral', 'bad', 'terrible'];

    BottomSheetHelper.showSafeBottomSheet(
      builder: (context, setState) => Obx(() {
        final book = controller.books.firstWhere((b) => b.id == bookId);
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(book.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            GestureDetector(
              onTap: () => _showUpdateProgressDialog(context, book),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppTheme.primary.withAlpha(10), borderRadius: BorderRadius.circular(12)),
                child: Text('pages_read'.trParams({'current': book.currentPage.toString(), 'total': book.totalPages.toString()}), 
                  style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text('reading_mood'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(moodEmojis.length, (i) {
                final mood = Mood.values[i];
                final isSelected = book.readingMood == mood;
                return GestureDetector(
                  onTap: () => controller.setMood(book, mood),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary.withAlpha(30) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? Border.all(color: AppTheme.primary) : null,
                    ),
                    child: Column(
                      children: [
                        Text(moodEmojis[i], style: const TextStyle(fontSize: 24)),
                        Text(moodLabels[i].tr, style: TextStyle(fontSize: 10, color: isSelected ? AppTheme.primary : theme.dividerColor)),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            Text('rate_book'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(
                    i < book.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.orange,
                    size: 32,
                  ),
                  onPressed: () => controller.setRating(book, i + 1.0),
                );
              }),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(CupertinoIcons.book_fill),
                    label: Text('resume_reading'.tr),
                    onPressed: () => controller.openBookFile(book),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  ),
                ),
                const SizedBox(width: 12),
                if (!book.isCompleted)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_rounded),
                      label: Text('task_completed'.tr),
                      onPressed: () {
                        controller.markAsCompleted(book);
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                controller.deleteBook(book);
                Get.back();
              },
              child: Text('delete_task'.tr, style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      }),
    );
  }

  void _showUpdateProgressDialog(BuildContext context, Book book) {
    final currentController = TextEditingController(text: book.currentPage.toString());
    final totalController = TextEditingController(text: book.totalPages.toString());

    Get.dialog(
      AlertDialog(
        title: Text('update'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: currentController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Current Page')),
            TextField(controller: totalController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Pages')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () {
              controller.updateProgress(book, int.parse(currentController.text), int.parse(totalController.text));
              Get.back();
            },
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }
}
