import 'package:isar/isar.dart';

part 'appointment_model.g.dart';

/// Appointment lifecycle status
enum AppointmentStatus { active, completed, cancelled }

@collection
class Appointment {
  Id id = Isar.autoIncrement;

  String patientName = '';
  String doctorName = '';
  String? clinicName;
  String? clinicLocation;
  String? note;

  @Index()
  DateTime scheduledAt;

  @Index()
  @enumerated
  AppointmentStatus status = AppointmentStatus.active;

  /// Whether reminders are enabled for this appointment
  bool remindersEnabled = true;

  /// Whether an exact-time alarm is enabled for this appointment
  bool alarmEnabled = false;

  /// Minutes before the appointment to send a reminder (e.g., 15, 60, 1440)
  List<int> reminderOffsets = const [60]; // Default: 1 hour before

  @Index()
  int? color;

  Appointment({
    this.patientName = '',
    this.doctorName = '',
    this.clinicName,
    this.clinicLocation,
    this.note,
    required this.scheduledAt,
    this.status = AppointmentStatus.active,
    this.remindersEnabled = true,
    this.alarmEnabled = false,
    this.reminderOffsets = const [60],
    this.color,
  });

  Appointment copyWith({
    Id? id,
    String? patientName,
    String? doctorName,
    String? clinicName,
    String? clinicLocation,
    String? note,
    DateTime? scheduledAt,
    AppointmentStatus? status,
    bool? remindersEnabled,
    bool? alarmEnabled,
    List<int>? reminderOffsets,
    int? color,
  }) {
    final newAppt = Appointment(
      patientName: patientName ?? this.patientName,
      doctorName: doctorName ?? this.doctorName,
      clinicName: clinicName ?? this.clinicName,
      clinicLocation: clinicLocation ?? this.clinicLocation,
      note: note ?? this.note,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      reminderOffsets: reminderOffsets ?? this.reminderOffsets,
      color: color ?? this.color,
    );
    newAppt.id = id ?? this.id;
    return newAppt;
  }
}
