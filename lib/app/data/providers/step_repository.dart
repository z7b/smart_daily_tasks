import 'package:isar/isar.dart';
import 'package:get_storage/get_storage.dart';
import '../models/step_log_model.dart';

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
    double? calories,
    double? distance,
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
        existing.isManual = isManual;
        existing.goal = _currentGoal; 
        
        // Only update if values are provided and not zero (to avoid overwriting real data with zeros)
        if (calories != null && calories > 0) existing.calories = calories;
        if (distance != null && distance > 0) existing.distance = distance;
        
        await _isar.stepLogs.put(existing);
      } else {
        await _isar.stepLogs.put(
          StepLog(
            date: start, 
            steps: finalSteps, 
            goal: _currentGoal,
            calories: calories ?? 0.0,
            distance: distance ?? 0.0,
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

  /// SSOT: Watch a specific day's log for reactive UI updates
  Stream<StepLog?> watchStepLog(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    return _isar.stepLogs.filter().dateEqualTo(start).watch(fireImmediately: true).map((list) => list.isNotEmpty ? list.first : null);
  }

  /// SSOT: Pure write endpoint for any StepLog mutation
  Future<void> saveStepLog(StepLog log) async {
    await _isar.writeTxn(() async {
      await _isar.stepLogs.put(log);
    });
  }

  /// Get all logs for a range
  Future<List<StepLog>> getLogsInRange(DateTime start, DateTime end) async {
    // ✅ Concept D2 Fix: Reverse range recovery
    if (start.isAfter(end)) {
      final temp = start;
      start = end;
      end = temp;
    }
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
    // ✅ Concept P1 Fix: Prevent integer wrapping for extreme performance history
    int total = 0;
    for (var log in all) {
      if (log.steps > 0) {
        // Defensive check against overflow (64-bit safe but expert-guided)
        if (total > 9007199254740991 - log.steps) { // Number.MAX_SAFE_INTEGER for JS parity
             total = 9007199254740991; 
             break;
        }
        total += log.steps;
      }
    }
    return total;
  }
}
