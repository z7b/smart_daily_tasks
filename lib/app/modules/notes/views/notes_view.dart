import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';

import '../../../data/models/note_model.dart';
import '../controllers/notes_controller.dart';
import '../../../core/helpers/number_extension.dart';

class NotesView extends GetView<NotesController> {
  const NotesView({super.key});

  // Note accent colors (mapped from model's `color` index)
  static const _noteColors = [
    Color(0xFF007AFF), // 0 Blue
    Color(0xFFFF2D55), // 1 Pink
    Color(0xFFFF9500), // 2 Orange
    Color(0xFF34C759), // 3 Green
    Color(0xFFAF52DE), // 4 Purple
  ];

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
                  'notes'.tr,
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
                  onPressed: () => Get.toNamed('/add-note'),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // ── Search bar (same standard as Tasks) ──
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: CupertinoSearchTextField(
                  placeholder: 'search_notes'.tr,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  onChanged: controller.searchNotes,
                ),
              ),
            ),

            // ── Smart summary strip ──
            SliverToBoxAdapter(
              child: Obx(() {
                final total = controller.filteredNotes.length;
                if (total == 0) return const SizedBox.shrink();
                final pinned =
                    controller.filteredNotes.where((n) => n.isPinned).length;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      _miniChip(
                           icon: CupertinoIcons.doc_text,
                          label: total.f,
                          color: AppTheme.primary),
                      if (pinned > 0) ...[
                        const SizedBox(width: 8),
                        _miniChip(
                            icon: CupertinoIcons.pin_fill,
                            label: pinned.f,
                            color: const Color(0xFFFF9500)),
                      ],
                    ],
                  ),
                );
              }),
            ),

            // ── Notes grid ──
            Obx(() {
              if (controller.filteredNotes.isEmpty) {
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
                          child: Icon(CupertinoIcons.doc_text,
                              size: 56, color: AppTheme.primary.withAlpha(80)),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'no_notes_yet'.tr,
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
                    childAspectRatio: 0.88,
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

  // ─── Note Card ────────────────────────────────────────────────
  Widget _buildNoteCard(BuildContext context, Note note, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _noteColors[(note.color ?? 0).clamp(0, _noteColors.length - 1)];
    final now = DateTime.now();
    final noteDate = note.updatedAt ?? note.createdAt;
    final ageDays = now.difference(noteDate).inDays;

    return GestureDetector(
      onTap: () => Get.toNamed('/add-note', arguments: note),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showNoteOptions(context, note);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? theme.cardColor.withAlpha(180)
              : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: note.isPinned
                ? accent.withAlpha(80)
                : theme.dividerColor.withAlpha(15),
            width: note.isPinned ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 18 : 5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Left accent stripe
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(22)),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            note.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.titleLarge?.color,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (note.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, top: 2),
                            child: Icon(CupertinoIcons.pin_fill,
                                color: accent, size: 14),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Content preview
                    Expanded(
                      child: Text(
                        note.content ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodySmall?.color,
                          height: 1.5,
                        ),
                        overflow: TextOverflow.fade,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Footer
                    Row(
                      children: [
                        // Age indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withAlpha(12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _ageLabel(ageDays),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                        ),
                        const Spacer(),

                        // Date
                        Text(
                          DateFormat.MMMd(Get.locale?.languageCode)
                              .format(noteDate),
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.textTheme.bodySmall?.color
                                ?.withAlpha(120),
                          ),
                        ),

                        // Pin toggle
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            controller.togglePin(note);
                          },
                          child: Icon(
                            note.isPinned
                                ? CupertinoIcons.pin_fill
                                : CupertinoIcons.pin,
                            size: 14,
                            color: note.isPinned
                                ? accent
                                : theme.dividerColor,
                          ),
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
    )
        .animate(delay: Duration(milliseconds: 50 * index))
        .fadeIn(duration: const Duration(milliseconds: 300))
        .scale(begin: const Offset(0.97, 0.97));
  }

  // ─── Age label ────────────────────────────────────────────────
  String _ageLabel(int days) {
    if (days == 0) return 'today'.tr;
    if (days <= 3) return 'recent'.tr;
    if (days <= 14) return '${days.f}d';
    return DateFormat.MMMd(Get.locale?.languageCode)
        .format(DateTime.now().subtract(Duration(days: days)));
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

  // ─── Long-press options ───────────────────────────────────────
  void _showNoteOptions(BuildContext context, Note note) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(note.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              Get.toNamed('/add-note', arguments: note);
            },
            child: Text('edit'.tr),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              controller.togglePin(note);
            },
            child: Text(
                note.isPinned ? 'unpin'.tr : 'pin'.tr),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Get.back();
              _confirmDelete(context, note);
            },
            child: Text('delete'.tr),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Get.back(),
          child: Text('cancel'.tr),
        ),
      ),
    );
  }

  // ─── Delete confirmation ──────────────────────────────────────
  void _confirmDelete(BuildContext context, Note note) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('delete'.tr),
        content: Text('delete_confirmation'.tr),
        actions: [
          CupertinoDialogAction(
            child: Text('cancel'.tr),
            onPressed: () => Get.back(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('delete'.tr),
            onPressed: () {
              controller.deleteNote(note.id);
              Get.back();
            },
          ),
        ],
      ),
    );
  }
}
