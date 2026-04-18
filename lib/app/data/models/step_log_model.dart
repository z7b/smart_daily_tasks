import 'package:isar/isar.dart';

part 'step_log_model.g.dart';

@collection
class StepLog {
  Id id = Isar.autoIncrement;

  @Index()
  DateTime date; // Normalized to midnight

  int steps;
  int goal;
  bool isManual;
  
  @Index()
  DateTime lastSyncedAt = DateTime.now();

  double get progress => goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0;

  StepLog({
    this.id = Isar.autoIncrement,
    required this.date,
    this.steps = 0,
    this.goal = 10000,
    this.isManual = false,
    DateTime? lastSyncedAt,
  }) : lastSyncedAt = lastSyncedAt ?? DateTime.now();

  StepLog copyWith({
    Id? id,
    DateTime? date,
    int? steps,
    int? goal,
    bool? isManual,
    DateTime? lastSyncedAt,
  }) {
    return StepLog(
      id: id ?? this.id,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      goal: goal ?? this.goal,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'steps': steps,
      'goal': goal,
      'isManual': isManual,
      'lastSyncedAt': lastSyncedAt.toIso8601String(),
    };
  }
}
