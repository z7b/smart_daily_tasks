import 'package:isar/isar.dart';

part 'task_model.g.dart';

/// Task priority levels
enum TaskPriority { low, medium, high }

/// Task recurrence patterns
enum TaskRecurrence { none, daily, weekly, monthly }

/// Task lifecycle status
enum TaskStatus { active, completed, cancelled }

@collection
class Task {
  Id id = Isar.autoIncrement;

  String title = '';
  String? note;

  @Index()
  DateTime scheduledAt;

  @Index()
  DateTime? scheduledEnd;

  @Index()
  int? color;

  @Index()
  @enumerated
  TaskStatus status = TaskStatus.active;

  /// Task priority (low, medium, high)
  @Index()
  @enumerated
  TaskPriority priority = TaskPriority.medium;

  /// Task recurrence pattern
  @enumerated
  TaskRecurrence recurrence = TaskRecurrence.none;

  /// Tags/categories for the task
  List<String> tags = [];

  DateTime createdAt = DateTime.now();
  DateTime? completedAt;

  @Index()
  bool isNotificationEnabled = true;

  // --- Life OS Intelligence ---

  /// Total duration of the task
  @ignore
  Duration get duration {
    if (scheduledEnd == null) return Duration.zero;
    return scheduledEnd!.difference(scheduledAt);
  }

  /// Progress percentage (0.0 to 1.0) if the task is currently active
  @ignore
  double get progress {
    if (scheduledEnd == null) return 0.0;
    final now = DateTime.now();
    if (now.isBefore(scheduledAt)) return 0.0;
    if (now.isAfter(scheduledEnd!)) return 1.0;
    
    final total = duration.inSeconds;
    if (total == 0) return 1.0;
    final elapsed = now.difference(scheduledAt).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  /// Human-readable time left or status
  @ignore
  String get timeLeft {
    if (status == TaskStatus.completed) return 'task_completed_status';
    if (status == TaskStatus.cancelled) return 'cancelled_status';
    final now = DateTime.now();
    if (now.isAfter(scheduledAt) && (scheduledEnd == null || now.isBefore(scheduledEnd!))) {
      return 'active_now';
    }
    if (now.isAfter(scheduledAt) && scheduledEnd != null && now.isAfter(scheduledEnd!)) {
      return 'overdue';
    }
    
    final diff = scheduledAt.difference(now);
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m left';
    return 'Starting now';
  }

  // Computed property for search
  @Index(type: IndexType.value)
  String get titleLower => title.toLowerCase();

  Task({
    this.id = Isar.autoIncrement,
    required this.title,
    this.note,
    required this.scheduledAt,
    this.scheduledEnd,
    this.color,
    this.status = TaskStatus.active,
    this.priority = TaskPriority.medium,
    this.recurrence = TaskRecurrence.none,
    this.tags = const [],
    this.isNotificationEnabled = true,
    required this.createdAt,
    this.completedAt,
  });

  Task copyWith({
    Id? id,
    String? title,
    String? note,
    DateTime? scheduledAt,
    DateTime? scheduledEnd,
    int? color,
    TaskStatus? status,
    TaskPriority? priority,
    TaskRecurrence? recurrence,
    List<String>? tags,
    bool? isNotificationEnabled,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      color: color ?? this.color,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      recurrence: recurrence ?? this.recurrence,
      tags: tags ?? this.tags,
      isNotificationEnabled: isNotificationEnabled ?? this.isNotificationEnabled,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int? ?? Isar.autoIncrement,
      title: (json['title'] as String?) ?? 'Untitled Task',
      note: json['note'] as String?,
      scheduledAt: json['scheduledAt'] != null 
          ? DateTime.tryParse(json['scheduledAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      scheduledEnd: json['scheduledEnd'] != null 
          ? DateTime.tryParse(json['scheduledEnd'] as String)
          : null,
      color: json['color'] as int?,
      status: json['status'] != null 
          ? TaskStatus.values[(json['status'] as int?)?.clamp(0, 2) ?? 0]
          : (json['isCompleted'] as bool? ?? false) ? TaskStatus.completed : TaskStatus.active,
      priority: TaskPriority.values[(json['priority'] as int?)?.clamp(0, 2) ?? 1],
      recurrence: TaskRecurrence.values[(json['recurrence'] as int?)?.clamp(0, 3) ?? 0],
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : const [],
      isNotificationEnabled: (json['isNotificationEnabled'] as bool?) ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'scheduledAt': scheduledAt.toIso8601String(),
      'scheduledEnd': scheduledEnd?.toIso8601String(),
      'color': color,
      'status': status.index,
      'isCompleted': status == TaskStatus.completed,
      'priority': priority.index,
      'recurrence': recurrence.index,
      'tags': tags,
      'isNotificationEnabled': isNotificationEnabled,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  /// Human-readable priority name
  String get priorityName {
    switch (priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  /// Human-readable recurrence name
  String get recurrenceName {
    switch (recurrence) {
      case TaskRecurrence.none:
        return 'None';
      case TaskRecurrence.daily:
        return 'Daily';
      case TaskRecurrence.weekly:
        return 'Weekly';
      case TaskRecurrence.monthly:
        return 'Monthly';
    }
  }
}
