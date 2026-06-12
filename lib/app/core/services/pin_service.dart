import 'dart:async';
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';
import '../../data/models/keep_note_model.dart';
import '../../core/helpers/log_helper.dart';

class PinService extends GetxService {
  final Isar _isar;
  PinService(this._isar);

  // Observable set of pinned keys, e.g. "task_5", "medication_12"
  final RxSet<String> pinnedItems = <String>{}.obs;
  StreamSubscription? _watcherSub;

  @override
  void onInit() {
    super.onInit();
    _loadPinnedItems();
    _watcherSub = _isar.keepNotes.watchLazy().listen((_) {
      _loadPinnedItems();
    });
  }

  @override
  void onClose() {
    _watcherSub?.cancel();
    super.onClose();
  }

  String _getKey(String type, int id) => '${type}_$id';

  Future<void> _loadPinnedItems() async {
    try {
      final pinnedNotes = await _isar.keepNotes.filter()
          .linkedItemTypeIsNotNull()
          .findAll();
      
      final Set<String> keys = {};
      for (var note in pinnedNotes) {
        if (note.linkedItemType != null && note.linkedItemId != null) {
          keys.add(_getKey(note.linkedItemType!, note.linkedItemId!));
        }
      }
      pinnedItems.assignAll(keys);
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Failed to load pinned items');
    }
  }

  bool isPinned(String type, int id) {
    return pinnedItems.contains(_getKey(type, id));
  }

  /// Remove linked KeepNote when the source item is deleted.
  /// This prevents the red "item_deleted_or_missing" error on the board.
  Future<void> unpinOnDelete(String type, int id) async {
    final key = _getKey(type, id);
    try {
      // Always query DB — don't rely on pinnedItems set being up-to-date
      final notes = await _isar.keepNotes.filter()
          .linkedItemTypeEqualTo(type)
          .linkedItemIdEqualTo(id)
          .findAll();

      if (notes.isNotEmpty) {
        await _isar.writeTxn(() async {
          await _isar.keepNotes.deleteAll(notes.map((n) => n.id).toList());
        });
      }
      pinnedItems.remove(key);
      talker.info('📌 Auto-unpinned deleted item: $key (removed ${notes.length} notes)');
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Failed to auto-unpin on delete');
    }
  }

  Future<void> togglePin(String type, int id) async {
    final key = _getKey(type, id);
    try {
      if (pinnedItems.contains(key)) {
        // Unpin: Find and delete the note
        final note = await _isar.keepNotes.filter()
            .linkedItemTypeEqualTo(type)
            .linkedItemIdEqualTo(id)
            .findFirst();
            
        if (note != null) {
          await _isar.writeTxn(() async {
            await _isar.keepNotes.delete(note.id);
          });
          pinnedItems.remove(key);
        }
      } else {
        // Pin: Create a new shell keepNote
        // so KeepController picks it up in the board view.
        final note = KeepNote()
          ..title = '📌 $type #$id'
          ..createdAt = DateTime.now()
          ..linkedItemType = type
          ..linkedItemId = id
          ..isPinned = false
          ..sortOrder = DateTime.now().millisecondsSinceEpoch.toDouble();
        
        await _isar.writeTxn(() async {
          await _isar.keepNotes.put(note);
        });
        pinnedItems.add(key);
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Failed to toggle pin');
    }
  }
}
