import 'package:isar/isar.dart';

part 'work_profile_model.g.dart';

@collection
class WorkProfile {
  Id id = 0; // Singleton pattern for settings

  String? jobTitle;
  String? jobPosition;
  String? companyName;
  
  // Working Hours (Stored as minutes from midnight for easy calculation)
  int startMinutes;
  int endMinutes;

  // JSON string for custom day schedules: { "dayIndex": { "start": min, "end": min } }
  String? customSchedulesJson;

  // Salary Configuration
  int salaryDay; // 1-31
  double? monthlySalary;

  // Working Days (0 = Sunday, 1 = Monday, ..., 6 = Saturday)
  List<int> workingDays;

  bool remindersEnabled;

  WorkProfile({
    this.id = 0,
    this.jobTitle,
    this.jobPosition,
    this.companyName,
    this.startMinutes = 540, // 09:00
    this.endMinutes = 1020,  // 17:00
    this.customSchedulesJson,
    this.salaryDay = 25,
    this.monthlySalary,
    this.workingDays = const [1, 2, 3, 4, 5], // Mon-Fri
    this.remindersEnabled = true,
  });

  WorkProfile copyWith({
    Id? id,
    String? jobTitle,
    String? jobPosition,
    String? companyName,
    int? startMinutes,
    int? endMinutes,
    String? customSchedulesJson,
    int? salaryDay,
    double? monthlySalary,
    List<int>? workingDays,
    bool? remindersEnabled,
  }) {
    return WorkProfile(
      id: id ?? this.id,
      jobTitle: jobTitle ?? this.jobTitle,
      jobPosition: jobPosition ?? this.jobPosition,
      companyName: companyName ?? this.companyName,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      customSchedulesJson: customSchedulesJson ?? this.customSchedulesJson,
      salaryDay: salaryDay ?? this.salaryDay,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      workingDays: workingDays ?? this.workingDays,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    );
  }
}
