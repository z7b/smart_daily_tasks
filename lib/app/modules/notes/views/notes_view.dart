import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/notes_controller.dart';

class NotesView extends GetView<NotesController> {
  const NotesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(CupertinoIcons.back, color: AppTheme.primary, size: 28),
                onPressed: () => Get.back(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  'notes'.tr, // ✅ Showing "الملاحظات"
                  style: TextStyle(
                    color: theme.textTheme.titleLarge?.color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(CupertinoIcons.add_circled_solid, color: AppTheme.primary, size: 28),
                  onPressed: () => Get.toNamed('/add-note'),
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.search, color: theme.textTheme.bodyMedium?.color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: controller.searchNotes,
                          decoration: InputDecoration(
                            hintText: 'search_notes'.tr, // ✅ Showing "ابحث عن الملاحظات..."
                            hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Obx(() {
              if (controller.filteredNotes.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.doc_text, size: 60, color: theme.dividerColor),
                        const SizedBox(height: 16),
                        Text(
                          'no_notes_yet'.tr, // ✅ Showing "لا توجد ملاحظات بعد"
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final note = controller.filteredNotes[index];
                      return _buildNoteCard(context, note, index);
                    },
                    childCount: controller.filteredNotes.length,
                  ),
                ),
              );
            }),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, dynamic note, int index) {
    final theme = Theme.of(context);
    final isPinned = note.isPinned ?? false;
    
    return GestureDetector(
      onTap: () => Get.toNamed('/add-note', arguments: note),
      onLongPress: () => _showDeleteDialog(context, note),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isPinned ? AppTheme.primary : theme.dividerColor.withAlpha(10),
            width: isPinned ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isPinned)
                  const Icon(CupertinoIcons.pin_fill, color: AppTheme.primary, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                note.content ?? '',
                style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color, height: 1.5),
                overflow: TextOverflow.fade,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.yMMMd(Get.locale?.languageCode).format(note.updatedAt ?? note.createdAt),
                  style: TextStyle(fontSize: 11, color: theme.dividerColor),
                ),
                GestureDetector(
                  onTap: () => controller.togglePin(note),
                  child: Icon(
                    isPinned ? CupertinoIcons.pin_fill : CupertinoIcons.pin,
                    size: 14,
                    color: isPinned ? AppTheme.primary : theme.dividerColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate(delay: (50 * index).ms).fadeIn().scale(),
    );
  }

  void _showDeleteDialog(BuildContext context, dynamic note) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('delete'.tr),
        content: Text('delete_confirmation'.tr),
        actions: [
          CupertinoDialogAction(child: Text('cancel'.tr), onPressed: () => Get.back()),
          CupertinoDialogAction(isDestructiveAction: true, child: Text('delete'.tr), onPressed: () {
            controller.deleteNote(note.id);
            Get.back();
          }),
        ],
      ),
    );
  }
}
