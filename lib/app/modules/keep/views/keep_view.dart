import '../../../core/helpers/number_extension.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/models/keep_note_model.dart';
import '../controllers/keep_controller.dart';
import '../widgets/keep_sticky_card.dart';
import '../widgets/linked_item_card.dart';
import '../views/add_keep_note_view.dart';
import '../../../widgets/ad_banner_widget.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class KeepView extends StatelessWidget {
  const KeepView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<KeepController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Listen to MediaQuery to rebuild when keyboard appears/disappears
    MediaQuery.of(context);
    final keyboardHeight = View.of(context).viewInsets.bottom / View.of(context).devicePixelRatio;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── Header + content ──────────────────────────────────────────
          DragTarget<int>(
            onWillAcceptWithDetails: (details) => true,
            onAcceptWithDetails: (details) {
              ctrl.moveToEnd(details.data);
            },
            builder: (context, candidateData, rejectedData) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(height: MediaQuery.of(context).padding.top),
                  ),
                  SliverAppBar(
                    expandedHeight: 100,
                    floating: true,
                    pinned: false,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    toolbarHeight: 65,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.scaffoldBackgroundColor,
                              theme.scaffoldBackgroundColor.withValues(alpha: 0.85),
                              theme.scaffoldBackgroundColor.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _buildHeader(context, ctrl, isDark),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Obx(() => AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: ctrl.isSelectionMode ? 0.0 : 1.0,
                      child: IgnorePointer(
                        ignoring: ctrl.isSelectionMode,
                        child: _buildSearchBar(context, ctrl, isDark),
                      ),
                    )),
                  ),
                  SliverToBoxAdapter(child: _buildStatsStrip(context, ctrl, isDark)),
                  const SliverToBoxAdapter(
                    child: AdBannerWidget(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                  ),
                  Obx(() {
                    if (ctrl.filteredNotes.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyBoard(context, isDark),
                      );
                    }
                    return _buildSliverStickyGrid(context, ctrl, keyboardHeight);
                  }),
                ],
              );
            },
          ),

          // ── Contextual Action Bar (Glass Floating) ─────────────────────────
          Obx(() {
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              top: ctrl.isSelectionMode ? MediaQuery.of(context).padding.top + 16 : -100,
              left: 16,
              right: 16,
              child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E).withValues(alpha: 0.65) : Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : Colors.black87),
                          onPressed: () => ctrl.clearSelection(),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${ctrl.selectedNoteIds.length}',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.push_pin_rounded, color: isDark ? Colors.white : Colors.black87),
                          onPressed: () => ctrl.pinSelectedNotes(),
                        ),
                        if (_canShowPalette(ctrl))
                          IconButton(
                            icon: Icon(Icons.palette_outlined, color: isDark ? Colors.white : Colors.black87),
                            onPressed: () => _showColorPickerCAB(context, ctrl),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          onPressed: () {
                            Get.dialog(
                              AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Text('delete'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                                content: Text('keep_delete_confirm'.tr, style: const TextStyle(fontSize: 16)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(),
                                    child: Text('cancel'.tr, style: const TextStyle(color: Colors.grey)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      Get.back();
                                      ctrl.deleteSelectedNotes();
                                    },
                                    child: Text('delete'.tr),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                  ),
              ),
            );
          }),

          // ── FAB ────────────────────────────────────────────────────────
          PositionedDirectional(
            bottom: 160,
            end: 20,
            child: _buildFAB(context, ctrl, isDark),
          ),
        ],
      ),
    );
  }

  bool _canShowPalette(KeepController ctrl) {
    if (ctrl.selectedNoteIds.isEmpty) return false;
    for (final note in ctrl.keepNotes) {
      if (!ctrl.selectedNoteIds.contains(note.id)) continue;
      
      if (note.linkedItemType != null) return false;
      if (note.backgroundIndex != null) return false;
    }
    return true;
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, KeepController ctrl, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    final subTextColor = isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF7F8C8D);
    final badgeBgColor = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05);
    final badgeBorderColor = isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1);
    final shadowColor = isDark ? Colors.black45 : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Board title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('📌', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'keep_board_title'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              color: shadowColor,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'keep_board_subtitle'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: subTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Note count badge
          Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: badgeBorderColor,
                ),
              ),
              child: Text(
                '${ctrl.keepNotes.length} ${'keep_notes'.tr}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: const Duration(milliseconds: 400))
    .slideY(begin: -0.1);
  }

  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar(
    BuildContext context,
    KeepController ctrl,
    bool isDark,
  ) {
    final bgColor = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.04);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08);
    final textColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    final hintColor = isDark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF95A5A6);
    final iconColor = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF7F8C8D);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: CupertinoSearchTextField(
              focusNode: ctrl.searchFocusNode,
              onChanged: ctrl.searchNotes,
              placeholder: 'search_notes'.tr,
              style: TextStyle(color: textColor, fontSize: 14),
              placeholderStyle: TextStyle(
                color: hintColor,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                CupertinoIcons.search,
                color: iconColor,
              ),
              suffixIcon: Icon(
                CupertinoIcons.clear_circled_solid,
                color: iconColor,
              ),
              backgroundColor: Colors.transparent,
            ),
            ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 100));
  }

  // ── Stats strip ────────────────────────────────────────────────────────────
  Widget _buildStatsStrip(BuildContext context, KeepController ctrl, bool isDark) {
    return Obx(() {
      final total = ctrl.keepNotes.length;
      final pinned = ctrl.keepNotes.where((n) => n.isPinned).length;
      final checklists = ctrl.keepNotes.where((n) => n.checkItems.isNotEmpty).length;
      final images = ctrl.keepNotes.where((n) => 
          n.attachments.any((a) => a.type == 'image')).length;
      final voices = ctrl.keepNotes.where((n) => 
          n.attachments.any((a) => a.type == 'voice' || a.type == 'audio')).length;
      final drawings = ctrl.keepNotes.where((n) => 
          n.attachments.any((a) => a.type == 'drawing')).length;

      if (total == 0) return const SizedBox.shrink();

      return SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _miniStat(Icons.notes_rounded, total.fc, Colors.lightBlueAccent, isDark),
            const SizedBox(width: 8),
            _miniStat(Icons.push_pin_rounded, pinned.fc, Colors.amber, isDark),
            const SizedBox(width: 8),
            _miniStat(Icons.checklist_rounded, checklists.fc, Colors.lightGreenAccent, isDark),
            const SizedBox(width: 8),
            _miniStat(Icons.image_outlined, images.fc, Colors.purpleAccent, isDark),
            const SizedBox(width: 8),
            _miniStat(Icons.mic_none_rounded, voices.fc, Colors.orangeAccent, isDark),
            const SizedBox(width: 8),
            _miniStat(Icons.draw_outlined, drawings.fc, Colors.pinkAccent, isDark),
          ],
        ),
      );
    });
  }

  Widget _miniStat(IconData icon, String count, Color color, bool isDark) {
    final bgColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.04);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08);
    final textColor = isDark ? Colors.white : const Color(0xFF2C3E50);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? color.withValues(alpha: 0.85) : color.withRed((color.r * 255 * 0.8).toInt()).withGreen((color.g * 255 * 0.8).toInt()).withBlue((color.b * 255 * 0.8).toInt())),
          const SizedBox(width: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Sticky grid (masonry-style) ────────────────────────────────────────────
  Widget _buildSliverStickyGrid(BuildContext context, KeepController ctrl, double keyboardHeight) {
    final notes = ctrl.filteredNotes;
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(8, 8, 8, 400 + keyboardHeight),
      sliver: SliverMasonryGrid.count(
        key: ValueKey(notes.map((e) => '${e.id}_${e.sortOrder}').join('-')),
        crossAxisCount: _crossAxisCount(context),
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        childCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          Widget child;

          if (note.linkedItemType != null) {
            child = LinkedItemCard(
              note: note,
              index: index,
            );
          } else {
            child = KeepStickyCard(
              note: note,
              index: index,
              onTap: () => _openNote(note),
              onDelete: () => ctrl.deleteNote(note.id),
              onTogglePin: () => ctrl.togglePin(note),
              onColorChange: (colorIndex) => ctrl.changeColor(note, colorIndex),
            );
          }

          if (ctrl.searchQuery.value.isNotEmpty) {
            return GestureDetector(
              onLongPress: () {
                HapticFeedback.mediumImpact();
                if (!ctrl.selectedNoteIds.contains(note.id)) {
                  ctrl.toggleSelection(note.id);
                }
              },
              child: child,
            );
          }

          return DragTarget<int>(
            key: ValueKey(note.id),
            onWillAcceptWithDetails: (details) {
              return true;
            },
            onAcceptWithDetails: (details) {
              if (details.data == note.id) return;
              ctrl.reorderNotes(details.data, note.id);
            },
            builder: (context, candidateData, rejectedData) {
              final isHovered = candidateData.isNotEmpty;
              
              return LongPressDraggable<int>(
                data: note.id,
                delay: const Duration(milliseconds: 350),
                onDragStarted: () {
                  HapticFeedback.mediumImpact();
                  if (!ctrl.selectedNoteIds.contains(note.id)) {
                    ctrl.toggleSelection(note.id);
                  }
                },
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    // Estimate width for feedback since it's floating outside grid
                    width: (MediaQuery.of(context).size.width - 48) / _crossAxisCount(context),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: child,
                    ),
                  ),
                ),
                childWhenDragging: child, // Keeps original fully visible to avoid layout spaces
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  transform: isHovered ? Matrix4.diagonal3Values(0.95, 0.95, 1.0) : Matrix4.identity(),
                  transformAlignment: Alignment.center,
                  child: isHovered
                      ? Opacity(opacity: 0.6, child: child)
                      : child,
                ),
              );
            },
          );
        },
      ),
    );
  }

  int _crossAxisCount(BuildContext context) {
    return 2;
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyBoard(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.3);
    final circleColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1);

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.push_pin_outlined,
                size: 44,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'keep_empty_title'.tr,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textColor.withValues(alpha: 0.8),
                shadows: [
                  Shadow(
                    color: isDark ? Colors.black38 : Colors.transparent,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'keep_empty_sub'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 500))
        .scale(begin: const Offset(0.9, 0.9)),
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────
  Widget _buildFAB(BuildContext context, KeepController ctrl, bool isDark) {
    return _KeepFAB(onAddNote: _openAddNote, isDark: isDark);
  }

  void _openNote(KeepNote note) {
    Get.to(
      () => AddKeepNoteView(existingNote: note, viewOnly: true),
      transition: Transition.downToUp,
      duration: const Duration(milliseconds: 350),
    );
  }

  void _openAddNote() {
    Get.to(
      () => const AddKeepNoteView(),
      transition: Transition.downToUp,
      duration: const Duration(milliseconds: 350),
    );
  }
  // ── CAB Color Picker ───────────────────────────────────────────────────────
  void _showColorPickerCAB(BuildContext context, KeepController ctrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final tc = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('color'.tr, style: TextStyle(fontWeight: FontWeight.w700, color: tc, fontSize: 16)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: KeepController.boardColors.length,
                    itemBuilder: (_, i) {
                      final c = KeepController.boardColors[i];
                      return GestureDetector(
                        onTap: () {
                          ctrl.changeColorForSelected(i);
                          Get.back();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── FAB with type picker ───────────────────────────────────────────────────
class _KeepFAB extends StatefulWidget {
  final VoidCallback onAddNote;
  final bool isDark;
  const _KeepFAB({required this.onAddNote, required this.isDark});

  @override
  State<_KeepFAB> createState() => _KeepFABState();
}

class _KeepFABState extends State<_KeepFAB>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animCtrl.forward();
    } else {
      _animCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mini action buttons (expanded)
        ScaleTransition(
          scale: _scaleAnim,
          alignment: isRtl ? Alignment.bottomLeft : Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              end: 4,
              bottom: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _miniFABItem(
                  label: 'keep_text'.tr,
                  icon: Icons.notes_rounded,
                  color: const Color(0xFFFFEB3B),
                  onTap: () {
                    _toggle();
                    final ctrl = Get.find<KeepController>();
                    ctrl.blocks.clear();
                    ctrl.addBlock(KeepNoteType.text, '');
                    widget.onAddNote();
                  },
                ),
                const SizedBox(height: 10),
                _miniFABItem(
                  label: 'keep_list'.tr,
                  icon: Icons.checklist_rounded,
                  color: const Color(0xFFA5D6A7),
                  onTap: () {
                    _toggle();
                    final ctrl = Get.find<KeepController>();
                    ctrl.blocks.clear();
                    ctrl.addBlock(KeepNoteType.checklist, <ChecklistItem>[]);
                    widget.onAddNote();
                  },
                ),
                const SizedBox(height: 10),
                _miniFABItem(
                  label: 'keep_image'.tr,
                  icon: Icons.image_outlined,
                  color: const Color(0xFF90CAF9),
                  onTap: () {
                    _toggle();
                    final ctrl = Get.find<KeepController>();
                    ctrl.blocks.clear();
                    ctrl.addBlock(KeepNoteType.image, '');
                    widget.onAddNote();
                  },
                ),
                const SizedBox(height: 10),
                _miniFABItem(
                  label: 'keep_voice'.tr,
                  icon: Icons.mic_outlined,
                  color: const Color(0xFFFFCC80),
                  onTap: () {
                    _toggle();
                    final ctrl = Get.find<KeepController>();
                    ctrl.blocks.clear();
                    ctrl.addBlock(KeepNoteType.voice, '');
                    widget.onAddNote();
                  },
                ),
                const SizedBox(height: 10),
                _miniFABItem(
                  label: 'keep_draw'.tr,
                  icon: Icons.brush_outlined,
                  color: const Color(0xFFE1BEE7),
                  onTap: () {
                    _toggle();
                    final ctrl = Get.find<KeepController>();
                    ctrl.blocks.clear();
                    ctrl.addBlock(KeepNoteType.drawing, '');
                    widget.onAddNote();
                  },
                ),
              ],
            ),
          ),
        ),

        // Main FAB
        AnimatedBuilder(
          animation: _animCtrl,
          builder: (context, child) {
            final double gradientAlpha = widget.isDark ? 0.6 : 0.85;
            final Color shadowColor = widget.isDark 
                ? Colors.black.withValues(alpha: 0.5) 
                : const Color(0xFF90CAF9).withValues(alpha: 0.35);

            return GestureDetector(
              onTap: _toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: SweepGradient(
                          transform: GradientRotation(_animCtrl.value * 0.5 * 3.1415926535), // Subtle 90 degree shift on click
                          colors: [
                            Color(0xFF90CAF9).withValues(alpha: gradientAlpha), // Blue
                            Color(0xFFA5D6A7).withValues(alpha: gradientAlpha), // Green
                            Color(0xFFFFEB3B).withValues(alpha: gradientAlpha), // Yellow
                            Color(0xFFFFCC80).withValues(alpha: gradientAlpha), // Orange
                            Color(0xFFE1BEE7).withValues(alpha: gradientAlpha), // Purple
                            Color(0xFF90CAF9).withValues(alpha: gradientAlpha), // Blue (to wrap)
                          ],
                        ),
                      ),
                      child: AnimatedRotation(
                        turns: _expanded ? 0.125 : 0,
                        duration: const Duration(milliseconds: 280),
                        child: Icon(
                          Icons.add_rounded,
                          color: widget.isDark ? Colors.white : const Color(0xFF5D4037),
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                );
          },
        ),
      ],
    );
  }

  Widget _miniFABItem({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label pill (leading side)
          Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(width: 10),
          // Icon button (trailing side)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF3E2723), size: 22),
          ),
        ],
      ),
    );
  }
}
