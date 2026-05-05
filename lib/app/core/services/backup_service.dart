import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../data/models/task_model.dart';
import '../../data/models/note_model.dart';
import '../../data/models/journal_model.dart';
import '../../data/models/bookmark_model.dart';
import '../../data/models/calendar_event_model.dart';
import '../../data/models/book_model.dart';
import '../../data/models/medication_model.dart';
import '../../data/models/step_log_model.dart';
import '../../data/models/work_profile_model.dart';
import '../../data/models/attendance_log_model.dart';


class BackupService {
  final Isar _isar = Get.find<Isar>();

  /// Collects all app data and returns a JSON string representing the backup.
  Future<String> exportBackupData() async {
    final tasks = await _isar.tasks.where().findAll();
    final notes = await _isar.notes.where().findAll();
    final journals = await _isar.journals.where().findAll();
    final bookmarks = await _isar.bookmarks.where().findAll();
    final events = await _isar.calendarEvents.where().findAll();
    final books = await _isar.books.where().findAll();
    final medications = await _isar.medications.where().findAll();
    final stepLogs = await _isar.stepLogs.where().findAll();
    final workProfiles = await _isar.workProfiles.where().findAll();
    final attendanceLogs = await _isar.attendanceLogs.where().findAll();

    final Map<String, dynamic> backupData = {
      'version': 2,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'tasks': tasks.map((e) => e.toJson()).toList(),
      'notes': notes.map((e) => e.toJson()).toList(),
      'journal': journals.map((e) => e.toJson()).toList(),
      'bookmarks': bookmarks.map((e) => e.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
      'books': books.map((e) => e.toJson()).toList(),
      'medications': medications.map((e) => e.toJson()).toList(),
      'stepLogs': stepLogs.map((e) => e.toJson()).toList(),
      'workProfiles': workProfiles.map((e) => e.toJson()).toList(),
      'attendanceLogs': attendanceLogs.map((e) => e.toJson()).toList(),
    };

    return jsonEncode(backupData);
  }

  /// Exports data to a file and triggers the share sheet.
  Future<void> createBackup() async {
    final jsonString = await exportBackupData();
    final directory = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File('${directory.path}/smart_daily_tasks_$dateStr.json');

    await file.writeAsString(jsonString);

    await Share.shareXFiles([XFile(file.path)], text: 'Smart Daily Tasks Backup');
  }

  /// Restores data from a picked JSON file using a safe additive merge strategy.
  Future<void> restoreBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final jsonString = await file.readAsString();
    final dynamic decoded = jsonDecode(jsonString);

    if (decoded is! Map<String, dynamic>) throw 'Invalid backup file format';
    
    final Map<String, dynamic> backupData = decoded;
    if (backupData['version'] == null) throw 'Corrupted backup metadata';

    // 1. Safe parsing into memory first (Dry Run)
    final List<Task> tasksToRestore = [];
    final List<Note> notesToRestore = [];
    final List<Journal> journalsToRestore = [];
    final List<Bookmark> bookmarksToRestore = [];
    final List<CalendarEvent> eventsToRestore = [];
    final List<Book> booksToRestore = [];
    final List<Medication> medicationsToRestore = [];
    final List<StepLog> stepLogsToRestore = [];
    final List<WorkProfile> workProfilesToRestore = [];
    final List<AttendanceLog> attendanceLogsToRestore = [];

    // Process Tasks
    if (backupData['tasks'] != null && backupData['tasks'] is List) {
      for (var e in (backupData['tasks'] as List)) {
        if (e is Map<String, dynamic>) {
          tasksToRestore.add(Task.fromJson(e)..id = Isar.autoIncrement);
        }
      }
    }

    // Process Notes
    if (backupData['notes'] != null && backupData['notes'] is List) {
      for (var e in (backupData['notes'] as List)) {
        if (e is Map<String, dynamic>) {
          notesToRestore.add(Note.fromJson(e)..id = Isar.autoIncrement);
        }
      }
    }

    // Process Journal
    if (backupData['journal'] != null && backupData['journal'] is List) {
      for (var e in (backupData['journal'] as List)) {
        if (e is Map<String, dynamic>) {
          journalsToRestore.add(Journal.fromJson(e)..id = Isar.autoIncrement);
        }
      }
    }

    // Process Bookmarks
    if (backupData['bookmarks'] != null && backupData['bookmarks'] is List) {
      for (var e in (backupData['bookmarks'] as List)) {
        if (e is Map<String, dynamic>) {
          bookmarksToRestore.add(Bookmark.fromJson(e)..id = Isar.autoIncrement);
        }
      }
    }

    // Process Events
    if (backupData['events'] != null && backupData['events'] is List) {
      for (var e in (backupData['events'] as List)) {
        if (e is Map<String, dynamic>) {
          eventsToRestore.add(CalendarEvent.fromJson(e)..id = Isar.autoIncrement);
        }
      }
    }

    // Process Books
    if (backupData['books'] != null && backupData['books'] is List) {
      for (var e in (backupData['books'] as List)) {
        if (e is Map<String, dynamic>) {
          booksToRestore.add(Book.fromJson(e)..id = Isar.autoIncrement);
        }
      }
    }

    // Process Medications
    if (backupData['medications'] != null && backupData['medications'] is List) {
      for (var e in (backupData['medications'] as List)) {
        if (e is Map<String, dynamic>) {
          medicationsToRestore.add(Medication.fromJson(e)..id = Isar.autoIncrement);
        }
      }
    }

    // Process StepLogs
    if (backupData['stepLogs'] != null && backupData['stepLogs'] is List) {
      for (var e in (backupData['stepLogs'] as List)) {
        if (e is Map<String, dynamic>) {
          stepLogsToRestore.add(StepLog.fromJson(e)..id = Isar.autoIncrement);
        }
      }
    }

    // Process WorkProfiles
    if (backupData['workProfiles'] != null && backupData['workProfiles'] is List) {
      for (var e in (backupData['workProfiles'] as List)) {
        if (e is Map<String, dynamic>) {
          workProfilesToRestore.add(WorkProfile.fromJson(e));
        }
      }
    }

    // Process AttendanceLogs
    if (backupData['attendanceLogs'] != null && backupData['attendanceLogs'] is List) {
      for (var e in (backupData['attendanceLogs'] as List)) {
        if (e is Map<String, dynamic>) {
          attendanceLogsToRestore.add(AttendanceLog.fromJson(e)..id = Isar.autoIncrement);
        }
      }
    }

    // 2. Perform additive merge transaction (No .clear() calls)
    await _isar.writeTxn(() async {
      if (tasksToRestore.isNotEmpty) await _isar.tasks.putAll(tasksToRestore);
      if (notesToRestore.isNotEmpty) await _isar.notes.putAll(notesToRestore);
      if (journalsToRestore.isNotEmpty) await _isar.journals.putAll(journalsToRestore);
      if (bookmarksToRestore.isNotEmpty) await _isar.bookmarks.putAll(bookmarksToRestore);
      if (eventsToRestore.isNotEmpty) await _isar.calendarEvents.putAll(eventsToRestore);
      if (booksToRestore.isNotEmpty) await _isar.books.putAll(booksToRestore);
      if (medicationsToRestore.isNotEmpty) await _isar.medications.putAll(medicationsToRestore);
      if (stepLogsToRestore.isNotEmpty) await _isar.stepLogs.putAll(stepLogsToRestore);
      if (workProfilesToRestore.isNotEmpty) await _isar.workProfiles.putAll(workProfilesToRestore);
      if (attendanceLogsToRestore.isNotEmpty) await _isar.attendanceLogs.putAll(attendanceLogsToRestore);
    });
  }
}

