import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../../core/helpers/log_helper.dart';
import '../models/journal_model.dart';

class JournalRepository {
  final Isar _isar;

  JournalRepository(this._isar) {
    talker.info('📔 JournalRepository initialized');
  }

  /// Create a new journal entry with success result
  Future<bool> addJournal(Journal journal) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.journals.put(journal);
      });
      return true;
    } on IsarError catch (e, stack) {
      talker.handle(e, stack, '🔴 Isar Database Error (Add Journal)');
      return false;
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Add Journal)');
      return false;
    }
  }

  // Read all
  Stream<List<Journal>> watchAllJournals({int limit = 300}) async* {
    yield* _isar.journals.where().sortByDateDesc().watch(fireImmediately: true);
  }

  // Read by ID
  Future<Journal?> getJournal(Id id) async {
    return await _isar.journals.get(id);
  }

  /// Update an existing journal entry with success result
  Future<bool> updateJournal(Journal journal) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.journals.put(journal);
      });
      return true;
    } on IsarError catch (e, stack) {
      talker.handle(e, stack, '🔴 Isar Database Error (Update Journal)');
      return false;
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Update Journal)');
      return false;
    }
  }

  // Delete
  Future<void> deleteJournal(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.journals.delete(id);
    });
  }
}
