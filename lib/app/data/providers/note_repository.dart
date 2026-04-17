import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../../core/helpers/log_helper.dart';
import '../models/note_model.dart';

class NoteRepository {
  final Isar _isar;

  NoteRepository(this._isar) {
    talker.info('📝 NoteRepository initialized');
  }

  /// Create a new note with success result
  Future<bool> addNote(Note note) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.notes.put(note);
      });
      return true;
    } on IsarError catch (e, stack) {
      talker.handle(e, stack, '🔴 Isar Database Error (Add Note)');
      return false;
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Add Note)');
      return false;
    }
  }

  // Read all
  Stream<List<Note>> watchAllNotes({int limit = 300}) async* {
    yield* _isar.notes.where().sortByUpdatedAtDesc().watch(fireImmediately: true);
  }

  // Read by ID
  Future<Note?> getNote(Id id) async {
    return await _isar.notes.get(id);
  }

  /// Update an existing note with success result
  Future<bool> updateNote(Note note) async {
    try {
      final noteWithTimestamp = note.copyWith(updatedAt: DateTime.now());
      await _isar.writeTxn(() async {
        await _isar.notes.put(noteWithTimestamp);
      });
      return true;
    } on IsarError catch (e, stack) {
      talker.handle(e, stack, '🔴 Isar Database Error (Update Note)');
      return false;
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Update Note)');
      return false;
    }
  }

  /// Delete a note with safety governance
  Future<bool> deleteNote(Id id) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.notes.delete(id);
      });
      return true;
    } on IsarError catch (e, stack) {
      talker.handle(e, stack, '🔴 Isar Database Error (Delete Note)');
      return false;
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Delete Note)');
      return false;
    }
  }

  // Search
  Future<List<Note>> searchNotes(String query) async {
    try {
      return await _isar.notes
          .filter()
          .titleLowerContains(query.toLowerCase())
          .or()
          .contentLowerContains(query.toLowerCase())
          .limit(50)
          .findAll();
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Note search error');
      return [];
    }
  }
}
