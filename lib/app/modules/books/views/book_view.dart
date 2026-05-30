import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';


import '../../../core/theme/app_theme.dart';
import '../../../core/helpers/bottom_sheet_helper.dart';
import '../controllers/book_controller.dart';
import '../../../data/models/book_model.dart';

import '../../../core/helpers/number_extension.dart';
import '../../../widgets/ad_banner_widget.dart';

import 'widgets/book_tile.dart';

class BookView extends GetView<BookController> {
  const BookView({super.key});

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
                titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
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

            // ── Ad Banner ──
            SliverToBoxAdapter(
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: AdBannerWidget(),
              ),
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

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  // ─── Book Card ────────────────────────────────────────────────
  Widget _buildBookCard(BuildContext context, Book book, int index) {
    return BookTile(
      book: book,
      index: index,
      onDelete: () => _confirmDeleteBook(context, book),
      onEdit: () => _showEditMetadataSheet(context, book),
      onRead: () => _showUpdateProgressSheet(context, book),
      onStatusChange: (status) {
        if (status) {
          controller.markAsCompleted(book);
        }
      },
    ).animate(delay: Duration(milliseconds: 60 * index)).fadeIn(duration: const Duration(milliseconds: 300)).scale(
        begin: const Offset(0.96, 0.96));
  }


  // ─── Update progress bottom sheet ────────────────────────────
  void _showUpdateProgressSheet(BuildContext context, Book book) {
    final currentCtrl = TextEditingController(text: book.currentPage.toString());
    final totalCtrl = TextEditingController(text: book.totalPages.toString());
    final theme = Theme.of(context);

    BottomSheetHelper.showSafeBottomSheet(
      builder: (context, setState) {
        // Validation logic
        bool isInvalid() {
          final curr = int.tryParse(currentCtrl.text) ?? 0;
          final total = int.tryParse(totalCtrl.text) ?? book.totalPages;
          return curr > total || curr < 0 || total <= 0;
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          // 🛡️ Notice: We rely entirely on BottomSheetHelper for viewInsets.
          // No more double-padding layout loops causing ANRs!
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                      color: theme.dividerColor.withAlpha(50),
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),

              // Title Header
              Row(
                children: [
                   Container(
                     padding: const EdgeInsets.all(10),
                     decoration: BoxDecoration(
                       color: AppTheme.primary.withAlpha(20),
                       shape: BoxShape.circle,
                     ),
                     child: const Icon(CupertinoIcons.book_solid, color: AppTheme.primary, size: 24),
                   ),
                   const SizedBox(width: 14),
                   Text('update_progress'.tr,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 30),

              // Input Fields
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('current_page'.tr, 
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium?.color?.withAlpha(150))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: currentCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: theme.cardColor,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 34),
                    child: Text('/', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('total_pages'.tr, 
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium?.color?.withAlpha(150))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: totalCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: theme.cardColor,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (isInvalid()) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text('invalid_progress_data'.tr, 
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ],

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: isInvalid() ? Colors.redAccent.withAlpha(200) : AppTheme.primary,
                  borderRadius: BorderRadius.circular(16),
                  onPressed: isInvalid() ? null : () {
                    FocusScope.of(context).unfocus(); // Dismiss keyboard safely
                    final curr = int.tryParse(currentCtrl.text) ?? 0;
                    final total = int.tryParse(totalCtrl.text) ?? book.totalPages;
                    controller.updateProgress(book, curr, total);
                    Get.back();
                  },
                  child: Text(isInvalid() ? 'invalid'.tr : 'save'.tr,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
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
