import 'package:isar/isar.dart';

import 'task_model.dart';
part 'calendar_event_model.g.dart';

@collection
class CalendarEvent {
  Id id = Isar.autoIncrement;

  String title = '';
  String? description;

  @Index()
  DateTime date = DateTime.now();

  DateTime? startTime;
  DateTime? endTime;

  // The link to the actual task
  final linkedTask = IsarLink<Task>();

  int? color;

  DateTime createdAt = DateTime.now();

  // Computed property for search
  @Index(type: IndexType.value)
  String get titleLower => title.toLowerCase();

  /// Temporal integrity validation
  @ignore
  bool get isValidTimeRange {
    if (startTime == null || endTime == null) return true;
    return !endTime!.isBefore(startTime!);
  }

  CalendarEvent({
    this.id = Isar.autoIncrement,
    required this.title,
    this.description,
    required this.date,
    this.startTime,
    this.endTime,
    this.color,
    required this.createdAt,
  });

  CalendarEvent copyWith({
    Id? id,
    String? title,
    String? description,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    int? color,
    DateTime? createdAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as int? ?? Isar.autoIncrement,
      title: (json['title'] as String?) ?? 'Untitled Event',
      description: json['description'] as String?,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'] as String)
          : null,
      color: json['color'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'linkedTaskId': linkedTask.value?.id,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
