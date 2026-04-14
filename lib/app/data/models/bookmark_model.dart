import 'package:isar/isar.dart';

part 'bookmark_model.g.dart';

@collection
class Bookmark {
  Id id = Isar.autoIncrement;

  String title = '';
  String url = '';

  @Index()
  String? category;

  String? description;

  List<String> tags = [];

  DateTime createdAt = DateTime.now();
  DateTime? updatedAt;

  // Computed property for search
  @Index(type: IndexType.value)
  String get titleLower => title.toLowerCase();

  Bookmark({
    this.id = Isar.autoIncrement,
    required this.title,
    required this.url,
    this.category,
    this.description,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
  });

  Bookmark copyWith({
    Id? id,
    String? title,
    String? url,
    String? category,
    String? description,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      category: category ?? this.category,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as int? ?? Isar.autoIncrement,
      title: (json['title'] as String?) ?? 'Untitled Bookmark',
      url: (json['url'] as String?) ?? '',
      category: json['category'] as String?,
      description: json['description'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'category': category,
      'description': description,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
