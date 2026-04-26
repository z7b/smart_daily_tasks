
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

  /// Atomically add or update an entry for a specific date (Resolves Race Conditions)
  Future<bool> addOrUpdateJournalForDate(DateTime date, Mood mood, String? note) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      await _isar.writeTxn(() async {
        final existing = await _isar.journals
            .filter()
            .dateBetween(startOfDay, endOfDay, includeLower: true, includeUpper: false)
            .findFirst();
        
        final journal = Journal(
          id: existing?.id ?? Isar.autoIncrement,
          date: date,
          mood: mood,
          note: note,
          createdAt: existing?.createdAt ?? DateTime.now(),
        );
        
        await _isar.journals.put(journal);
      });
      return true;
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Atomic Database Error (Add/Update Journal)');
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

  /// Delete a journal entry with safety governance
  Future<bool> deleteJournal(Id id) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.journals.delete(id);
      });
      return true;
    } on IsarError catch (e, stack) {
      talker.handle(e, stack, '🔴 Isar Database Error (Delete Journal)');
      return false;
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Delete Journal)');
      return false;
    }
  }
}
