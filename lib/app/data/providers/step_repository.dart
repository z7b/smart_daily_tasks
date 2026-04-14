import 'package:isar/isar.dart';
import 'package:health/health.dart';
import 'package:get_storage/get_storage.dart';
import '../models/step_log_model.dart';
import '../../core/helpers/log_helper.dart';

class StepRepository {
  final Isar _isar;
  final Health _health = Health();
  final _storage = GetStorage();

  int get _currentGoal => _storage.read('daily_step_goal') ?? 10000;

  StepRepository(this._isar);

  Future<void> init() async {
    try {
      // Basic configuration for the singleton
      await _health.configure();
      talker.info('🏥 Health Service Configured');
    } catch (e) {
      talker.error('❌ Health Configuration Error: $e');
    }
  }

  Future<bool> hasPermissions() async {
    return await _health.hasPermissions(_types) ?? false;
  }

  Future<bool> requestPermissions() async {
    return await _health.requestAuthorization(_types);
  }

  // Define the data types we want to read
  final List<HealthDataType> _types = [HealthDataType.STEPS];

  /// Syncs steps from Health sensors for a specific date
  Future<int> syncStepsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    try {
      if (await hasPermissions()) {
        final int? steps = await _health.getTotalStepsInInterval(start, end);
        final stepCount = steps ?? 0;
        return await updateStepsLocally(start, stepCount);
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Step sync error for $date');
    }
    return 0;
  }

  Future<int> updateStepsLocally(
    DateTime date,
    int steps, {
    bool isManual = false,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    int finalSteps = steps;

    await _isar.writeTxn(() async {
      final existing = await _isar.stepLogs
          .filter()
          .dateEqualTo(start)
          .findFirst();
      if (existing != null) {
        // If manual, we add to existing. If sync, we take the sensor count.
        finalSteps = isManual ? (existing.steps + steps) : steps;
        existing.steps = finalSteps;
        if (existing.goal == 10000) existing.goal = _currentGoal;
        await _isar.stepLogs.put(existing);
      } else {
        await _isar.stepLogs.put(
          StepLog(date: start, steps: finalSteps, goal: _currentGoal),
        );
      }
    });
    return finalSteps;
  }

  /// Get steps from local Isar cache
  Future<StepLog?> getStepLog(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    return await _isar.stepLogs.filter().dateEqualTo(start).findFirst();
  }

  /// Get all logs for a range
  Future<List<StepLog>> getLogsInRange(DateTime start, DateTime end) async {
    return await _isar.stepLogs
        .filter()
        .dateBetween(start, end)
        .sortByDateDesc()
        .findAll();
  }

  /// Fetch total steps for years (Summary)
  Future<int> getTotalStepsForAllTime() async {
    final all = await _isar.stepLogs.where().findAll();
    int total = 0;
    for (var log in all) {
      total += log.steps;
    }
    return total;
  }
}
