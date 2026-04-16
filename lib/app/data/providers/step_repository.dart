import 'package:isar/isar.dart';
import 'package:get_storage/get_storage.dart';
import '../models/step_log_model.dart';
import '../../core/helpers/log_helper.dart';

class StepRepository {
  final Isar _isar;
  final _storage = GetStorage();

  int get _currentGoal => _storage.read('daily_step_goal') ?? 10000;

  StepRepository(this._isar);

  /// DAO Pattern: Updates total steps in local Isar cache.
  /// If isManual is true, we add to the existing total.
  /// If false (sync), we replace with the sensor count.
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
        finalSteps = isManual ? (existing.steps + steps) : steps;
        existing.steps = finalSteps;
        existing.isManual = isManual; // Tag the log's provenance
        if (existing.goal == 10000) existing.goal = _currentGoal;
        await _isar.stepLogs.put(existing);
      } else {
        await _isar.stepLogs.put(
          StepLog(
            date: start, 
            steps: finalSteps, 
            goal: _currentGoal,
            isManual: isManual,
          ),
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
    final normalStart = DateTime(start.year, start.month, start.day);
    final normalEnd = DateTime(end.year, end.month, end.day).add(const Duration(days: 1));
    return await _isar.stepLogs
        .filter()
        .dateBetween(normalStart, normalEnd, includeLower: true, includeUpper: false)
        .sortByDateDesc()
        .findAll();
  }

  /// Total steps for Lifetime summary
  Future<int> getTotalStepsForAllTime() async {
    final all = await _isar.stepLogs.where().findAll();
    return all.fold<int>(0, (sum, log) => sum + log.steps);
  }
}
