import 'package:isar/isar.dart';

part 'journal_model.g.dart';

@collection
class Journal {
  Id id = Isar.autoIncrement;

  DateTime date = DateTime.now();

  @Index()
  @enumerated
  Mood mood = Mood.neutral;

  String? note;

  DateTime createdAt = DateTime.now();

  Journal({
    this.id = Isar.autoIncrement,
    required this.date,
    required this.mood,
    this.note,
    required this.createdAt,
  });

  Journal copyWith({
    Id? id,
    DateTime? date,
    Mood? mood,
    String? note,
    DateTime? createdAt,
  }) {
    return Journal(
      id: id ?? this.id,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Journal.fromJson(Map<String, dynamic> json) {
    return Journal(
      id: json['id'] as int? ?? Isar.autoIncrement,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      mood: Mood.values[(json['mood'] as int?)?.clamp(0, 4) ?? 2],
      note: json['note'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood.index,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

enum Mood {
  amazing, // 0
  good, // 1
  neutral, // 2
  bad, // 3
  terrible, // 4
}
