import 'package:isar/isar.dart';
import 'task_model.dart';

part 'medication_model.g.dart';

enum MedicationType { pill, syrup, injection, cream, drops, other }
enum MedicationInstruction { beforeFood, afterFood, withFood, emptyStomach, beforeSleep, none } // ✅ Added beforeSleep

@collection
class Medication {
  Id id = Isar.autoIncrement;

  @Index()
  String name = '';
  
  @enumerated
  MedicationType type = MedicationType.pill;
  
  String? dosage;
  
  @enumerated
  MedicationInstruction instruction = MedicationInstruction.none;
  
  String? method;
  
  @enumerated
  TaskPriority priority = TaskPriority.medium;
  
  String? description;
  
  DateTime startDate = DateTime.now();
  DateTime? endDate;
  
  List<String> reminderTimes = []; 
  
  @Index()
  bool isActive = true;

  bool isNotificationEnabled = true;
  int reminderLeadMinutes = 0;

  DateTime createdAt = DateTime.now();
  List<DateTime> intakeHistory = [];

  Medication({
    this.id = Isar.autoIncrement,
    required this.name,
    this.type = MedicationType.pill,
    this.dosage,
    this.instruction = MedicationInstruction.none,
    this.method,
    this.priority = TaskPriority.medium,
    this.description,
    required this.startDate,
    this.endDate,
    this.reminderTimes = const [],
    this.isActive = true,
    this.isNotificationEnabled = true,
    this.reminderLeadMinutes = 0,
    required this.createdAt,
    this.intakeHistory = const [],
  });

  int get totalDurationDays {
    if (endDate == null) return -1;
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return end.difference(start).inDays + 1;
  }

  int get remainingDays {
    if (endDate == null) return -1;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    if (today.isAfter(end)) return 0;
    return end.difference(today).inDays + 1;
  }

  // --- Life OS Intelligence ---

  int get todayDoseCount {
    final now = DateTime.now();
    return intakeHistory.where((dt) => 
      dt.year == now.year && dt.month == now.month && dt.day == now.day).length;
  }

  double get todayCompliance {
    if (reminderTimes.isEmpty) return 0.0;
    final progress = todayDoseCount / reminderTimes.length;
    return progress.clamp(0.0, 1.0);
  }

  Medication copyWith({
    Id? id,
    String? name,
    MedicationType? type,
    String? dosage,
    MedicationInstruction? instruction,
    String? method,
    TaskPriority? priority,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? reminderTimes,
    bool? isActive,
    bool? isNotificationEnabled,
    int? reminderLeadMinutes,
    DateTime? createdAt,
    List<DateTime>? intakeHistory,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      dosage: dosage ?? this.dosage,
      instruction: instruction ?? this.instruction,
      method: method ?? this.method,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      isActive: isActive ?? this.isActive,
      isNotificationEnabled: isNotificationEnabled ?? this.isNotificationEnabled,
      reminderLeadMinutes: reminderLeadMinutes ?? this.reminderLeadMinutes,
      createdAt: createdAt ?? this.createdAt,
      intakeHistory: intakeHistory ?? this.intakeHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'dosage': dosage,
      'instruction': instruction.index,
      'method': method,
      'priority': priority.index,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'reminderTimes': reminderTimes,
      'isActive': isActive,
      'isNotificationEnabled': isNotificationEnabled,
      'reminderLeadMinutes': reminderLeadMinutes,
      'createdAt': createdAt.toIso8601String(),
      'intakeHistory': intakeHistory.map((e) => e.toIso8601String()).toList(),
    };
  }
}
