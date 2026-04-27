import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../data/models/note_model.dart';
import '../../../data/models/journal_model.dart';
import '../../../data/models/bookmark_model.dart';
import '../../../data/models/medication_model.dart';
import '../../../data/models/calendar_event_model.dart';
import '../../../data/models/book_model.dart';

class PillarCounts {
  final int notes;
  final int journals;
  final int bookmarks;
  final int medications;
  final int calendarEvents;
  final int books;

  PillarCounts({
    this.notes = 0,
    this.journals = 0,
    this.bookmarks = 0,
    this.medications = 0,
    this.calendarEvents = 0,
    this.books = 0,
  });
}

class HomePillarService extends GetxService {
  final Isar _isar;
  HomePillarService(this._isar);

  Future<PillarCounts> getGlobalCounts() async {
    final results = await Future.wait([
      _isar.notes.count(),
      _isar.journals.count(),
      _isar.bookmarks.count(),
      _isar.medications.count(),
      _isar.calendarEvents.count(),
      _isar.books.count(),
    ]);

    return PillarCounts(
      notes: results[0],
      journals: results[1],
      bookmarks: results[2],
      medications: results[3],
      calendarEvents: results[4],
      books: results[5],
    );
  }
}
