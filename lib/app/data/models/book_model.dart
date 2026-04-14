import 'package:isar/isar.dart';
import 'journal_model.dart';

part 'book_model.g.dart';

@collection
class Book {
  Id id = Isar.autoIncrement;

  @Index()
  String title = '';
  
  String? filePath;
  
  int totalPages = 0;
  int currentPage = 0;

  @Index()
  bool isFavorite = false;

  @Index()
  bool isCompleted = false; // ✅ Pro Feature: Track completion

  double rating = 0.0; // 1-5 stars

  @enumerated
  Mood readingMood = Mood.neutral;

  DateTime createdAt = DateTime.now();
  DateTime? lastReadAt;
  DateTime? completedAt; // ✅ Track when it was finished

  Book({
    this.id = Isar.autoIncrement,
    required this.title,
    this.filePath,
    this.totalPages = 0,
    this.currentPage = 0,
    this.isFavorite = false,
    this.isCompleted = false,
    this.rating = 0.0,
    this.readingMood = Mood.neutral,
    required this.createdAt,
    this.lastReadAt,
    this.completedAt,
  });

  Book copyWith({
    Id? id,
    String? title,
    String? filePath,
    int? totalPages,
    int? currentPage,
    bool? isFavorite,
    bool? isCompleted,
    double? rating,
    Mood? readingMood,
    DateTime? createdAt,
    DateTime? lastReadAt,
    DateTime? completedAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      isFavorite: isFavorite ?? this.isFavorite,
      isCompleted: isCompleted ?? this.isCompleted,
      rating: rating ?? this.rating,
      readingMood: readingMood ?? this.readingMood,
      createdAt: createdAt ?? this.createdAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  double get progress => totalPages > 0 ? (currentPage / totalPages) : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'isFavorite': isFavorite,
      'isCompleted': isCompleted,
      'rating': rating,
      'readingMood': readingMood.index,
      'createdAt': createdAt.toIso8601String(),
      'lastReadAt': lastReadAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
