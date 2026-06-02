import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/helpers/log_helper.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/models/keep_note_model.dart';
import '../../../data/providers/keep_repository.dart';

/// Note types supported in the Keep bulletin board
enum KeepNoteType { text, checklist, image, drawing, voice }

/// Checklist item model (for UI form state only — DB uses KeepCheckItem)
class ChecklistItem {
  String text;
  bool isDone;
  ChecklistItem({required this.text, this.isDone = false});

  factory ChecklistItem.fromLine(String line) {
    final done = line.startsWith('[x] ');
    final text = line.startsWith('[x] ') ? line.substring(4) : (line.startsWith('[ ] ') ? line.substring(4) : line);
    return ChecklistItem(text: text, isDone: done);
  }

  String toLine() => isDone ? '[x] $text' : '[ ] $text';

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      text: json['text'] as String? ?? '',
      isDone: json['isDone'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'isDone': isDone,
      };
}

class KeepBlock {
  final String id;
  KeepNoteType type;
  dynamic data; // String for text/image/drawing/voice, List<ChecklistItem> for checklist

  KeepBlock({String? id, required this.type, required this.data}) : id = id ?? UniqueKey().toString();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'data': type == KeepNoteType.checklist
          ? (data as List<ChecklistItem>).map((e) => e.toJson()).toList()
          : data,
    };
  }

  factory KeepBlock.fromJson(Map<String, dynamic> json) {
    final type = KeepNoteType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => KeepNoteType.text);
    dynamic data = json['data'];

    if (type == KeepNoteType.checklist) {
      if (data is List) {
        data = data
            .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        data = <ChecklistItem>[];
      }
    }

    return KeepBlock(id: json['id'] as String?, type: type, data: data);
  }
}

class KeepNoteData {
  final List<KeepBlock> blocks;
  final int? backgroundIndex;
  final double? backgroundBlur;

  final int? textAlign;
  final double? textSize;
  final bool? isBold;
  final bool? isItalic;
  final bool? isUnderline;
  final int? textColorIndex;
  final DateTime? reminderAt;

  KeepNoteData({
    required this.blocks,
    this.backgroundIndex,
    this.backgroundBlur,
    this.textAlign,
    this.textSize,
    this.isBold,
    this.isItalic,
    this.isUnderline,
    this.textColorIndex,
    this.reminderAt,
  });

  factory KeepNoteData.fromJson(Map<String, dynamic> json) {
    return KeepNoteData(
      blocks: (json['blocks'] as List?)
              ?.map((e) => KeepBlock.fromJson(e))
              .toList() ??
          [],
      backgroundIndex: json['backgroundIndex'] as int?,
      backgroundBlur: (json['backgroundBlur'] as num?)?.toDouble(),
      textAlign: json['textAlign'] as int?,
      textSize: (json['textSize'] as num?)?.toDouble(),
      isBold: json['isBold'] as bool?,
      isItalic: json['isItalic'] as bool?,
      isUnderline: json['isUnderline'] as bool?,
      textColorIndex: json['textColorIndex'] as int?,
      reminderAt: json['reminderAt'] != null ? DateTime.tryParse(json['reminderAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'blocks': blocks.map((e) => e.toJson()).toList(),
        'backgroundIndex': backgroundIndex,
        'backgroundBlur': backgroundBlur,
        'textAlign': textAlign,
        'textSize': textSize,
        'isBold': isBold,
        'isItalic': isItalic,
        'isUnderline': isUnderline,
        'textColorIndex': textColorIndex,
        if (reminderAt != null) 'reminderAt': reminderAt!.toIso8601String(),
      };
}

class KeepController extends GetxController {
  final KeepRepository _repository;
  KeepController(this._repository);

  // State
  final keepNotes = <KeepNote>[].obs;
  final filteredNotes = <KeepNote>[].obs;
  final searchQuery = ''.obs;
  final isLoading = false.obs;

  // Selection Mode State
  final selectedNoteIds = <int>{}.obs;
  bool get isSelectionMode => selectedNoteIds.isNotEmpty;

  void toggleSelection(int noteId) {
    if (selectedNoteIds.contains(noteId)) {
      selectedNoteIds.remove(noteId);
    } else {
      selectedNoteIds.add(noteId);
    }
  }

  void clearSelection() {
    selectedNoteIds.clear();
  }

  Future<void> deleteSelectedNotes() async {
    await _repository.deleteMultiple(selectedNoteIds.toList());
    clearSelection();
  }

  Future<void> pinSelectedNotes() async {
    bool allPinned = true;
    final selectedNotes = keepNotes.where((n) => selectedNoteIds.contains(n.id));
    for (final n in selectedNotes) {
      if (!n.isPinned) {
        allPinned = false;
        break;
      }
    }
    for (final n in selectedNotes) {
      final updated = n.copyWith(isPinned: !allPinned);
      await _repository.putNote(updated);
    }
    clearSelection();
  }

  Future<void> changeColorForSelected(int? colorIndex) async {
    final selectedNotes = keepNotes.where((n) => selectedNoteIds.contains(n.id));
    for (final n in selectedNotes) {
      final updated = n.copyWith(colorIndex: colorIndex);
      await _repository.putNote(updated);
    }
    clearSelection();
  }

  // Add/Edit form state
  final searchFocusNode = FocusNode();
  final titleController = TextEditingController();
  final blocks = <KeepBlock>[].obs;
  final selectedColor = Rx<int?>(null);
  final selectedBackground = Rx<int?>(null);
  final backgroundBlur = 0.0.obs;
  final textAlign = 0.obs;
  final textSize = 16.0.obs;
  final isBold = false.obs;
  final isItalic = false.obs;
  final isUnderline = false.obs;
  final selectedTextColor = Rx<int?>(null);
  final isPinned = false.obs;
  final reminderAt = Rx<DateTime?>(null);

  StreamSubscription? _notesSub;

  // Keep note colors - warm sticky note palette
  static const List<Color> boardColors = [
    Color(0xFFFFEB3B), // Yellow (classic)
    Color(0xFF80DEEA), // Cyan
    Color(0xFFA5D6A7), // Green
    Color(0xFFFFCC80), // Orange
    Color(0xFFCE93D8), // Purple
    Color(0xFFF48FB1), // Pink
    Color(0xFF90CAF9), // Blue
    Color(0xFFFFCDD2), // Red
    Color(0xFFDCEDC8), // Lime
    Color(0xFFB0BEC5), // Grey
    Color(0xFF80CBC4), // Teal
    Color(0xFF9FA8DA), // Indigo
    Color(0xFFBCAAA4), // Brown
    Color(0xFFFFAB91), // DeepOrange
    Color(0xFFFFE082), // Amber
    Color(0xFFB39DDB), // DeepPurple
  ];

  static const List<Color> textColors = [
    Colors.black,
    Colors.white,
    Color(0xFFFFEB3B), // Yellow (classic)
    Color(0xFF80DEEA), // Cyan
    Color(0xFFA5D6A7), // Green
    Color(0xFFFFCC80), // Orange
    Color(0xFFCE93D8), // Purple
    Color(0xFFF48FB1), // Pink
    Color(0xFF90CAF9), // Blue
    Color(0xFFFFCDD2), // Red
    Color(0xFFDCEDC8), // Lime
    Color(0xFFB0BEC5), // Grey
    Color(0xFF80CBC4), // Teal
    Color(0xFF9FA8DA), // Indigo
    Color(0xFFBCAAA4), // Brown
    Color(0xFFFFAB91), // DeepOrange
    Color(0xFFFFE082), // Amber
    Color(0xFFB39DDB), // DeepPurple
  ];

  static const List<String> backgroundImages = [
    'assets/images/Background_notes/dominikakukulka-cat.jpg',
    'assets/images/Background_notes/impermanent-forest.jpg',
    'assets/images/Background_notes/impermanent-samurai.jpg',
    'assets/images/Background_notes/jaron-photoA.jpg',
    'assets/images/Background_notes/kanenori-starry-skyA.jpg',
    'assets/images/Background_notes/miezekieze-cat.jpg',
    'assets/images/Background_notes/mohann-bird.jpg',
    'assets/images/Background_notes/nitrogeniumn-planets.jpg',
    'assets/images/Background_notes/rickietomschunemann-building.jpg',
    'assets/images/Background_notes/rickietomschunemann-mountains.jpg',
    'assets/images/Background_notes/rickietomschunemannMountains.jpg',
    'assets/images/Background_notes/rogeliorosa_shot-cats.jpg',
  ];

  @override
  void onInit() {
    super.onInit();
    _notesSub = _repository.watchAll().listen((allNotes) {
      // Sort notes consistently in Dart to match the drag-and-drop sort order fallback
      allNotes.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        
        double orderA = a.sortOrder == 0.0 ? (a.updatedAt ?? a.createdAt).millisecondsSinceEpoch.toDouble() : a.sortOrder;
        double orderB = b.sortOrder == 0.0 ? (b.updatedAt ?? b.createdAt).millisecondsSinceEpoch.toDouble() : b.sortOrder;
        
        if (orderA != orderB) return orderB.compareTo(orderA);
        
        final aDate = a.updatedAt ?? a.createdAt;
        final bDate = b.updatedAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });
      keepNotes.value = allNotes;
      _applyFilter();
    });

    debounce(searchQuery, (_) => _applyFilter(),
        time: const Duration(milliseconds: 300));
    ever(keepNotes, (_) => _applyFilter());
  }

  void _applyFilter() {
    if (searchQuery.value.isEmpty) {
      filteredNotes.assignAll(keepNotes);
      return;
    }
    final q = searchQuery.value.toLowerCase();
    filteredNotes.assignAll(keepNotes.where((n) =>
        n.title.toLowerCase().contains(q) ||
        (n.content?.toLowerCase().contains(q) ?? false)));
  }

  void searchNotes(String query) => searchQuery.value = query;

  Future<void> saveNote({KeepNote? existing, bool popAfterSave = true}) async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      FocusManager.instance.primaryFocus?.unfocus();

      final title = titleController.text.trim();
      
      // Clean up blocks: remove empty text blocks
      final cleanedBlocks = blocks.where((b) {
        if (b.type == KeepNoteType.text && (b.data == null || (b.data as String).trim().isEmpty)) return false;
        if (b.type == KeepNoteType.checklist && (b.data as List).isEmpty) return false;
        return true;
      }).toList();

      // Check if note has any meaningful content (text, media, checklist)
      final hasMedia = cleanedBlocks.any((b) =>
          b.type == KeepNoteType.image ||
          b.type == KeepNoteType.drawing ||
          b.type == KeepNoteType.voice);

      if (title.isEmpty && cleanedBlocks.isEmpty && !hasMedia) {
        isLoading.value = false;
        if (existing == null) {
          if (popAfterSave) {
            Get.back();
            _clearForm();
          }
          return;
        } else {
          await showDeleteConfirmation(existing);
          return;
        }
      }

      // ── Build KeepNote from form state ──────────────────────────────────

      final note = existing?.copyWith(
            title: title,
            updatedAt: DateTime.now(),
          ) ??
          (KeepNote()
            ..title = title
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now()
            ..sortOrder = DateTime.now().millisecondsSinceEpoch.toDouble());

      // Color & background
      note.colorIndex = selectedColor.value;
      note.isPinned = isPinned.value;
      note.backgroundIndex = selectedBackground.value;
      note.backgroundBlur = backgroundBlur.value;
      note.textAlign = textAlign.value;
      note.textSize = textSize.value;
      note.isBold = isBold.value;
      note.isItalic = isItalic.value;
      note.isUnderline = isUnderline.value;
      note.textColorIndex = selectedTextColor.value;
      note.reminderAt = reminderAt.value;

      // Flatten blocks → KeepNote fields
      final textParts = <String>[];
      final checkItems = <KeepCheckItem>[];
      final attachments = <KeepAttachment>[];
      int checkSort = 0;
      int attachSort = 0;

      for (final block in cleanedBlocks) {
        switch (block.type) {
          case KeepNoteType.text:
            if (block.data is String && (block.data as String).trim().isNotEmpty) {
              textParts.add(block.data as String);
            }
            break;
          case KeepNoteType.checklist:
            for (final item in (block.data as List<ChecklistItem>)) {
              checkItems.add(KeepCheckItem()
                ..text = item.text
                ..isDone = item.isDone
                ..sortIndex = checkSort++);
            }
            break;
          case KeepNoteType.image:
          case KeepNoteType.drawing:
          case KeepNoteType.voice:
            if (block.data is String && (block.data as String).isNotEmpty) {
              attachments.add(KeepAttachment()
                ..type = block.type.name
                ..relativePath = block.data as String
                ..sortIndex = attachSort++);
            }
            break;
        }
      }

      note.content = textParts.isNotEmpty ? textParts.join('\n') : null;
      note.checkItems = checkItems;
      note.attachments = attachments;

      final result = await _repository.putNote(note);

      if (result.isSuccess) {
        // ✅ Schedule notification only after confirmed save (note.id is valid)
        if (reminderAt.value != null && reminderAt.value!.isAfter(DateTime.now())) {
          final notifId = 800000000 + note.id;
          String previewText = 'keep_notes'.tr;
          if (textParts.isNotEmpty) {
            String rawData = textParts.first.trim();
            try {
              if (rawData.startsWith('[') && rawData.endsWith(']')) {
                final decoded = jsonDecode(rawData) as List;
                String extracted = '';
                for (var item in decoded) {
                  if (item is Map && item['insert'] is String) {
                    extracted += item['insert'];
                  }
                }
                previewText = extracted.trim();
              } else {
                previewText = rawData;
              }
            } catch (_) {
              previewText = rawData;
            }
          } else if (checkItems.isNotEmpty) {
            previewText = checkItems.first.text;
          }
          if (previewText.isEmpty) previewText = 'keep_notes'.tr;
          if (previewText.length > 50) previewText = '${previewText.substring(0, 50)}...';

          await Get.find<NotificationService>().scheduleNotification(
            id: notifId,
            title: title.isNotEmpty ? title : 'keep_notes'.tr,
            body: previewText,
            scheduledTime: reminderAt.value!,
            channelId: 'reminders_channel',
            channelName: 'Reminders',
          );
          talker.info('🔔 Keep reminder scheduled: id=$notifId at ${reminderAt.value}');
        } else {
          Get.find<NotificationService>().cancelNotification(800000000 + note.id);
        }

        if (popAfterSave) {
          Get.back();
          _clearForm();
        }
        Get.snackbar('success'.tr,
            existing == null ? 'note_added'.tr : 'note_updated'.tr,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.withValues(alpha: 0.1),
            colorText: Colors.green,
            duration: const Duration(seconds: 2));
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Keep Save Error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> showDeleteConfirmation(KeepNote note) async {
    final theme = Theme.of(Get.context!);
    final isDark = theme.brightness == Brightness.dark;
    
    await Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E).withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline_rounded, size: 48, color: Colors.redAccent.withValues(alpha: 0.8)),
                  const SizedBox(height: 16),
                  Text(
                    'confirm_delete'.tr,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'keep_empty_delete_msg'.tr,
                    style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Get.back();
                            loadNoteIntoForm(note);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('cancel'.tr),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Get.back();
                            await deleteNote(note.id);
                            Get.back();
                            _clearForm();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('delete'.tr),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        ),
      ),
      barrierColor: Colors.black.withValues(alpha: 0.3),
    );
  }

  // ── Drag and Drop Reordering ──────────────────────────────────────────────
  Future<void> reorderNotes(int draggedId, int targetId) async {
    final draggedNote = keepNotes.firstWhereOrNull((n) => n.id == draggedId);
    final targetNote = keepNotes.firstWhereOrNull((n) => n.id == targetId);

    if (draggedNote == null || targetNote == null) return;
    
    // Prevent interaction with pinned notes
    if (draggedNote.isPinned || targetNote.isPinned) return;

    final unpinnedNotes = keepNotes.where((n) => !n.isPinned).toList();
    final targetIndex = unpinnedNotes.indexWhere((n) => n.id == targetId);
    final draggedIndex = unpinnedNotes.indexWhere((n) => n.id == draggedId);

    if (targetIndex == -1 || draggedIndex == -1) return;

    double newOrder;

    // Calculate an sortOrder that inserts draggedNote before or after targetNote.
    // Notes are sorted DESCENDING (highest sortOrder at top).
    if (draggedIndex < targetIndex) {
      // Dragging downwards. Insert AFTER targetNote.
      if (targetIndex == unpinnedNotes.length - 1) {
        double tOrder = unpinnedNotes[targetIndex].sortOrder;
        if (tOrder == 0.0) tOrder = (unpinnedNotes[targetIndex].updatedAt ?? unpinnedNotes[targetIndex].createdAt).millisecondsSinceEpoch.toDouble();
        newOrder = tOrder - 10000.0;
      } else {
        double tOrder1 = unpinnedNotes[targetIndex].sortOrder;
        if (tOrder1 == 0.0) tOrder1 = (unpinnedNotes[targetIndex].updatedAt ?? unpinnedNotes[targetIndex].createdAt).millisecondsSinceEpoch.toDouble();
        
        double tOrder2 = unpinnedNotes[targetIndex + 1].sortOrder;
        if (tOrder2 == 0.0) tOrder2 = (unpinnedNotes[targetIndex + 1].updatedAt ?? unpinnedNotes[targetIndex + 1].createdAt).millisecondsSinceEpoch.toDouble();
        
        newOrder = (tOrder1 + tOrder2) / 2.0;
      }
    } else {
      // Dragging upwards. Insert BEFORE targetNote.
      if (targetIndex == 0) {
        double tOrder = unpinnedNotes[targetIndex].sortOrder;
        if (tOrder == 0.0) tOrder = (unpinnedNotes[targetIndex].updatedAt ?? unpinnedNotes[targetIndex].createdAt).millisecondsSinceEpoch.toDouble();
        newOrder = tOrder + 10000.0;
      } else {
        double tOrder1 = unpinnedNotes[targetIndex].sortOrder;
        if (tOrder1 == 0.0) tOrder1 = (unpinnedNotes[targetIndex].updatedAt ?? unpinnedNotes[targetIndex].createdAt).millisecondsSinceEpoch.toDouble();
        
        double tOrder2 = unpinnedNotes[targetIndex - 1].sortOrder;
        if (tOrder2 == 0.0) tOrder2 = (unpinnedNotes[targetIndex - 1].updatedAt ?? unpinnedNotes[targetIndex - 1].createdAt).millisecondsSinceEpoch.toDouble();
        
        newOrder = (tOrder1 + tOrder2) / 2.0;
      }
    }

    final updatedDragged = draggedNote.copyWith(sortOrder: newOrder);

    // Optimistic UI Update
    final indexA = keepNotes.indexWhere((n) => n.id == draggedNote.id);
    if (indexA != -1) {
      keepNotes[indexA] = updatedDragged;
      
      // Re-sort in memory
      keepNotes.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        
        double orderA = a.sortOrder == 0.0 ? (a.updatedAt ?? a.createdAt).millisecondsSinceEpoch.toDouble() : a.sortOrder;
        double orderB = b.sortOrder == 0.0 ? (b.updatedAt ?? b.createdAt).millisecondsSinceEpoch.toDouble() : b.sortOrder;
        
        if (orderA != orderB) return orderB.compareTo(orderA);
        
        final aDate = a.updatedAt ?? a.createdAt;
        final bDate = b.updatedAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });
      _applyFilter();
    }

    // Save to database
    await _repository.putNote(updatedDragged);
    
    // Governance: if position was transferred (dragged), intention is not edit/select, so close it.
    clearSelection();
  }

  Future<void> moveToEnd(int draggedId) async {
    final draggedNote = keepNotes.firstWhereOrNull((n) => n.id == draggedId);
    if (draggedNote == null || draggedNote.isPinned) return;

    final unpinnedNotes = keepNotes.where((n) => !n.isPinned).toList();
    if (unpinnedNotes.isEmpty) return;

    double minOrder = unpinnedNotes.map((n) {
      if (n.sortOrder == 0.0) return (n.updatedAt ?? n.createdAt).millisecondsSinceEpoch.toDouble();
      return n.sortOrder;
    }).reduce(min);

    // Move to end by assigning a sortOrder smaller than the minimum
    final newOrder = minOrder - 10000.0;
    final updatedDragged = draggedNote.copyWith(sortOrder: newOrder);

    final indexA = keepNotes.indexWhere((n) => n.id == draggedId);
    if (indexA != -1) {
      keepNotes[indexA] = updatedDragged;
      keepNotes.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        
        double orderA = a.sortOrder == 0.0 ? (a.updatedAt ?? a.createdAt).millisecondsSinceEpoch.toDouble() : a.sortOrder;
        double orderB = b.sortOrder == 0.0 ? (b.updatedAt ?? b.createdAt).millisecondsSinceEpoch.toDouble() : b.sortOrder;
        
        if (orderA != orderB) return orderB.compareTo(orderA);
        
        final aDate = a.updatedAt ?? a.createdAt;
        final bDate = b.updatedAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });
      _applyFilter();
    }

    await _repository.putNote(updatedDragged);
  }

  Future<void> deleteNote(int id) async {
    await _repository.deleteNote(id);
  }

  Future<void> togglePin(KeepNote note) async {
    try {
      await _repository.putNote(note.copyWith(isPinned: !note.isPinned));
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Keep Pin Toggle Error');
    }
  }

  Future<void> changeColor(KeepNote note, int? colorIndex) async {
    try {
      final updated = note.copyWith(
        colorIndex: colorIndex,
        backgroundIndex: colorIndex != null ? null : note.backgroundIndex,
        backgroundBlur: colorIndex != null ? 0.0 : note.backgroundBlur,
        updatedAt: DateTime.now(),
      );
      await _repository.putNote(updated);
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Keep Color Error');
    }
  }
  
  Future<void> changeBackground(KeepNote note, int? bgIndex, {double? blur}) async {
    try {
      final updated = note.copyWith(
        backgroundIndex: bgIndex,
        backgroundBlur: blur ?? note.backgroundBlur,
        colorIndex: bgIndex != null ? null : note.colorIndex,
        updatedAt: DateTime.now(),
      );
      await _repository.putNote(updated);
    } catch(e, stack) {
      talker.handle(e, stack, '🔴 Keep Background Error');
    }
  }

  void loadNoteIntoForm(KeepNote note) {
    titleController.text = note.title;
    selectedColor.value = note.colorIndex;
    isPinned.value = note.isPinned;
    selectedBackground.value = note.backgroundIndex;
    backgroundBlur.value = note.backgroundBlur;
    textAlign.value = note.textAlign;
    textSize.value = note.textSize;
    isBold.value = note.isBold;
    isItalic.value = note.isItalic;
    isUnderline.value = note.isUnderline;
    selectedTextColor.value = note.textColorIndex;
    reminderAt.value = note.reminderAt;
    
    // Rebuild blocks from KeepNote fields
    final rebuiltBlocks = <KeepBlock>[];
    
    // Text content
    if (note.content != null && note.content!.isNotEmpty) {
      rebuiltBlocks.add(KeepBlock(type: KeepNoteType.text, data: note.content));
    }
    
    // Checklist items
    if (note.checkItems.isNotEmpty) {
      final items = note.checkItems
          .map((ci) => ChecklistItem(text: ci.text, isDone: ci.isDone))
          .toList();
      rebuiltBlocks.add(KeepBlock(type: KeepNoteType.checklist, data: items));
    }
    
    // Attachments
    for (final att in note.attachments) {
      final type = KeepNoteType.values.firstWhere(
        (e) => e.name == att.type,
        orElse: () => KeepNoteType.image,
      );
      rebuiltBlocks.add(KeepBlock(type: type, data: att.relativePath));
    }
    
    blocks.assignAll(rebuiltBlocks);
    
    // If empty, add a default text block
    if (blocks.isEmpty) {
      blocks.add(KeepBlock(type: KeepNoteType.text, data: ''));
    }
  }

  void _clearForm() {
    titleController.clear();
    blocks.clear();
    selectedColor.value = null;
    selectedBackground.value = null;
    backgroundBlur.value = 0.0;
    textAlign.value = 0;
    textSize.value = 16.0;
    isBold.value = false;
    isItalic.value = false;
    isUnderline.value = false;
    selectedTextColor.value = null;
    isPinned.value = false;
    reminderAt.value = null;
  }

  /// Block manipulation helpers
  void addBlock(KeepNoteType type, dynamic initialData) {
    blocks.add(KeepBlock(type: type, data: initialData));
  }
  
  void removeBlock(int index) {
    if (index >= 0 && index < blocks.length) {
      blocks.removeAt(index);
    }
  }

  void updateBlockData(int index, dynamic newData) {
    if (index >= 0 && index < blocks.length) {
      blocks[index].data = newData;
      blocks.refresh();
    }
  }

  // Type detection helpers (for backward compatibility)
  static KeepNoteType _detectType(String? content) {
    if (content == null) return KeepNoteType.text;
    if (content.startsWith('checklist:')) return KeepNoteType.checklist;
    if (content.startsWith('img:')) return KeepNoteType.image;
    if (content.startsWith('draw:')) return KeepNoteType.drawing;
    if (content.startsWith('voice:')) return KeepNoteType.voice;
    return KeepNoteType.text;
  }

  static String? _stripTypeTag(String? content) {
    if (content == null) return null;
    for (final tag in ['checklist:', 'img:', 'draw:', 'voice:', 'text:']) {
      if (content.startsWith(tag)) return content.substring(tag.length);
    }
    return content;
  }

  static List<ChecklistItem> parseChecklistString(String? content) {
    if (content == null || content.isEmpty) return [];
    return content.split('\n').where((l) => l.isNotEmpty).map(ChecklistItem.fromLine).toList();
  }

  /// Parses both new JSON format and old string-prefix format
  static KeepNoteData parseContent(String? raw) {
    if (raw == null || raw.isEmpty) return KeepNoteData(blocks: []);

    // Try JSON parsing
    if (raw.startsWith('{') && raw.endsWith('}')) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        if (map.containsKey('blocks')) {
          return KeepNoteData.fromJson(map);
        }
      } catch (_) {}
    }

    // Fallback parsing for old format
    final type = _detectType(raw);
    final dataString = _stripTypeTag(raw) ?? '';

    dynamic data = dataString;
    if (type == KeepNoteType.checklist) {
      data = parseChecklistString(dataString);
    }

    return KeepNoteData(
      blocks: [KeepBlock(type: type, data: data)],
      backgroundIndex: null,
      backgroundBlur: 0.0,
      textColorIndex: null,
    );
  }

  /// Build KeepNoteData from a KeepNote (for views that still need block-based rendering)
  static KeepNoteData noteToData(KeepNote note) {
    final blocks = <KeepBlock>[];

    if (note.content != null && note.content!.isNotEmpty) {
      blocks.add(KeepBlock(type: KeepNoteType.text, data: note.content));
    }
    if (note.checkItems.isNotEmpty) {
      blocks.add(KeepBlock(
        type: KeepNoteType.checklist,
        data: note.checkItems
            .map((ci) => ChecklistItem(text: ci.text, isDone: ci.isDone))
            .toList(),
      ));
    }
    for (final att in note.attachments) {
      final type = KeepNoteType.values.firstWhere(
        (e) => e.name == att.type,
        orElse: () => KeepNoteType.image,
      );
      blocks.add(KeepBlock(type: type, data: att.relativePath));
    }

    return KeepNoteData(
      blocks: blocks,
      backgroundIndex: note.backgroundIndex,
      backgroundBlur: note.backgroundBlur,
      textAlign: note.textAlign,
      textSize: note.textSize,
      isBold: note.isBold,
      isItalic: note.isItalic,
      isUnderline: note.isUnderline,
      textColorIndex: note.textColorIndex,
      reminderAt: note.reminderAt,
    );
  }

  Color getBoardColor(int? colorIndex, bool isDark) {
    if (colorIndex == null || colorIndex < 0 || colorIndex >= boardColors.length) {
      return isDark ? const Color(0xFF1E1E1E) : Colors.white;
    }
    return boardColors[colorIndex];
  }

  Color? getTextColor(int? colorIndex) {
    if (colorIndex == null || colorIndex < 0 || colorIndex >= textColors.length) {
      return null;
    }
    return textColors[colorIndex];
  }

  @override
  void onClose() {
    searchFocusNode.dispose();
    _notesSub?.cancel();
    titleController.dispose();
    super.onClose();
  }
}
