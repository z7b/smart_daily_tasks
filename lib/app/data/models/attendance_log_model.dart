import 'package:isar/isar.dart';

part 'attendance_log_model.g.dart';

enum AttendanceStatus { present, absent, sick, leave, holiday }

@collection
class AttendanceLog {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  DateTime date; // Normalized to midnight

  @enumerated
  AttendanceStatus status;

  DateTime? checkInTime;
  DateTime? checkOutTime;

  String? note;

  AttendanceLog({
    this.id = Isar.autoIncrement,
    required this.date,
    this.status = AttendanceStatus.present,
    this.checkInTime,
    this.checkOutTime,
    this.note,
  });

  AttendanceLog copyWith({
    Id? id,
    DateTime? date,
    AttendanceStatus? status,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? note,
  }) {
    return AttendanceLog(
      id: id ?? this.id,
      date: date ?? this.date,
      status: status ?? this.status,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      note: note ?? this.note,
    );
  }

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    return AttendanceLog(
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      status: AttendanceStatus.values[(json['status'] ?? 0).clamp(0, AttendanceStatus.values.length - 1)],
      checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime']) : null,
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'status': status.index,
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'note': note,
    };
  }
}
