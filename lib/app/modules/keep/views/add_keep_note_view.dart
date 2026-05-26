import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import '../../../data/models/note_model.dart';
import '../controllers/keep_controller.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class AddKeepNoteView extends StatefulWidget {
  final Note? existingNote;
  const AddKeepNoteView({super.key, this.existingNote});

  @override
  State<AddKeepNoteView> createState() => _AddKeepNoteViewState();
}

class _AddKeepNoteViewState extends State<AddKeepNoteView> with SingleTickerProviderStateMixin {
  late final KeepController _ctrl;
  final Map<String, quill.QuillController> _quillControllers = {};
  
  bool _isAddMenuExpanded = false;
  bool _isFilePickerActive = false;
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

    _ctrl = Get.find<KeepController>();
    if (widget.existingNote != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ctrl.loadNoteIntoForm(widget.existingNote!);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ctrl.selectedColor.value = null;
        _ctrl.selectedBackground.value = null;
        _ctrl.titleController.clear();
        if (_ctrl.blocks.isEmpty) {
          _ctrl.addBlock(KeepNoteType.text, '');
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _quillControllers.values) {
      c.dispose();
    }
    for (final c in _textControllers.values) {
      c.dispose();
    }
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggleAddMenu() {
    setState(() => _isAddMenuExpanded = !_isAddMenuExpanded);
    if (_isAddMenuExpanded) {
      _animCtrl.forward();
    } else {
      _animCtrl.reverse();
    }
  }

  quill.QuillController _getQuillController(String id, String text) {
    if (!_quillControllers.containsKey(id)) {
      quill.Document doc;
      final trimmedText = text.trim();
      bool isLegacyPlaintext = false;
      if (trimmedText.startsWith('[') && trimmedText.endsWith(']')) {
        try {
          final decoded = jsonDecode(text);
          if (decoded is List) {
            doc = quill.Document.fromJson(decoded);
          } else {
            doc = quill.Document()..insert(0, text.isEmpty ? '\n' : '$text\n');
            isLegacyPlaintext = true;
          }
        } catch (_) {
          doc = quill.Document()..insert(0, text.isEmpty ? '\n' : '$text\n');
          isLegacyPlaintext = true;
        }
      } else {
        doc = quill.Document()..insert(0, text.isEmpty ? '\n' : '$text\n');
        isLegacyPlaintext = true;
      }

      final controller = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );

      // Apply legacy global formatting if migrating from plaintext
      if (isLegacyPlaintext && text.isNotEmpty) {
        if (_ctrl.isBold.value) controller.formatText(0, doc.length, quill.Attribute.bold);
        if (_ctrl.isItalic.value) controller.formatText(0, doc.length, quill.Attribute.italic);
        if (_ctrl.isUnderline.value) controller.formatText(0, doc.length, quill.Attribute.underline);
        
        final alignVal = _ctrl.textAlign.value;
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

      controller.addListener(() {
        final index = _ctrl.blocks.indexWhere((b) => b.id == id);
        if (index != -1) {
          final deltaJson = jsonEncode(controller.document.toDelta().toJson());
          _ctrl.blocks[index].data = deltaJson;
        }
      });
      _quillControllers[id] = controller;
    }
    return _quillControllers[id]!;
  }

  quill.QuillController? get _activeQuillController {
    for (final c in _quillControllers.values) {
      if (c.selection.isValid && !c.selection.isCollapsed) {
        return c;
      }
    }
    if (_quillControllers.isNotEmpty) {
      return _quillControllers.values.first;
    }
    return null;
  }
  
  final Map<String, TextEditingController> _textControllers = {};

  TextEditingController _getTextController(String id, String text) {
    if (!_textControllers.containsKey(id)) {
      _textControllers[id] = TextEditingController(text: text);
      _textControllers[id]!.addListener(() {
        // Find if this ID is a checklist item
        final parts = id.split('_');
        if (parts.length >= 2) {
          final blockId = parts.sublist(0, parts.length - 1).join('_');
          final itemIndex = int.tryParse(parts.last);
          if (itemIndex != null) {
            final blockIdx = _ctrl.blocks.indexWhere((b) => b.id == blockId);
            if (blockIdx != -1 && _ctrl.blocks[blockIdx].type == KeepNoteType.checklist) {
              final items = _ctrl.blocks[blockIdx].data as List<ChecklistItem>;
              if (itemIndex < items.length) {
                items[itemIndex].text = _textControllers[id]!.text;
                // No need to trigger deep reactivity on every keystroke
              }
            }
          }
        }
      });
    }
    return _textControllers[id]!;
  }
  
  void _toggleStyle(quill.Attribute attribute, void Function(void Function()) setModalState) {
    final c = _activeQuillController;
    if (c != null) {
      final isApplied = c.getSelectionStyle().containsKey(attribute.key);
      c.skipRequestKeyboard = true;
      c.formatSelection(isApplied ? quill.Attribute.clone(attribute, null) : attribute);
      setModalState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Obx(() {
      final bgColor = _ctrl.getBoardColor(_ctrl.selectedColor.value, isDark);
      final isImageBg = _ctrl.selectedBackground.value != null &&
          _ctrl.selectedBackground.value! >= 0 &&
          _ctrl.selectedBackground.value! < KeepController.backgroundImages.length;
      final customTextColor = _ctrl.getTextColor(_ctrl.selectedTextColor.value);
      final textColor = customTextColor ?? (isImageBg ? Colors.white : _contrastColor(bgColor));

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          await _ctrl.saveNote(existing: widget.existingNote);
        },
        child: Stack(
          children: [
            Container(color: bgColor),
            // Background Image
            if (_ctrl.selectedBackground.value != null &&
                _ctrl.selectedBackground.value! >= 0 &&
                _ctrl.selectedBackground.value! < KeepController.backgroundImages.length)
              Positioned.fill(
                child: Obx(() => ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: _ctrl.backgroundBlur.value, 
                    sigmaY: _ctrl.backgroundBlur.value,
                  ),
                  child: Image.asset(
                    KeepController.backgroundImages[_ctrl.selectedBackground.value!],
                    fit: BoxFit.cover,
                  ),
                )),
              ),
            Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Column(
                  children: [
                    // ── App Bar (Transparent) ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          _buildGlassButton(Icons.arrow_back_ios_new_rounded, isDark, () => _ctrl.saveNote(existing: widget.existingNote)),
                          const Spacer(),
                          _buildGlassButton(
                            _ctrl.isPinned.value ? Icons.push_pin : Icons.push_pin_outlined,
                            isDark,
                            () {
                              _ctrl.isPinned.value = !_ctrl.isPinned.value;
                              HapticFeedback.lightImpact();
                            },
                            color: _ctrl.isPinned.value ? (isDark ? Colors.redAccent : Colors.red) : null,
                          ),
                          const SizedBox(width: 8),
                          Obx(() => _buildGlassButton(
                            _ctrl.reminderAt.value != null ? Icons.notifications_active_rounded : Icons.notifications_none_outlined,
                            isDark,
                            () => _pickReminder(context),
                            color: _ctrl.reminderAt.value != null ? (isDark ? Colors.blueAccent : Colors.blue) : null,
                          )),
                          const SizedBox(width: 8),
                          _buildGlassButton(Icons.archive_outlined, isDark, () {}),
                        ],
                      ),
                    ),

                    // ── Form body ────────────────────────────
                    // ── Form body & Floating Toolbar ─────────────
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  TextField(
                                    controller: _ctrl.titleController,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'title_hint'.tr,
                                      hintStyle: TextStyle(
                                        color: textColor.withValues(alpha: 0.35),
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    maxLines: null,
                                    textInputAction: TextInputAction.next,
                                  ),
                                  
                                  const SizedBox(height: 16),

                                  // Dynamic Blocks
                                  Obx(() => Column(
                                        children: _ctrl.blocks.asMap().entries.map((entry) {
                                          return _buildBlockWrapper(entry.key, entry.value, textColor);
                                        }).toList(),
                                      )),

                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
                          
                          // ── Floating Bottom Toolbar ─────────────────────
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: _buildBottomToolbar(textColor, isDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBlockWrapper(int index, KeepBlock block, Color textColor) {
    Widget content;
    switch (block.type) {
      case KeepNoteType.text:
        content = _buildTextBlock(block, textColor);
        break;
      case KeepNoteType.checklist:
        content = _buildChecklistBlock(block, textColor);
        break;
      case KeepNoteType.image:
        content = _buildImageBlock(index, block, textColor);
        break;
      case KeepNoteType.drawing:
        content = _buildDrawingBlock(index, block, textColor);
        break;
      case KeepNoteType.voice:
        content = _buildVoiceBlock(index, block, textColor);
        break;
    }

    return Padding(
      key: ValueKey(block.id),
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: content),
          IconButton(
            onPressed: () => _ctrl.removeBlock(index),
            icon: Icon(Icons.close_rounded, size: 20, color: textColor.withValues(alpha: 0.3)),
          )
        ],
      ),
    );
  }

  Widget _buildTextBlock(KeepBlock block, Color textColor) {
    final controller = _getQuillController(block.id, block.data as String? ?? '');
    
    return Obx(() => quill.QuillEditor.basic(
      controller: controller,
      config: quill.QuillEditorConfig(
        padding: EdgeInsets.zero,
        placeholder: 'keep_text_hint'.tr,
        customStyleBuilder: (attribute) {
          if (attribute.key == 'size') {
            final double? size = double.tryParse(attribute.value.toString());
            if (size != null) {
              return TextStyle(fontSize: size);
            }
          }
          return const TextStyle();
        },
        customStyles: quill.DefaultStyles(
          paragraph: quill.DefaultTextBlockStyle(
            TextStyle(
              fontSize: _ctrl.textSize.value,
              color: textColor.withValues(alpha: 0.85),
              height: 1.6,
            ),
            const quill.HorizontalSpacing(0, 0),
            const quill.VerticalSpacing(0, 0),
            const quill.VerticalSpacing(0, 0),
            null,
          ),
        ),
      ),
    ));
  }

  Widget _buildChecklistBlock(KeepBlock block, Color textColor) {
    final items = block.data as List<ChecklistItem>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final tc = _getTextController('${block.id}_$i', item.text);
          return Row(
            children: [
              IconButton(
                icon: Icon(
                  item.isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: item.isDone ? textColor.withValues(alpha: 0.4) : textColor.withValues(alpha: 0.7),
                ),
                onPressed: () {
                  item.isDone = !item.isDone;
                  _ctrl.blocks.refresh();
                },
              ),
              Expanded(
                child: TextField(
                  controller: tc,
                  style: TextStyle(
                    fontSize: 15,
                    color: item.isDone ? textColor.withValues(alpha: 0.4) : textColor.withValues(alpha: 0.85),
                    decoration: item.isDone ? TextDecoration.lineThrough : null,
                  ),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  onChanged: (v) {
                    item.text = v;
                    // Don't refresh the whole list to avoid losing focus
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: textColor.withValues(alpha: 0.3)),
                onPressed: () {
                  items.removeAt(i);
                  _ctrl.blocks.refresh();
                },
              ),
            ],
          );
        }),
        TextButton.icon(
          onPressed: () {
            items.add(ChecklistItem(text: ''));
            _ctrl.blocks.refresh();
          },
          icon: Icon(Icons.add_rounded, color: textColor.withValues(alpha: 0.6)),
          label: Text('keep_add_item'.tr, style: TextStyle(color: textColor.withValues(alpha: 0.6))),
        )
      ],
    );
  }

  Widget _buildImageBlock(int index, KeepBlock block, Color textColor) {
    final path = block.data as String? ?? '';
    final file = File(path);
    if (path.isEmpty || !file.existsSync()) {
      return GestureDetector(
        onTap: () async {
          if (_isFilePickerActive) return;
          _isFilePickerActive = true;
          try {
            final result = await FilePicker.platform.pickFiles(type: FileType.image);
            if (result != null && result.files.single.path != null) {
              _ctrl.updateBlockData(index, result.files.single.path!);
            }
          } finally {
            _isFilePickerActive = false;
          }
        },
        child: Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: textColor.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 40, color: textColor.withValues(alpha: 0.3)),
              const SizedBox(height: 8),
              Text('keep_tap_add_image'.tr, style: TextStyle(color: textColor.withValues(alpha: 0.5))),
            ],
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        file,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          height: 150,
          color: Colors.black26,
          child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
        ),
      ),
    );
  }

  Widget _buildDrawingBlock(int index, KeepBlock block, Color textColor) {
    return _DrawingCanvas(
      textColor: textColor,
      initialData: block.data as String? ?? '',
      onDrawingChanged: (data) => _ctrl.updateBlockData(index, data),
    );
  }

  Widget _buildVoiceBlock(int index, KeepBlock block, Color textColor) {
    return _VoiceRecorderWidget(
      textColor: textColor,
      initialPath: block.data as String? ?? '',
      onPathChanged: (path) => _ctrl.updateBlockData(index, path),
    );
  }

  Widget _buildGlassButton(IconData icon, bool isDark, VoidCallback onPressed, {Color? color}) {
    final iconColor = color ?? (isDark ? Colors.white : Colors.black87);
    final bgColor = isDark ? Colors.black54 : Colors.white60;

    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: iconColor.withValues(alpha: 0.15), width: 1.2),
          ),
          child: IconButton(
            icon: Icon(icon, color: iconColor.withValues(alpha: 0.8), size: 22),
            onPressed: onPressed,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ),
      ),
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
          // Icon button (left)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
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
          const SizedBox(width: 10),
          // Label pill (right)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
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
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Toolbar ────────────────────────────────────────────────────────
  Widget _buildBottomToolbar(Color textColor, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mini action buttons (expanded)
        ScaleTransition(
          scale: _scaleAnim,
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _miniFABItem(
                  label: 'keep_image'.tr,
                  icon: Icons.image_outlined,
                  color: const Color(0xFF90CAF9),
                  onTap: () {
                    _toggleAddMenu();
                    _ctrl.addBlock(KeepNoteType.image, '');
                  },
                ),
                const SizedBox(height: 10),
                _miniFABItem(
                  label: 'keep_draw'.tr,
                  icon: Icons.brush_outlined,
                  color: const Color(0xFFE1BEE7),
                  onTap: () {
                    _toggleAddMenu();
                    _ctrl.addBlock(KeepNoteType.drawing, '');
                  },
                ),
                const SizedBox(height: 10),
                _miniFABItem(
                  label: 'keep_voice'.tr,
                  icon: Icons.mic_outlined,
                  color: const Color(0xFFFFCC80),
                  onTap: () {
                    _toggleAddMenu();
                    _ctrl.addBlock(KeepNoteType.voice, '');
                  },
                ),
                const SizedBox(height: 10),
                _miniFABItem(
                  label: 'keep_list'.tr,
                  icon: Icons.checklist_rounded,
                  color: const Color(0xFFA5D6A7),
                  onTap: () {
                    _toggleAddMenu();
                    _ctrl.addBlock(KeepNoteType.checklist, <ChecklistItem>[]);
                  },
                ),
                const SizedBox(height: 10),
                _miniFABItem(
                  label: 'keep_text'.tr,
                  icon: Icons.notes_rounded,
                  color: const Color(0xFFFFEB3B),
                  onTap: () {
                    _toggleAddMenu();
                    _ctrl.addBlock(KeepNoteType.text, '');
                  },
                ),
              ],
            ),
          ),
        ),

        // Bottom toolbar row
        SizedBox(
          height: 56,
          child: Row(
            children: [
              AnimatedRotation(
                turns: _isAddMenuExpanded ? 0.125 : 0,
                duration: const Duration(milliseconds: 280),
                child: _buildGlassButton(Icons.add_rounded, isDark, _toggleAddMenu),
              ),
              const SizedBox(width: 8),
              _buildGlassButton(Icons.palette_outlined, isDark, () => _showPaletteMenu(isDark)),
              const SizedBox(width: 8),
              _buildGlassButton(Icons.text_format_rounded, isDark, () {
                _showFormatMenu(isDark);
              }),
              const Spacer(),
              Text(
                widget.existingNote != null 
                  ? 'Edited ${widget.existingNote!.updatedAt?.toIso8601String().substring(0, 10)}'
                  : 'New Note',
                style: TextStyle(color: (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.5), fontSize: 12),
              ),
              const Spacer(),
              _buildGlassButton(Icons.more_vert_rounded, isDark, () {}),
            ],
          ),
        ),
      ],
    );
  }


  void _showFormatMenu(bool isDark) {
    final uiColor = isDark ? Colors.white : Colors.black87;
    double currentSize = _ctrl.textSize.value;
    final activeC = _activeQuillController;
    if (activeC != null) {
      final sizeAttr = activeC.getSelectionStyle().attributes['size'];
      if (sizeAttr != null && sizeAttr.value != null) {
        currentSize = double.tryParse(sizeAttr.value.toString()) ?? currentSize;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.only(top: 20, bottom: 20, left: 16, right: 16),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('keep_format'.tr, style: TextStyle(fontWeight: FontWeight.bold, color: uiColor)),
                  const SizedBox(height: 24),
                  
                  // Text Alignment
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAlignButton(Icons.format_align_left_rounded, 0, uiColor, setModalState),
                      _buildAlignButton(Icons.format_align_center_rounded, 1, uiColor, setModalState),
                      _buildAlignButton(Icons.format_align_right_rounded, 2, uiColor, setModalState),
                      _buildAlignButton(Icons.format_align_justify_rounded, 3, uiColor, setModalState),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Text Styles (Bold, Italic, Underline)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStyleButton(Icons.format_bold_rounded, quill.Attribute.bold, uiColor, setModalState),
                      _buildStyleButton(Icons.format_italic_rounded, quill.Attribute.italic, uiColor, setModalState),
                      _buildStyleButton(Icons.format_underline_rounded, quill.Attribute.underline, uiColor, setModalState),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  // Font Size Slider
                  Row(
                    children: [
                      Icon(Icons.format_size_rounded, color: uiColor.withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: currentSize,
                          min: 12.0,
                          max: 36.0,
                          divisions: 12,
                          activeColor: uiColor,
                          inactiveColor: uiColor.withValues(alpha: 0.2),
                          onChanged: (val) {
                            setModalState(() {
                              currentSize = val;
                            });
                            if (_activeQuillController != null) {
                              _activeQuillController!.skipRequestKeyboard = true;
                              final attr = quill.Attribute('size', quill.AttributeScope.inline, val.toString());
                              _activeQuillController!.formatSelection(attr);
                            }
                          },
                        ),
                      ),
                      Text('${currentSize.toInt()}', style: TextStyle(color: uiColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Text Colors
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildColorButton(Colors.black, uiColor, setModalState),
                        const SizedBox(width: 12),
                        _buildColorButton(Colors.white, uiColor, setModalState),
                        const SizedBox(width: 12),
                        _buildColorButton(Colors.red, uiColor, setModalState),
                        const SizedBox(width: 12),
                        _buildColorButton(Colors.orange, uiColor, setModalState),
                        const SizedBox(width: 12),
                        _buildColorButton(Colors.green, uiColor, setModalState),
                        const SizedBox(width: 12),
                        _buildColorButton(Colors.blue, uiColor, setModalState),
                        const SizedBox(width: 12),
                        _buildColorButton(Colors.purple, uiColor, setModalState),
                        const SizedBox(width: 12),
                        _buildColorButton(Colors.grey, uiColor, setModalState),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
      },
    );
  }

  Widget _buildAlignButton(IconData icon, int alignValue, Color uiColor, void Function(void Function()) setModalState) {
    final c = _activeQuillController;
    bool isSelected = false;
    
    if (c != null) {
       final alignAttr = c.getSelectionStyle().attributes['align']?.value;
       if (alignValue == 0) {
         isSelected = alignAttr == 'left' || alignAttr == null;
       } else if (alignValue == 1) {
         isSelected = alignAttr == 'center';
       } else if (alignValue == 2) {
         isSelected = alignAttr == 'right';
       } else if (alignValue == 3) {
         isSelected = alignAttr == 'justify';
       }
    } else {
       isSelected = _ctrl.textAlign.value == alignValue;
    }

    return GestureDetector(
      onTap: () {
        if (c != null) {
          quill.Attribute alignAttr;
          if (alignValue == 0) {
            alignAttr = quill.Attribute.leftAlignment;
          } else if (alignValue == 1) {
            alignAttr = quill.Attribute.centerAlignment;
          } else if (alignValue == 2) {
            alignAttr = quill.Attribute.rightAlignment;
          } else {
            alignAttr = quill.Attribute.justifyAlignment;
          }
          c.skipRequestKeyboard = true;
          c.formatSelection(alignAttr);
          
          // Clear any corrupted RTL direction attribute left over from the old buggy implementation.
          // flutter_quill handles RTL paragraph direction natively through the app's Directionality.
          c.skipRequestKeyboard = true;
          c.formatSelection(quill.Attribute.clone(quill.Attribute.rtl, null));
        } else {
          _ctrl.textAlign.value = alignValue;
        }
        setModalState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? uiColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: isSelected ? uiColor : uiColor.withValues(alpha: 0.5)),
      ),
    );
  }

  Widget _buildStyleButton(IconData icon, quill.Attribute attribute, Color uiColor, void Function(void Function()) setModalState) {
    final c = _activeQuillController;
    final isSelected = c?.getSelectionStyle().containsKey(attribute.key) ?? false;
    return GestureDetector(
      onTap: () => _toggleStyle(attribute, setModalState),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? uiColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: isSelected ? uiColor : uiColor.withValues(alpha: 0.5)),
      ),
    );
  }

  Widget _buildColorButton(Color color, Color uiColor, void Function(void Function()) setModalState) {
    final c = _activeQuillController;
    final colorHex = '#${color.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';
    
    bool isSelected = false;
    if (c != null) {
      final colorAttr = c.getSelectionStyle().attributes['color'];
      if (colorAttr != null && colorAttr.value != null) {
        final attrValue = colorAttr.value.toString().toLowerCase();
        final searchHex = colorHex.toLowerCase();
        // flutter_quill might prepend 'ff' or keep it 6 chars
        isSelected = attrValue == searchHex || attrValue == '#ff${searchHex.substring(1)}';
      }
    }

    return GestureDetector(
      onTap: () {
        if (c != null) {
          c.skipRequestKeyboard = true;
          if (isSelected) {
            c.formatSelection(const quill.ColorAttribute(null));
          } else {
            c.formatSelection(quill.ColorAttribute(colorHex));
          }
          setModalState(() {});
        }
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? uiColor : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: uiColor.withValues(alpha: 0.3), blurRadius: 6, spreadRadius: 1)]
              : [],
        ),
      ),
    );
  }

  void _showPaletteMenu(bool isDark) {
    final uiColor = isDark ? Colors.white : Colors.black87;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.only(top: 20, bottom: 10, left: 16, right: 16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('color'.tr, style: TextStyle(fontWeight: FontWeight.bold, color: uiColor)),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: KeepController.boardColors.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return GestureDetector(
                        onTap: () {
                          _ctrl.selectedColor.value = null;
                          Get.back();
                        },
                        child: Obx(() {
                          final isSelected = _ctrl.selectedColor.value == null;
                          return Container(
                            width: 44,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: uiColor.withValues(alpha: 0.3)),
                            ),
                            child: Icon(Icons.block, color: uiColor.withValues(alpha: isSelected ? 0.9 : 0.3)),
                          );
                        }),
                      );
                    }
                    final cIndex = i - 1;
                    final c = KeepController.boardColors[cIndex];
                    return GestureDetector(
                      onTap: () {
                        _ctrl.selectedColor.value = cIndex;
                        _ctrl.selectedBackground.value = null;
                      },
                      child: Obx(() {
                        final isSelected = _ctrl.selectedColor.value == cIndex;
                        return Container(
                          width: 44,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: uiColor, width: 2) : null,
                          ),
                          child: isSelected ? Icon(Icons.check, color: _contrastColor(c)) : null,
                        );
                      }),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text('background'.tr, style: TextStyle(fontWeight: FontWeight.bold, color: uiColor)),
              const SizedBox(height: 12),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: KeepController.backgroundImages.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      // None
                      return GestureDetector(
                        onTap: () {
                          _ctrl.selectedBackground.value = null;
                        },
                        child: Obx(() {
                          final isSelected = _ctrl.selectedBackground.value == null;
                          return Container(
                            width: 60,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: uiColor.withValues(alpha: 0.3)),
                            ),
                            child: Icon(Icons.block, color: uiColor.withValues(alpha: isSelected ? 0.9 : 0.3)),
                          );
                        }),
                      );
                    }
                    final pIndex = i - 1;
                    return GestureDetector(
                      onTap: () {
                        _ctrl.selectedBackground.value = pIndex;
                        _ctrl.selectedColor.value = null;
                      },
                      child: Obx(() {
                        final isSelected = _ctrl.selectedBackground.value == pIndex;
                        return Container(
                          width: 60,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: uiColor.withValues(alpha: isSelected ? 1 : 0.1), width: isSelected ? 2 : 1),
                            image: DecorationImage(
                              image: AssetImage(KeepController.backgroundImages[pIndex]),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                        );
                      }),
                    );
                  },
                ),
              ),
              // Text Color
              const SizedBox(height: 24),
              Text('text_color'.tr, style: TextStyle(fontWeight: FontWeight.bold, color: uiColor)),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: KeepController.textColors.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return GestureDetector(
                        onTap: () {
                          _ctrl.selectedTextColor.value = null;
                        },
                        child: Obx(() {
                          final isSelected = _ctrl.selectedTextColor.value == null;
                          return Container(
                            width: 44,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: uiColor.withValues(alpha: 0.3)),
                            ),
                            child: Icon(Icons.auto_awesome, color: uiColor.withValues(alpha: isSelected ? 0.9 : 0.3)),
                          );
                        }),
                      );
                    }
                    final cIndex = i - 1;
                    final c = KeepController.textColors[cIndex];
                    return GestureDetector(
                      onTap: () {
                        _ctrl.selectedTextColor.value = cIndex;
                      },
                      child: Obx(() {
                        final isSelected = _ctrl.selectedTextColor.value == cIndex;
                        return Container(
                          width: 44,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: uiColor, width: 2) : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          child: isSelected ? Icon(Icons.check, color: _contrastColor(c)) : null,
                        );
                      }),
                    );
                  },
                ),
              ),
              // Blur Slider
              Obx(() {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text('keep_blur'.tr, style: TextStyle(fontWeight: FontWeight.bold, color: uiColor)),
                    Slider(
                      value: _ctrl.backgroundBlur.value,
                      min: 0.0,
                      max: 20.0,
                      activeColor: uiColor,
                      inactiveColor: uiColor.withValues(alpha: 0.2),
                      onChanged: (val) {
                        _ctrl.backgroundBlur.value = val;
                      },
                    ),
                  ],
                );
              }),
            ],
          ),
          ),
        ));
      },
    );
  }



  Future<void> _pickReminder(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Colors.blueAccent : Colors.blue;
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 24),
                  Icon(Icons.notifications_active_rounded, size: 48, color: primary.withValues(alpha: 0.8)),
                  const SizedBox(height: 16),
                  Text('set_reminder'.tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Obx(() {
                    if (_ctrl.reminderAt.value != null) {
                      return Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            title: Text('remove_reminder'.tr, style: const TextStyle(color: Colors.redAccent)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            tileColor: Colors.redAccent.withValues(alpha: 0.1),
                            onTap: () {
                              _ctrl.reminderAt.value = null;
                              Get.back();
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  ListTile(
                    leading: Icon(Icons.access_time_rounded, color: primary),
                    title: Text('pick_date_time'.tr),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: primary.withValues(alpha: 0.1),
                    onTap: () async {
                      Get.back();
                      if (!context.mounted) return;
                      final now = DateTime.now();
                      final initial = _ctrl.reminderAt.value ?? now;
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: initial.isBefore(now) ? now : initial,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365 * 5)),
                      );
                      if (pickedDate != null && context.mounted) {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(initial),
                        );
                        if (pickedTime != null) {
                          _ctrl.reminderAt.value = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _contrastColor(Color bg) {
    return bg.computeLuminance() > 0.5 ? const Color(0xFF3E2723) : Colors.white;
  }
}

// ── Drawing Canvas Widget ─────────────────────────────────────────────────
class _DrawingCanvas extends StatefulWidget {
  final Color textColor;
  final String initialData;
  final Function(String data) onDrawingChanged;

  const _DrawingCanvas({
    required this.textColor,
    this.initialData = '',
    required this.onDrawingChanged,
  });

  @override
  State<_DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<_DrawingCanvas> {
  final List<List<Offset?>> _strokes = [];
  List<Offset?> _currentStroke = [];
  Color _penColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _isEraser = false;

  final List<Color> _palette = [
    Colors.black,
    const Color(0xFF3E2723),
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.amber,
    Colors.green,
    const Color(0xFF007AFF),
    Colors.purple,
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    _deserialize(widget.initialData);
  }

  void _deserialize(String data) {
    if (data.isEmpty) return;
    try {
      final parts = data.split(':');
      if (parts.length >= 3) {
        _penColor = Color(int.parse(parts[0]));
        _strokeWidth = double.parse(parts[1]);
        _strokes.clear();
        final lines = parts[2].split('|');
        for (final line in lines) {
          if (line.isEmpty) continue;
          final coords = line.split(',');
          final stroke = <Offset?>[];
          for (int i = 0; i < coords.length - 1; i += 2) {
            stroke.add(Offset(double.parse(coords[i]), double.parse(coords[i+1])));
          }
          stroke.add(null);
          _strokes.add(stroke);
        }
      }
    } catch (e) {
      debugPrint('Error deserializing drawing: $e');
    }
  }

  String _serialize() {
    if (_strokes.isEmpty) return '';
    final lines = <String>[];
    for (final stroke in _strokes) {
      final points = <String>[];
      for (final p in stroke) {
        if (p != null) {
          points.add('${p.dx.toStringAsFixed(1)},${p.dy.toStringAsFixed(1)}');
        }
      }
      if (points.isNotEmpty) {
        lines.add(points.join(','));
      }
    }
    return '${_penColor.toARGB32()}:$_strokeWidth:${lines.join('|')}';
  }

  @override
  Widget build(BuildContext context) {
    final tc = widget.textColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Canvas
        Container(
          width: double.infinity,
          height: 260,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tc.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: GestureDetector(
              onPanStart: (d) {
                setState(() {
                  _currentStroke = [d.localPosition];
                  _strokes.add(_currentStroke);
                });
              },
              onPanUpdate: (d) {
                setState(() => _currentStroke.add(d.localPosition));
              },
              onPanEnd: (_) {
                setState(() {
                  _currentStroke.add(null);
                  widget.onDrawingChanged(_serialize());
                });
              },
              child: CustomPaint(
                painter: _CanvasPainter(
                  strokes: _strokes,
                  penColor: _isEraser ? Colors.white : _penColor,
                  strokeWidth: _isEraser ? 18 : _strokeWidth,
                ),
                child: _strokes.isEmpty
                    ? Center(
                        child: Text(
                          'keep_draw_hint'.tr,
                          style: TextStyle(
                            color: Colors.grey.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Toolbar
        Row(
          children: [
            // Color palette
            Flexible(
              child: SizedBox(
                height: 32,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemCount: _palette.length,
                itemBuilder: (_, i) {
                  final c = _palette[i];
                  final isSelected = !_isEraser && _penColor == c;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _penColor = c;
                      _isEraser = false;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: isSelected ? 30 : 24,
                      height: isSelected ? 30 : 24,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? tc : Colors.grey.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

            const Spacer(),

            // Eraser
            GestureDetector(
              onTap: () => setState(() => _isEraser = !_isEraser),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _isEraser
                      ? tc.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isEraser
                        ? tc.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Icon(Icons.auto_fix_high_rounded,
                    size: 20, color: tc.withValues(alpha: 0.6)),
              ),
            ),

            const SizedBox(width: 4),

            // Clear
            GestureDetector(
              onTap: () => setState(() {
                _strokes.clear();
                widget.onDrawingChanged('');
              }),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.delete_outline_rounded,
                    size: 20, color: tc.withValues(alpha: 0.5)),
              ),
            ),
          ],
        ),

        // Stroke width slider
        Row(
          children: [
            Icon(Icons.line_weight_rounded,
                size: 16, color: tc.withValues(alpha: 0.4)),
            Expanded(
              child: Slider(
                value: _strokeWidth,
                min: 1,
                max: 12,
                divisions: 11,
                onChanged: (v) => setState(() => _strokeWidth = v),
                activeColor: tc.withValues(alpha: 0.6),
                inactiveColor: tc.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Canvas Painter ──────────────────────────────────────────────────────────
class _CanvasPainter extends CustomPainter {
  final List<List<Offset?>> strokes;
  final Color penColor;
  final double strokeWidth;

  _CanvasPainter({
    required this.strokes,
    required this.penColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = penColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      final path = Path();
      bool first = true;
      for (final point in stroke) {
        if (point == null) {
          first = true;
          continue;
        }
        if (first) {
          path.moveTo(point.dx, point.dy);
          first = false;
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }


  @override
  bool shouldRepaint(_CanvasPainter old) => true;
}

// ── Voice Recorder Widget ──────────────────────────────────────────────────
enum _RecorderState { idle, recording, recorded, playing }

class _VoiceRecorderWidget extends StatefulWidget {
  final Color textColor;
  final String initialPath;
  final ValueChanged<String> onPathChanged;

  const _VoiceRecorderWidget({
    required this.textColor,
    required this.initialPath,
    required this.onPathChanged,
  });

  @override
  State<_VoiceRecorderWidget> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<_VoiceRecorderWidget>
    with TickerProviderStateMixin {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  _RecorderState _state = _RecorderState.idle;
  String _filePath = '';
  int _seconds = 0;
  Timer? _timer;
  late AnimationController _waveCtrl;

  // Animated waveform bar heights
  final _random = Random();
  List<double> _waveBars = List.filled(28, 6.0);

  @override
  void initState() {
    super.initState();
    _filePath = widget.initialPath;
    if (_filePath.isNotEmpty) _state = _RecorderState.recorded;

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        if (_state == _RecorderState.recording) {
          setState(() {
            _waveBars = List.generate(
              28,
              (_) => 6.0 + _random.nextDouble() * 26,
            );
          });
        }
      });

    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _state = _RecorderState.recorded);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveCtrl.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/keep_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(), path: path);
    setState(() {
      _state = _RecorderState.recording;
      _seconds = 0;
      _filePath = path;
      _waveBars = List.filled(28, 6.0);
    });

    // Animate waveform at ~8fps
    _waveCtrl.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stop();
    _timer?.cancel();
    _waveCtrl.stop();
    setState(() {
      _state = _RecorderState.recorded;
      _waveBars = List.filled(28, 6.0);
    });
    widget.onPathChanged(_filePath);
  }

  Future<void> _playRecording() async {
    if (_filePath.isEmpty) return;
    await _player.play(DeviceFileSource(_filePath));
    setState(() => _state = _RecorderState.playing);
  }

  Future<void> _stopPlaying() async {
    await _player.stop();
    setState(() => _state = _RecorderState.recorded);
  }

  void _reRecord() {
    setState(() {
      _state = _RecorderState.idle;
      _filePath = '';
      _seconds = 0;
    });
    widget.onPathChanged('');
  }

  String _formatTime(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final tc = widget.textColor;
    final isRecording = _state == _RecorderState.recording;
    final isRecorded = _state == _RecorderState.recorded;
    final isPlaying = _state == _RecorderState.playing;

    return Column(
      children: [
        const SizedBox(height: 16),

        // ── Waveform ───────────────────────────────────────────────
        SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(28, (i) {
              double h = 6.0;
              if (isRecording) h = _waveBars[i];
              if (isRecorded || isPlaying) {
                const fixed = [
                  8.0, 18.0, 12.0, 26.0, 10.0, 22.0, 8.0, 30.0, 14.0, 20.0,
                  8.0, 28.0, 12.0, 18.0, 10.0, 24.0, 16.0, 8.0, 22.0, 12.0,
                  28.0, 10.0, 20.0, 8.0, 16.0, 24.0, 10.0, 8.0,
                ];
                h = fixed[i];
              }
              return AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 4,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: isRecording
                      ? Colors.redAccent.withValues(alpha: 0.8)
                      : isPlaying
                          ? tc.withValues(alpha: 0.7)
                          : tc.withValues(alpha: isRecorded ? 0.45 : 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 20),

        // ── Timer ─────────────────────────────────────────────────
        if (isRecording || isRecorded || isPlaying)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _formatTime(_seconds),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isRecording ? Colors.redAccent : tc.withValues(alpha: 0.7),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),

        // ── Main Button ───────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Re-record button (only when recorded/playing)
            if (isRecorded || isPlaying) ...[
              GestureDetector(
                onTap: _reRecord,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tc.withValues(alpha: 0.08),
                    border: Border.all(color: tc.withValues(alpha: 0.2)),
                  ),
                  child: Icon(Icons.refresh_rounded,
                      size: 20, color: tc.withValues(alpha: 0.55)),
                ),
              ),
              const SizedBox(width: 20),
            ],

            // Main record / stop / play button
            GestureDetector(
              onTap: () {
                if (_state == _RecorderState.idle) _startRecording();
                if (_state == _RecorderState.recording) _stopRecording();
                if (_state == _RecorderState.recorded) _playRecording();
                if (_state == _RecorderState.playing) _stopPlaying();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isRecording ? 72 : 80,
                height: isRecording ? 72 : 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRecording
                      ? Colors.redAccent
                      : isPlaying
                          ? tc.withValues(alpha: 0.25)
                          : tc.withValues(alpha: 0.1),
                  border: Border.all(
                    color: isRecording
                        ? Colors.redAccent
                        : tc.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: isRecording
                      ? [
                          BoxShadow(
                            color: Colors.redAccent.withValues(alpha: 0.4),
                            blurRadius: 18,
                            spreadRadius: 4,
                          )
                        ]
                      : [],
                ),
                child: Icon(
                  isRecording
                      ? Icons.stop_rounded
                      : isRecorded || isPlaying
                          ? (isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded)
                          : Icons.mic_rounded,
                  size: isRecording ? 32 : 38,
                  color: isRecording
                      ? Colors.white
                      : tc.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Label ──────────────────────────────────────────────────
        Text(
          isRecording
              ? 'keep_recording'.tr
              : isRecorded
                  ? 'keep_tap_play'.tr
                  : isPlaying
                      ? 'keep_playing'.tr
                      : 'keep_tap_record'.tr,
          style: TextStyle(
            fontSize: 13,
            color: isRecording
                ? Colors.redAccent
                : tc.withValues(alpha: 0.45),
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

