import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../../data/models/keep_note_model.dart';
import '../controllers/keep_controller.dart';

class KeepStickyCard extends StatelessWidget {
  // All possible saved 'untitled' strings from any language
  static const _untitledValues = {
    'بدون عنوان', 'Untitled', 'Sin título', 'Sans titre',
    'Без названия', '無標題', '无标题', 'शीर्षकहीन',
  };

  static bool _isUntitled(String title) =>
      title.isEmpty || _untitledValues.contains(title) || title == 'keep_untitled'.tr;
  final KeepNote note;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;
  final Function(int colorIndex) onColorChange;

  const KeepStickyCard({
    super.key,
    required this.note,
    required this.index,
    required this.onTap,
    required this.onDelete,
    required this.onTogglePin,
    required this.onColorChange,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<KeepController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = ctrl.getBoardColor(note.colorIndex, isDark);
    final noteData = KeepController.noteToData(note);
    
    final isImageBg = note.backgroundIndex != null && 
        note.backgroundIndex! >= 0 && 
        note.backgroundIndex! < KeepController.backgroundImages.length;
    final customTextColor = ctrl.getTextColor(note.textColorIndex);
    final textColor = customTextColor ?? (isImageBg ? Colors.white : _contrastColor(bgColor));
    final blocks = noteData.blocks;
    final hasHeroImage = blocks.isNotEmpty && blocks.first.type == KeepNoteType.image;
    final heroBlock = hasHeroImage ? blocks.first : null;
    final contentBlocks = hasHeroImage ? blocks.skip(1).toList() : blocks;

    return Obx(() {
      final isSelected = ctrl.selectedNoteIds.contains(note.id);
      final bool isVisualOnly = _isUntitled(note.title) && contentBlocks.isEmpty && (heroBlock != null || isImageBg);
      
      return GestureDetector(
        onTap: () {
          if (ctrl.isSelectionMode) {
            ctrl.toggleSelection(note.id);
          } else {
            onTap();
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
              // ── Card body ─────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(4),
                  border: isSelected 
                      ? Border.all(color: Colors.blueAccent, width: 2) 
                      : Border.all(color: Colors.transparent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(2, 4),
                    ),
                    // Inner lighter shadow for depth
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      blurRadius: 1,
                      offset: const Offset(-1, -1),
                    ),
                  ],
                ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    // Watermark background
                    if (noteData.backgroundIndex != null && 
                        noteData.backgroundIndex! >= 0 && 
                        noteData.backgroundIndex! < KeepController.backgroundImages.length)
                      Positioned.fill(
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: noteData.backgroundBlur ?? 0.0,
                            sigmaY: noteData.backgroundBlur ?? 0.0,
                          ),
                          child: Image.asset(
                            KeepController.backgroundImages[noteData.backgroundIndex!],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (heroBlock != null)
                          _buildHeroImage(heroBlock, textColor),



                        // Content
                        if (!isVisualOnly)
                          Padding(
                            padding: EdgeInsets.fromLTRB(12, 16, 12, noteData.reminderAt != null ? 34 : 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min, // Masonry grid relies on dynamic height
                            children: [
                              // Title
                              if (!_isUntitled(note.title))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    note.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                      height: 1.3,
                                    ),
                                  ),
                                ),

                              // Blocks Preview
                              if (contentBlocks.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ...contentBlocks.take(3).map((b) => _buildPreview(context, b, textColor, noteData)),
                                    if (contentBlocks.length > 3)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Icon(Icons.more_horiz, color: textColor.withValues(alpha: 0.5), size: 16),
                                      ),
                                  ],
                                )
                              else if (heroBlock == null)
                                _emptyHint(textColor),

                              const SizedBox(height: 4),
                            ],
                          ),
                        )
                        else if (heroBlock == null && isImageBg)
                          const SizedBox(height: 120, width: double.infinity),
                      ],
                    ),


                  ],
                ),
              ),
            ),

            // ── Pin ────────────────────────────────────────
            Positioned(
              top: 6,
              left: 0,
              right: 0,
              child: Center(
                child: _PinWidget(isPinned: note.isPinned),
              ),
            ),

            // ── Pinned badge ───────────────────────────────
            if (note.isPinned)
              Positioned(
                top: 8,
                right: 6,
                child: Icon(
                  Icons.push_pin,
                  size: 12,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ),

            // ── Reminder Badge ───────────────────────────────
            if (noteData.reminderAt != null)
              Positioned(
                bottom: 8,
                left: 8,
                child: _buildReminderBadge(noteData.reminderAt!, isDark),
              ),
            ],
          ),
        );
    });
  }

  Widget _buildReminderBadge(DateTime reminderAt, bool isDark) {
    final now = DateTime.now();
    final isActive = reminderAt.isAfter(now);
    
    // ✅ Calendar-day diff (midnight-to-midnight) — NOT Duration.inDays
    // Duration.inDays truncates partial days (e.g. 6d 19h → 6, but also 5d 2h → 5)
    // Calendar diff: "next Monday 8am" set on "Tuesday 1pm" = 6 calendar days, always.
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final reminderMidnight = DateTime(reminderAt.year, reminderAt.month, reminderAt.day);
    final calendarDays = reminderMidnight.difference(todayMidnight).inDays;
    
    // For hours/minutes we still use real duration (only when same day)
    final realDiff = isActive ? reminderAt.difference(now) : now.difference(reminderAt);
    
    String timeText;
    if (!isActive) {
      timeText = 'remind_expired'.tr;
    } else if (calendarDays >= 7) {
      final weeks = calendarDays ~/ 7;
      final remaining = calendarDays % 7;
      timeText = remaining > 0
          ? 'remind_in_weeks_days'.trParams({'weeks': '$weeks', 'days': '$remaining'})
          : 'remind_in_weeks'.trParams({'weeks': '$weeks'});
    } else if (calendarDays > 0) {
      timeText = 'remind_in_days'.trParams({'days': '$calendarDays'});
    } else if (realDiff.inHours > 0) {
      timeText = 'remind_in_hours'.trParams({'hours': '${realDiff.inHours}'});
    } else if (realDiff.inMinutes > 0) {
      timeText = 'remind_in_minutes'.trParams({'minutes': '${realDiff.inMinutes}'});
    } else {
      timeText = 'remind_now'.tr;
    }

    final color = isActive ? Colors.blueAccent : (isDark ? Colors.grey.shade400 : Colors.grey.shade600);
    final bgColor = isDark ? Colors.black.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.5);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.notifications_active_rounded : Icons.notifications_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            timeText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(KeepBlock block, Color textColor) {
    final content = block.data as String?;
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    final file = File(content);
    if (!file.existsSync()) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(4),
        topRight: Radius.circular(4),
      ),
      child: Image.file(
        file,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, KeepBlock block, Color textColor, KeepNoteData noteData) {
    switch (block.type) {
      case KeepNoteType.checklist:
        final items = block.data as List<ChecklistItem>;
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: items.take(3).map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Icon(
                      item.isDone
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 13,
                      color: item.isDone
                          ? textColor.withValues(alpha: 0.5)
                          : textColor.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        item.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: item.isDone
                              ? textColor.withValues(alpha: 0.4)
                              : textColor.withValues(alpha: 0.8),
                          decoration:
                              item.isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );

      case KeepNoteType.image:
        final content = block.data as String?;
        if (content == null || content.isEmpty) return const SizedBox.shrink();
        final file = File(content);
        if (!file.existsSync()) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _emptyHint(textColor),
              ),
            ),
          ),
        );

      case KeepNoteType.drawing:
        final content = block.data as String?;
        if (content == null || content.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxWidth * 0.8), // Maintain aspect ratio roughly
                painter: _MiniCanvasPainter(content),
              );
            },
          ),
        );

      case KeepNoteType.voice:
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(Icons.mic_rounded, size: 20, color: textColor.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case KeepNoteType.text:
        final content = block.data as String?;
        if (content == null || content.isEmpty) return const SizedBox.shrink();
        
        quill.Document doc;
        final trimmedContent = content.trim();
        bool isLegacyPlaintext = false;
        if (trimmedContent.startsWith('[') && trimmedContent.endsWith(']')) {
          try {
            final decoded = jsonDecode(content);
            if (decoded is List) {
              doc = quill.Document.fromJson(decoded);
            } else {
              doc = quill.Document()..insert(0, content.isEmpty ? '\n' : '$content\n');
              isLegacyPlaintext = true;
            }
          } catch (_) {
            doc = quill.Document()..insert(0, content.isEmpty ? '\n' : '$content\n');
            isLegacyPlaintext = true;
          }
        } else {
          doc = quill.Document()..insert(0, content.isEmpty ? '\n' : '$content\n');
          isLegacyPlaintext = true;
        }

        final controller = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: true,
        );

        if (isLegacyPlaintext && content.isNotEmpty) {
          if (noteData.isBold == true) controller.formatText(0, doc.length, quill.Attribute.bold);
          if (noteData.isItalic == true) controller.formatText(0, doc.length, quill.Attribute.italic);
          if (noteData.isUnderline == true) controller.formatText(0, doc.length, quill.Attribute.underline);
          
          final alignVal = noteData.textAlign ?? 0;
          quill.Attribute alignAttr;
          if (alignVal == 0) {
            alignAttr = quill.Attribute.leftAlignment;
          } else if (alignVal == 1) {
            alignAttr = quill.Attribute.centerAlignment;
          } else if (alignVal == 2) {
            alignAttr = quill.Attribute.rightAlignment;
          } else {
            alignAttr = quill.Attribute.justifyAlignment;
          }
          controller.formatText(0, doc.length, alignAttr);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.white.withValues(alpha: 0.0)],
                stops: const [0.75, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: IgnorePointer(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: quill.QuillEditor.basic(
                  controller: controller,
                  config: quill.QuillEditorConfig(
                    padding: EdgeInsets.zero,
                    customStyleBuilder: (attribute) {
                      if (attribute.key == 'size') {
                        final double? size = double.tryParse(attribute.value.toString());
                        if (size != null) {
                          return TextStyle(fontSize: size * 0.85); // Scale down for card view
                        }
                      }
                      return const TextStyle();
                    },
                    customStyles: quill.DefaultStyles(
                      paragraph: quill.DefaultTextBlockStyle(
                        TextStyle(
                          fontSize: (noteData.textSize ?? 16.0) * 0.85,
                          color: textColor.withValues(alpha: 0.75),
                          height: 1.4,
                        ),
                        const quill.HorizontalSpacing(0, 0),
                        const quill.VerticalSpacing(0, 0),
                        const quill.VerticalSpacing(0, 0),
                        null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
    }
  }

  Widget _emptyHint(Color textColor) {
    return Text(
      'keep_empty_note'.tr,
      style: TextStyle(
        fontSize: 13,
        color: textColor.withValues(alpha: 0.4),
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Color _contrastColor(Color bg) {
    return bg.computeLuminance() > 0.5
        ? const Color(0xFF3E2723)
        : Colors.white;
  }

}

class _PinWidget extends StatelessWidget {
  final bool isPinned;
  const _PinWidget({required this.isPinned});

  @override
  Widget build(BuildContext context) {
    if (!isPinned) return const SizedBox.shrink();
    
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.redAccent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ── Mini Canvas Painter for drawing preview ────────────────────────────────
class _MiniCanvasPainter extends CustomPainter {
  final String data;
  _MiniCanvasPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    try {
      final parts = data.split(':');
      if (parts.length < 3) return;
      
      final penColor = Color(int.parse(parts[0]));
      final strokeWidth = double.parse(parts[1]);
      
      final paint = Paint()
        ..color = penColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth * 0.4 // scale down for preview
        ..style = PaintingStyle.stroke;
        
      final lines = parts[2].split('|');
      
      // The original canvas width is likely ~320-360, height 260
      final scaleX = size.width / 320.0;
      final scaleY = size.height / 260.0;
      final scale = min(scaleX, scaleY);
      
      canvas.scale(scale, scale);

      for (final line in lines) {
        if (line.isEmpty) continue;
        
        List<String> coords;
        Paint strokePaint = paint;
        
        if (line.contains(';')) {
          final strokeParts = line.split(';');
          if (strokeParts.length >= 3) {
            strokePaint = Paint()
              ..color = Color(int.parse(strokeParts[0]))
              ..strokeCap = StrokeCap.round
              ..strokeWidth = double.parse(strokeParts[1]) * 0.4
              ..style = PaintingStyle.stroke;
            coords = strokeParts[2].split(',');
          } else {
            coords = line.split(',');
          }
        } else {
          coords = line.split(',');
        }
        
        if (coords.length < 4) continue;
        
        for (int i = 0; i < coords.length - 3; i += 2) {
          final p1 = Offset(double.parse(coords[i]), double.parse(coords[i+1]));
          final p2 = Offset(double.parse(coords[i+2]), double.parse(coords[i+3]));
          canvas.drawLine(p1, p2, strokePaint);
        }
      }
    } catch (_) {}
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
