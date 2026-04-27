import 'package:isar/isar.dart';

part 'work_profile_model.g.dart';

enum EmploymentStatus { notConfigured, employed, unemployed }

@collection
class WorkProfile {
  Id id = 0; // Singleton pattern for settings

  @enumerated
  EmploymentStatus employmentStatus;

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
  double? officialWorkHours; // Target hours for performance calculation

  WorkProfile({
    this.id = 0,
    this.employmentStatus = EmploymentStatus.notConfigured,
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
    this.officialWorkHours = 8.0,
  });

  WorkProfile copyWith({
    Id? id,
    EmploymentStatus? employmentStatus,
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
    double? officialWorkHours,
  }) {
    return WorkProfile(
      id: id ?? this.id,
      employmentStatus: employmentStatus ?? this.employmentStatus,
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
      officialWorkHours: officialWorkHours ?? this.officialWorkHours,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employmentStatus': employmentStatus.index,
      'jobTitle': jobTitle,
      'jobPosition': jobPosition,
      'companyName': companyName,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'customSchedulesJson': customSchedulesJson,
      'salaryDay': salaryDay,
      'monthlySalary': monthlySalary,
      'workingDays': workingDays,
      'remindersEnabled': remindersEnabled,
      'officialWorkHours': officialWorkHours,
    };
  }
}
