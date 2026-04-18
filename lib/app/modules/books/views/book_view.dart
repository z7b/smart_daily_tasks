import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/helpers/bottom_sheet_helper.dart';
import '../controllers/book_controller.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/journal_model.dart';
import '../../../core/helpers/number_extension.dart';

class BookView extends GetView<BookController> {
  const BookView({super.key});

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── iOS Large Title AppBar ──
            SliverAppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppTheme.primary, size: 22),
                onPressed: () => Get.back(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  'my_library'.tr,
                  style: TextStyle(
                    color: theme.textTheme.titleLarge?.color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(CupertinoIcons.add_circled_solid,
                      color: AppTheme.primary, size: 28),
                  onPressed: () => controller.pickAndAddBook(),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // ── Smart summary strip ──
            SliverToBoxAdapter(
              child: Obx(() {
                final books = controller.books;
                if (books.isEmpty) return const SizedBox.shrink();
                final reading = books.where((b) => !b.isCompleted).length;
                final completed = books.where((b) => b.isCompleted).length;
                final favorites = books.where((b) => b.isFavorite).length;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      _miniChip(
                          icon: CupertinoIcons.book,
                          label: reading.f,
                          color: AppTheme.primary),
                      const SizedBox(width: 8),
                      _miniChip(
                          icon: CupertinoIcons.checkmark_seal_fill,
                          label: completed.f,
                          color: const Color(0xFF34C759)),
                      if (favorites > 0) ...[
                        const SizedBox(width: 8),
                        _miniChip(
                            icon: CupertinoIcons.heart_fill,
                            label: favorites.f,
                            color: const Color(0xFFFF2D55)),
                      ],
                    ],
                  ),
                );
              }),
            ),

            // ── Book grid ──
            Obx(() {
              if (controller.books.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary.withAlpha(15),
                          ),
                          child: Icon(CupertinoIcons.book,
                              size: 56,
                              color: AppTheme.primary.withAlpha(80)),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'add_book'.tr,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: const Duration(milliseconds: 400)).slideY(begin: 0.05),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final book = controller.books[index];
                      return _buildBookCard(context, book, index);
                    },
                    childCount: controller.books.length,
                  ),
                ),
              );
            }),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ─── Book Card ────────────────────────────────────────────────
  Widget _buildBookCard(BuildContext context, Book book, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showBookDetails(context, book.id),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showBookOptions(context, book);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? theme.cardColor.withAlpha(180) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: book.isCompleted
              ? Border.all(color: const Color(0xFF34C759).withAlpha(100), width: 2)
              : Border.all(color: theme.dividerColor.withAlpha(12)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(isDark ? 18 : 5),
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
                        if (book.isFavorite)
                          const Icon(CupertinoIcons.heart_fill,
                              color: Color(0xFFFF2D55), size: 16),
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
                          color: const Color(0xFF34C759).withAlpha(25),
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
                                  AppTheme.primary.withAlpha(25),
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

              // Last read badge
              if (book.lastReadAt != null && !book.isCompleted)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      DateFormat.MMMd(Get.locale?.languageCode)
                          .format(book.lastReadAt!),
                      style: const TextStyle(
                          fontSize: 9,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: 60 * index)).fadeIn(duration: const Duration(milliseconds: 300)).scale(
        begin: const Offset(0.96, 0.96));
  }

  // ─── Book details sheet ───────────────────────────────────────
  void _showBookDetails(BuildContext context, int bookId) {
    final moodEmojis = ['🤩', '😊', '😐', '😢', '😤'];
    final moodLabels = ['amazing', 'good', 'neutral', 'bad', 'terrible'];

    BottomSheetHelper.showSafeBottomSheet(
      builder: (context, setState) => Obx(() {
        final book = controller.books.firstWhereOrNull((b) => b.id == bookId);
        if (book == null) return const SizedBox.shrink();

        final theme = Theme.of(context);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                      color: theme.dividerColor.withAlpha(60),
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                book.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Completion badge
              if (book.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.checkmark_seal_fill,
                          color: Color(0xFF34C759), size: 14),
                      const SizedBox(width: 6),
                      Text('task_completed'.tr,
                          style: const TextStyle(
                              color: Color(0xFF34C759),
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      if (book.completedAt != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          DateFormat.yMMMd(Get.locale?.languageCode)
                              .format(book.completedAt!),
                          style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF34C759).withAlpha(180)),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Progress tap to update
              GestureDetector(
                onTap: () => _showUpdateProgressSheet(context, book),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.primary.withAlpha(30)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'pages_read'.trParams({
                          'current': book.currentPage.f,
                          'total': book.totalPages.f
                        }),
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: book.progress,
                          minHeight: 6,
                          backgroundColor: AppTheme.primary.withAlpha(20),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Mood picker
              Text('reading_mood'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
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
                        color: isSelected
                            ? AppTheme.primary.withAlpha(25)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: AppTheme.primary)
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(moodEmojis[i],
                              style: const TextStyle(fontSize: 24)),
                          Text(moodLabels[i].tr,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? AppTheme.primary
                                    : theme.dividerColor,
                              )),
                        ],
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Star rating
              Text('rate_book'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      i < book.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: const Color(0xFFFFCC00),
                      size: 32,
                    ),
                    onPressed: () => controller.setRating(book, i + 1.0),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _buildActionBtn(
                      label: 'resume_reading'.tr,
                      icon: CupertinoIcons.book_fill,
                      color: AppTheme.primary,
                      onTap: () => controller.openBookFile(book),
                    ),
                  ),
                  if (!book.isCompleted) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionBtn(
                        label: 'task_completed'.tr,
                        icon: CupertinoIcons.checkmark_seal_fill,
                        color: const Color(0xFF34C759),
                        onTap: () {
                          controller.markAsCompleted(book);
                          Get.back();
                        },
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Delete
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _confirmDeleteBook(context, book),
                  icon: const Icon(CupertinoIcons.trash,
                      size: 16, color: Color(0xFFFF3B30)),
                  label: Text('delete'.tr,
                      style: const TextStyle(color: Color(0xFFFF3B30))),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ─── Update progress bottom sheet ────────────────────────────
  void _showUpdateProgressSheet(BuildContext context, Book book) {
    final currentCtrl =
        TextEditingController(text: book.currentPage.toString());
    final totalCtrl = TextEditingController(text: book.totalPages.toString());
    final theme = Theme.of(context);

    BottomSheetHelper.showSafeBottomSheet(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                    color: theme.dividerColor.withAlpha(60),
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Text('update'.tr,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: currentCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'current_page'.tr,
                prefixIcon: const Icon(CupertinoIcons.book),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: totalCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'total_pages'.tr,
                prefixIcon: const Icon(CupertinoIcons.book_fill),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Obx(() {
                 final curr = int.tryParse(currentCtrl.text) ?? 0;
                 final total = int.tryParse(totalCtrl.text) ?? book.totalPages;
                 bool isInvalid = curr > total || curr < 0 || total <= 0;
                 return CupertinoButton(
                    color: isInvalid ? Colors.redAccent.withAlpha(200) : AppTheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    onPressed: isInvalid ? null : () {
                      controller.updateProgress(book, curr, total);
                      Get.back();
                    },
                    child: Text(isInvalid ? 'invalid'.tr : 'save'.tr,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Delete confirmation ──────────────────────────────────────
  void _confirmDeleteBook(BuildContext context, Book book) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('delete'.tr),
        content: Text('delete_confirmation'.tr),
        actions: [
          CupertinoDialogAction(
              child: Text('cancel'.tr), onPressed: () => Get.back()),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('delete'.tr),
            onPressed: () {
              controller.deleteBook(book);
              Get.back(); // close dialog
              Get.back(); // close sheet
            },
          ),
        ],
      ),
    );
  }

  // ─── Long press options ───────────────────────────────────────
  void _showBookOptions(BuildContext context, Book book) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(book.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              _showUpdateProgressSheet(context, book);
            },
            child: Text('update'.tr),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              controller.openBookFile(book);
            },
            child: Text('resume_reading'.tr),
          ),
          if (!book.isCompleted)
            CupertinoActionSheetAction(
              onPressed: () {
                controller.markAsCompleted(book);
                Get.back();
              },
              child: Text('task_completed'.tr),
            ),
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.pencil, size: 20),
                const SizedBox(width: 8),
                Text('edit_book'.tr),
              ],
            ),
            onPressed: () {
              Get.back();
              _showEditMetadataSheet(context, book);
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Get.back();
              _confirmDeleteBook(context, book);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.trash, size: 20, color: Colors.red),
                const SizedBox(width: 8),
                Text('delete'.tr),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Get.back(),
          child: Text('cancel'.tr),
        ),
      ),
    );
  }

  void _showEditMetadataSheet(BuildContext context, Book book) {
    final titleCtrl = TextEditingController(text: book.title);
    final totalPagesCtrl = TextEditingController(text: book.totalPages.toString());
    final theme = Theme.of(context);

    BottomSheetHelper.showSafeBottomSheet(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 5, decoration: BoxDecoration(color: theme.dividerColor.withAlpha(60), borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 20),
            Text('edit_book'.tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(labelText: 'title'.tr, prefixIcon: const Icon(CupertinoIcons.bookmark)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: totalPagesCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'total_pages'.tr, prefixIcon: const Icon(CupertinoIcons.number)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(16),
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) return;
                  final total = int.tryParse(totalPagesCtrl.text) ?? book.totalPages;
                  controller.updateMetadata(book, title: title, totalPages: total);
                  Get.back();
                },
                child: Text('save'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Action button ────────────────────────────────────────────
  Widget _buildActionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ─── Mini chip ────────────────────────────────────────────────
  Widget _miniChip(
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
