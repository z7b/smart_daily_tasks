import 'package:isar/isar.dart';

part 'note_model.g.dart';

@collection
class Note {
  Id id = Isar.autoIncrement;

  String title = '';
  String? content;

  DateTime createdAt = DateTime.now();
  DateTime? updatedAt;

  bool isPinned = false;
  String? category;

  @Index()
  int? color;

  // Computed property for search
  @Index(type: IndexType.value)
  String get titleLower => title.toLowerCase();

  @Index(type: IndexType.value)
  // ✅ Concept A2 Fix: Use distinct marker for null to differentiate from empty strings in Isar indices
  String get contentLower => content?.toLowerCase() ?? '[NULL_MARKER]';

  Note({
    this.id = Isar.autoIncrement,
    required this.title,
    this.content,
    required this.createdAt,
    this.updatedAt,
    this.color,
    this.isPinned = false,
    this.category,
  });

  Note copyWith({
    Id? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? color,
    bool? isPinned,
    String? category,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      category: category ?? this.category,
    );
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as int? ?? Isar.autoIncrement,
      title: (json['title'] as String?) ?? 'Untitled Note',
      content: json['content'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      color: json['color'] as int?,
      isPinned: (json['isPinned'] as bool?) ?? false,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'color': color,
      'isPinned': isPinned,
      'category': category,
    };
  }
}
