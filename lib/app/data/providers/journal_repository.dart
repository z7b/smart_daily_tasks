
import 'package:isar/isar.dart';
import '../../core/helpers/log_helper.dart';
import '../../core/helpers/result.dart';
import '../models/journal_model.dart';

class JournalRepository {
  final Isar _isar;

  JournalRepository(this._isar) {
    talker.info('📔 JournalRepository initialized');
  }

  /// Create a new journal entry with success result
  Future<List<Journal>> getJournalsInRange(DateTime start, DateTime end) async {
    final startOfDay = DateTime(start.year, start.month, start.day);
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return await _isar.journals.filter()
        .dateBetween(startOfDay, endOfDay)
        .sortByDateDesc()
        .findAll();
  }

  Future<int> getJournalsCountForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return await _isar.journals.filter()
        .dateBetween(startOfDay, endOfDay, includeLower: true, includeUpper: false)
        .count();
  }

  Future<Result<bool>> addJournal(Journal journal) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.journals.put(journal);
      });
      return Result.success(true);
    } on IsarError catch (e, stack) {
      talker.handle(e, stack, '🔴 Isar Database Error (Add Journal)');
      return Result.failure(e.toString());
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Add Journal)');
      return Result.failure(e.toString());
    }
  }

  /// Atomically add or update an entry for a specific date (Resolves Race Conditions)
  Future<Result<bool>> addOrUpdateJournalForDate(DateTime date, Mood mood, String? note) async {
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
      return Result.success(true);
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Atomic Database Error (Add/Update Journal)');
      return Result.failure(e.toString());
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
  Future<Result<bool>> updateJournal(Journal journal) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.journals.put(journal);
      });
      return Result.success(true);
    } on IsarError catch (e, stack) {
      talker.handle(e, stack, '🔴 Isar Database Error (Update Journal)');
      return Result.failure(e.toString());
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Update Journal)');
      return Result.failure(e.toString());
    }
  }

  /// Delete a journal entry with safety governance
  Future<Result<bool>> deleteJournal(Id id) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.journals.delete(id);
      });
      return Result.success(true);
    } on IsarError catch (e, stack) {
      talker.handle(e, stack, '🔴 Isar Database Error (Delete Journal)');
      return Result.failure(e.toString());
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Delete Journal)');
      return Result.failure(e.toString());
    }
  }
}
