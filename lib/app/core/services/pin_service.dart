import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../data/models/note_model.dart';
import '../../core/helpers/log_helper.dart';

class PinService extends GetxService {
  final Isar _isar;
  PinService(this._isar);

  // Observable set of pinned keys, e.g. "task_5", "medication_12"
  final RxSet<String> pinnedItems = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPinnedItems();
  }

  String _getKey(String type, int id) => '${type}_$id';

  Future<void> _loadPinnedItems() async {
    try {
      final pinnedNotes = await _isar.notes.filter()
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

  Future<void> togglePin(String type, int id) async {
    final key = _getKey(type, id);
    try {
      if (pinnedItems.contains(key)) {
        // Unpin: Find and delete the note
        final note = await _isar.notes.filter()
            .linkedItemTypeEqualTo(type)
            .linkedItemIdEqualTo(id)
            .findFirst();
            
        if (note != null) {
          await _isar.writeTxn(() async {
            await _isar.notes.delete(note.id);
          });
          pinnedItems.remove(key);
        }
      } else {
        // Pin: Create a new shell note with category 'keep' 
        // so KeepController picks it up in the board view.
        final note = Note(
          title: '📌 $type #$id',
          createdAt: DateTime.now(),
          linkedItemType: type,
          linkedItemId: id,
          isPinned: false,
          category: 'keep',
        );
        
        await _isar.writeTxn(() async {
          await _isar.notes.put(note);
        });
        pinnedItems.add(key);
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Failed to toggle pin');
    }
  }
}
