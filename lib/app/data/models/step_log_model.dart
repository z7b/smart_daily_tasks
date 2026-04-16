import 'package:isar/isar.dart';

part 'step_log_model.g.dart';

@collection
class StepLog {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  DateTime date; // Normalized to midnight

  int steps;
  int goal;
  bool isManual;

  double get progress => goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0;

  StepLog({
    this.id = Isar.autoIncrement,
    required this.date,
    this.steps = 0,
    this.goal = 10000,
    this.isManual = false,
  });

  StepLog copyWith({
    Id? id,
    DateTime? date,
    int? steps,
    int? goal,
  }) {
    return StepLog(
      id: id ?? this.id,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      goal: goal ?? this.goal,
    );
  }
}
