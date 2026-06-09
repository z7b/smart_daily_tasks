import 'package:isar/isar.dart';
import '../../core/helpers/log_helper.dart';
import '../../core/helpers/result.dart';
import '../models/keep_note_model.dart';

class KeepRepository {
  final Isar _isar;

  KeepRepository(this._isar) {
    talker.info('📌 KeepRepository initialized');
  }

  // ── Create / Update ────────────────────────────────────────────────────────

  Future<Result<bool>> putNote(KeepNote note) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.keepNotes.put(note);
      });
      return Result.success(true);
    } on IsarError catch (e, stack) {
      talker.handle(e, stack, '🔴 Isar Error (KeepNote put)');
      return Result.failure(e.toString());
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Error (KeepNote put)');
      return Result.failure(e.toString());
    }
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Watch all keep notes, pinned first, then by sortOrder descending.
  Stream<List<KeepNote>> watchAll() {
    return _isar.keepNotes
        .where()
        .sortByIsPinnedDesc()
        .thenBySortOrderDesc()
        .watch(fireImmediately: true);
  }

  /// Get a single note by ID.
  Future<KeepNote?> getById(Id id) async {
    return await _isar.keepNotes.get(id);
  }

  /// Get all keep notes (one-shot, for migration checks).
  Future<List<KeepNote>> getAll() async {
    return await _isar.keepNotes.where().findAll();
  }

  /// Count total keep notes (for migration check).
  Future<int> count() async {
    return await _isar.keepNotes.count();
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<Result<bool>> deleteNote(Id id) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.keepNotes.delete(id);
      });
      return Result.success(true);
    } on IsarError catch (e, stack) {
      talker.handle(e, stack, '🔴 Isar Error (KeepNote delete)');
      return Result.failure(e.toString());
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Error (KeepNote delete)');
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> deleteMultiple(List<Id> ids) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.keepNotes.deleteAll(ids);
      });
      return Result.success(true);
    } on IsarError catch (e, stack) {
      talker.handle(e, stack, '🔴 Isar Error (KeepNote deleteMultiple)');
      return Result.failure(e.toString());
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Error (KeepNote deleteMultiple)');
      return Result.failure(e.toString());
    }
  }

  // ── Batch (for migration) ─────────────────────────────────────────────────

  Future<Result<bool>> putAll(List<KeepNote> notes) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.keepNotes.putAll(notes);
      });
      return Result.success(true);
    } on IsarError catch (e, stack) {
      talker.handle(e, stack, '🔴 Isar Error (KeepNote putAll)');
      return Result.failure(e.toString());
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Error (KeepNote putAll)');
      return Result.failure(e.toString());
    }
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  Future<List<KeepNote>> search(String query) async {
    try {
      final q = query.toLowerCase();
      return await _isar.keepNotes
          .filter()
          .titleContains(q, caseSensitive: false)
          .or()
          .contentContains(q, caseSensitive: false)
          .sortByIsPinnedDesc()
          .thenBySortOrderDesc()
          .limit(50)
          .findAll();
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 KeepNote search error');
      return [];
    }
  }
}
