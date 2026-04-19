import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';


import '../../../core/theme/app_theme.dart';
import '../../../data/models/bookmark_model.dart';
import '../controllers/bookmarks_controller.dart';
import '../../../core/helpers/number_extension.dart';

class BookmarksView extends GetView<BookmarksController> {
  const BookmarksView({super.key});

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
                  'bookmarks'.tr,
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
                  onPressed: () => Get.toNamed('/add-bookmark'),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // ── Search bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: CupertinoSearchTextField(
                  placeholder: 'search_bookmarks'.tr,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  onChanged: controller.searchBookmarks,
                ),
              ),
            ),

            // ── Smart strip ──
            SliverToBoxAdapter(
              child: Obx(() {
                final total = controller.bookmarks.length;
                final cats = controller.categories.length;
                if (total == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      _miniChip(
                          icon: CupertinoIcons.bookmark_fill,
                          label: total.f,
                          color: AppTheme.primary),
                      if (cats > 0) ...[
                        const SizedBox(width: 8),
                        _miniChip(
                            icon: CupertinoIcons.folder,
                            label: cats.f,
                            color: const Color(0xFFAF52DE)),
                      ],
                    ],
                  ),
                );
              }),
            ),

            // ── Category filter chips ──
            SliverToBoxAdapter(
              child: Obx(() {
                if (controller.categories.isEmpty) {
                  return const SizedBox.shrink();
                }
                return SizedBox(
                  height: 52,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 6),
                    itemCount: controller.categories.length + 1,
                    itemBuilder: (context, index) {
                      final isAll = index == 0;
                      final cat =
                          isAll ? null : controller.categories[index - 1];
                      final isSelected =
                          controller.selectedCategory.value == cat;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(isAll ? 'all'.tr : cat!),
                          selected: isSelected,
                          onSelected: (_) =>
                              controller.filterByCategory(cat),
                          selectedColor: AppTheme.primary.withAlpha(30),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppTheme.primary
                                : theme.textTheme.bodyMedium?.color,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),

            // ── Bookmark list ──
            Obx(() {
              final bookmarks = controller.filteredBookmarks;
              if (bookmarks.isEmpty) {
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
                          child: Icon(CupertinoIcons.bookmark,
                              size: 56,
                              color: AppTheme.primary.withAlpha(80)),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'no_bookmarks_yet'.tr,
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final bookmark = bookmarks[index];
                      return _buildBookmarkCard(context, bookmark, index);
                    },
                    childCount: bookmarks.length,
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

  // ─── Bookmark Card ────────────────────────────────────────────
  Widget _buildBookmarkCard(BuildContext context, Bookmark bookmark, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final domain = _parseDomain(bookmark.url);

    // Deterministic gradient per domain initial letter
    final gradients = [
      [const Color(0xFF007AFF), const Color(0xFF5AC8FA)],
      [const Color(0xFFFF2D55), const Color(0xFFFF9500)],
      [const Color(0xFF34C759), const Color(0xFF30D158)],
      [const Color(0xFFAF52DE), const Color(0xFF5E5CE6)],
      [const Color(0xFFFF9500), const Color(0xFFFFCC00)],
    ];
    final gradientIndex = domain.isNotEmpty
        ? domain.codeUnitAt(0) % gradients.length
        : 0;
    final gradient = gradients[gradientIndex];

    return Dismissible(
      key: Key('bm_${bookmark.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => controller.deleteBookmark(bookmark.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30).withAlpha(200),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(CupertinoIcons.trash, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => controller.openUrl(bookmark.url),
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showBookmarkOptions(context, bookmark);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor.withAlpha(180) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 20 : 5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Domain icon with gradient
              Container(
                width: 54,
                height: 54,
                margin: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    domain.isNotEmpty
                        ? domain[0].toUpperCase()
                        : '🔗',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),

              // Details
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.only(right: 14, top: 14, bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + category
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              bookmark.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.titleLarge?.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (bookmark.category?.isNotEmpty ?? false) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withAlpha(15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                bookmark.category!,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 3),

                      // Domain (clean display)
                      Text(
                        domain,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary.withAlpha(160),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Description
                      if (bookmark.description != null &&
                          bookmark.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          bookmark.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Tags
                      if (bookmark.tags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          children: bookmark.tags.take(3).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withAlpha(10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#$tag',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Open chevron
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(
                  CupertinoIcons.arrow_up_right_square,
                  size: 18,
                  color: AppTheme.primary.withAlpha(120),
                ),
              ),
            ],
          ),
        ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn(duration: const Duration(milliseconds: 300)).slideX(begin: 0.06),
      ),
    );
  }

  // ─── Domain parser ────────────────────────────────────────────
  String _parseDomain(String url) {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      String host = uri.host;
      if (host.startsWith('www.')) host = host.substring(4);
      return host;
    } catch (_) {
      return url;
    }
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
  void _showBookmarkOptions(BuildContext context, Bookmark bookmark) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(bookmark.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        message: Text(_parseDomain(bookmark.url)),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              controller.openUrl(bookmark.url);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.globe, size: 18),
                const SizedBox(width: 8),
                Text('open'.tr),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              controller.loadBookmarkIntoForm(bookmark);
              Get.toNamed('/add-bookmark', arguments: bookmark);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.pencil, size: 18),
                const SizedBox(width: 8),
                Text('edit'.tr),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Get.back();
              controller.deleteBookmark(bookmark.id);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.trash, size: 18),
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
}
