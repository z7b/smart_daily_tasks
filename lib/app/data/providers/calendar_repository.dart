import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../../core/helpers/log_helper.dart';
import '../models/calendar_event_model.dart';
import '../models/task_model.dart';

class CalendarRepository {
  final Isar _isar;

  CalendarRepository(this._isar) {
    talker.info('📅 CalendarRepository initialized');
  }

  /// Create a new calendar event with success result
  Future<bool> addEvent(CalendarEvent event) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.calendarEvents.put(event);
        await event.linkedTask.save();
      });
      return true;
    } on IsarError catch (e, stack) {
      talker.handle(e, stack, '🔴 Isar Database Error (Add Event)');
      return false;
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Add Event)');
      return false;
    }
  }

  // Read all
  Stream<List<CalendarEvent>> watchAllEvents({int limit = 300}) async* {
    yield* _isar.calendarEvents.where().sortByDateDesc().watch(fireImmediately: true);
  }

  /// Update an existing event with success result
  Future<bool> updateEvent(CalendarEvent event) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.calendarEvents.put(event);
        await event.linkedTask.save();
      });
      return true;
    } on IsarError catch (e, stack) {
      talker.handle(e, stack, '🔴 Isar Database Error (Update Event)');
      return false;
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Update Event)');
      return false;
    }
  }

  // Delete
  Future<void> deleteEvent(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.calendarEvents.delete(id);
    });
  }

  // Search by Date
  Future<List<CalendarEvent>> getEventsForDate(DateTime date) async {
    return await _isar.calendarEvents
        .filter()
        .dateEqualTo(date)
        .findAll();
  }

  // Get all events future
  Future<List<CalendarEvent>> getAllEvents() async {
    return await _isar.calendarEvents.where().sortByDateDesc().findAll();
  }
}
