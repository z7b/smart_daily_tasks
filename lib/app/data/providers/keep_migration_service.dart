import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:isar_community/isar.dart';

import '../../core/helpers/log_helper.dart';
import '../models/note_model.dart';
import '../models/keep_note_model.dart';

/// One-time migration: Note (category == 'keep') → KeepNote.
///
/// Runs once on first launch after schema upgrade.
/// Safe to call multiple times — skips if already migrated.
class KeepMigrationService {
  static const _migrationKey = 'keep_migration_v1_done';

  final Isar _isar;
  KeepMigrationService(this._isar);

  /// Returns true if migration was already completed.
  bool get isMigrated => GetStorage().read<bool>(_migrationKey) ?? false;

  /// Run migration if not already done.
  Future<void> migrateIfNeeded() async {
    if (isMigrated) return;

    final sw = Stopwatch()..start();
    talker.info('🔄 KeepMigration: Starting migration from Note → KeepNote...');

    try {
      // 1. Fetch all old keep notes
      final oldNotes = await _isar.notes
          .filter()
          .categoryEqualTo('keep')
          .findAll();

      if (oldNotes.isEmpty) {
        talker.info('🔄 KeepMigration: No old keep notes found. Marking as done.');
        await _markDone();
        return;
      }

      talker.info('🔄 KeepMigration: Found ${oldNotes.length} notes to migrate.');

      // 2. Convert each old Note → KeepNote
      final newNotes = <KeepNote>[];
      for (final old in oldNotes) {
        newNotes.add(_convertNote(old));
      }

      // 3. Batch insert into KeepNote collection
      await _isar.writeTxn(() async {
        await _isar.keepNotes.putAll(newNotes);
      });

      // 4. Mark migration as complete
      await _markDone();

      sw.stop();
      talker.info(
        '✅ KeepMigration: Successfully migrated ${newNotes.length} notes in ${sw.elapsedMilliseconds}ms',
      );
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 KeepMigration: Migration failed');
      // Do NOT mark as done — let it retry next launch
    }
  }

  /// Convert a single old Note to a KeepNote.
  KeepNote _convertNote(Note old) {
    final keepNote = KeepNote()
      ..title = old.title
      ..colorIndex = old.color
      ..isPinned = old.isPinned
      ..sortOrder = old.orderIndex
      ..linkedItemType = old.linkedItemType
      ..linkedItemId = old.linkedItemId
      ..createdAt = old.createdAt
      ..updatedAt = old.updatedAt;

    // Parse the old JSON-blob content
    final raw = old.content;
    if (raw == null || raw.isEmpty) {
      return keepNote;
    }

    // Try new JSON format first
    if (raw.startsWith('{') && raw.endsWith('}')) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        if (map.containsKey('blocks')) {
          _applyJsonBlocks(keepNote, map);
          return keepNote;
        }
      } catch (_) {}
    }

    // Fallback: old string-prefix format
    _applyLegacyContent(keepNote, raw);
    return keepNote;
  }

  /// Apply data from new JSON format (blocks array).
  void _applyJsonBlocks(KeepNote note, Map<String, dynamic> map) {
    // Style metadata
    note.backgroundIndex = map['backgroundIndex'] as int?;
    note.backgroundBlur = (map['backgroundBlur'] as num?)?.toDouble() ?? 0.0;
    note.textAlign = (map['textAlign'] as int?) ?? 0;
    note.textSize = (map['textSize'] as num?)?.toDouble() ?? 16.0;
    note.isBold = (map['isBold'] as bool?) ?? false;
    note.isItalic = (map['isItalic'] as bool?) ?? false;
    note.isUnderline = (map['isUnderline'] as bool?) ?? false;
    note.textColorIndex = map['textColorIndex'] as int?;

    if (map['reminderAt'] != null) {
      note.reminderAt = DateTime.tryParse(map['reminderAt'] as String);
    }

    final blocks = map['blocks'] as List? ?? [];
    final textParts = <String>[];
    final checkItems = <KeepCheckItem>[];
    final attachments = <KeepAttachment>[];
    int attachSort = 0;
    int checkSort = 0;

    for (final block in blocks) {
      final type = block['type'] as String? ?? 'text';
      final data = block['data'];

      switch (type) {
        case 'text':
          if (data is String && data.trim().isNotEmpty) {
            textParts.add(data);
          }
          break;
        case 'checklist':
          if (data is List) {
            for (final item in data) {
              final ci = KeepCheckItem()
                ..text = (item['text'] as String?) ?? ''
                ..isDone = (item['isDone'] as bool?) ?? false
                ..sortIndex = checkSort++;
              checkItems.add(ci);
            }
          }
          break;
        case 'image':
        case 'drawing':
        case 'voice':
          if (data is String && data.isNotEmpty) {
            final att = KeepAttachment()
              ..type = type
              ..relativePath = data
              ..sortIndex = attachSort++;
            attachments.add(att);
          }
          break;
      }
    }

    if (textParts.isNotEmpty) {
      note.content = textParts.join('\n');
    }
    note.checkItems = checkItems;
    note.attachments = attachments;
  }

  /// Apply data from old string-prefix format (legacy).
  void _applyLegacyContent(KeepNote note, String raw) {
    if (raw.startsWith('checklist:')) {
      final lines = raw.substring('checklist:'.length).split('\n');
      int sort = 0;
      for (final line in lines) {
        if (line.isEmpty) continue;
        final isDone = line.startsWith('[x] ');
        final text = line.startsWith('[x] ')
            ? line.substring(4)
            : (line.startsWith('[ ] ') ? line.substring(4) : line);
        note.checkItems.add(
          KeepCheckItem()
            ..text = text
            ..isDone = isDone
            ..sortIndex = sort++,
        );
      }
    } else if (raw.startsWith('img:')) {
      note.attachments.add(
        KeepAttachment()
          ..type = 'image'
          ..relativePath = raw.substring('img:'.length)
          ..sortIndex = 0,
      );
    } else if (raw.startsWith('draw:')) {
      note.attachments.add(
        KeepAttachment()
          ..type = 'drawing'
          ..relativePath = raw.substring('draw:'.length)
          ..sortIndex = 0,
      );
    } else if (raw.startsWith('voice:')) {
      note.attachments.add(
        KeepAttachment()
          ..type = 'audio'
          ..relativePath = raw.substring('voice:'.length)
          ..sortIndex = 0,
      );
    } else {
      // Plain text
      final stripped = raw.startsWith('text:') ? raw.substring('text:'.length) : raw;
      note.content = stripped;
    }
  }

  Future<void> _markDone() async {
    await GetStorage().write(_migrationKey, true);
  }
}
