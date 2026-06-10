import 'package:isar_community/isar.dart';

part 'keep_note_model.g.dart';

// ─── Embedded: مرفق واحد ────────────────────────────────────────────────────

@embedded
class KeepAttachment {
  /// نوع المرفق: 'image', 'video', 'audio', 'drawing'
  String type = '';

  /// مسار نسبي للملف — مثال: 'images/1717200000000.jpg'
  /// المسار الكامل يُبنى وقت الاستخدام:
  ///   final full = '${appDir.path}/keep/${attachment.relativePath}';
  String relativePath = '';

  /// مسار نسبي للصورة المصغّرة (للصور والفيديو فقط)
  String? thumbPath;

  /// مدة التسجيل بالمللي ثانية (للصوت فقط)
  int? durationMs;

  /// ترتيب المرفق داخل الملاحظة
  int sortIndex = 0;
}

// ─── Embedded: عنصر checklist ────────────────────────────────────────────────

@embedded
class KeepCheckItem {
  /// نص العنصر
  String text = '';

  /// هل تم إنجازه
  bool isDone = false;

  /// ترتيب العنصر داخل القائمة
  int sortIndex = 0;
}

// ─── Collection: الملاحظة الرئيسية ──────────────────────────────────────────

@collection
class KeepNote {
  Id id = Isar.autoIncrement;

  // ── المحتوى الأساسي ──────────────────────────────────────────────────────

  /// عنوان الملاحظة
  @Index(type: IndexType.value)
  String title = '';

  /// محتوى نصي فقط (Quill Delta JSON) — بدون مرفقات أو بيانات ثنائية
  String? content;

  /// عناصر الـ Checklist
  List<KeepCheckItem> checkItems = [];

  /// المرفقات (صور، فيديو، صوت، رسم) — metadata فقط، الملفات على القرص
  List<KeepAttachment> attachments = [];

  // ── المظهر ────────────────────────────────────────────────────────────────

  /// فهرس اللون من boardColors (null = اللون الافتراضي)
  int? colorIndex;

  /// فهرس صورة الخلفية من backgroundImages (null = بدون خلفية)
  int? backgroundIndex;

  /// شدة ضبابية الخلفية
  double backgroundBlur = 0.0;

  /// فهرس لون النص من textColors (null = تلقائي)
  int? textColorIndex;

  /// حجم الخط
  double textSize = 16.0;

  /// محاذاة النص: 0=يسار، 1=وسط، 2=يمين، 3=ضبط
  int textAlign = 0;

  /// تنسيقات النص
  bool isBold = false;
  bool isItalic = false;
  bool isUnderline = false;

  // ── التنظيم ───────────────────────────────────────────────────────────────

  /// تثبيت الملاحظة في الأعلى
  bool isPinned = false;

  /// ترتيب يدوي (drag & drop) — double لإمكانية الإدراج بين عنصرين
  double sortOrder = 0.0;

  /// وسوم / تصنيفات
  List<String> tags = [];

  // ── التذكير ───────────────────────────────────────────────────────────────

  /// وقت التذكير (null = بدون تذكير)
  @Index()
  DateTime? reminderAt;

  /// هل تم إطلاق التذكير
  bool reminderDone = false;

  // ── ربط بعناصر أخرى (Pin-to-Board) ───────────────────────────────────────

  /// نوع العنصر المربوط: 'task', 'medication', 'appointment', 'book'
  String? linkedItemType;

  /// معرّف العنصر المربوط في جدوله الأصلي
  int? linkedItemId;

  // ── التواريخ ──────────────────────────────────────────────────────────────

  DateTime createdAt = DateTime.now();
  DateTime? updatedAt;

  // ── Index مركّب للفرز + Pagination ────────────────────────────────────────

  @Index(composite: [CompositeIndex('sortOrder')])
  bool get pinnedSort => isPinned;

  // ── Constructor ───────────────────────────────────────────────────────────

  KeepNote();

  // ── copyWith ──────────────────────────────────────────────────────────────

  KeepNote copyWith({
    Id? id,
    String? title,
    String? content,
    List<KeepCheckItem>? checkItems,
    List<KeepAttachment>? attachments,
    int? colorIndex,
    int? backgroundIndex,
    double? backgroundBlur,
    int? textColorIndex,
    double? textSize,
    int? textAlign,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    bool? isPinned,
    double? sortOrder,
    List<String>? tags,
    DateTime? reminderAt,
    bool? reminderDone,
    String? linkedItemType,
    int? linkedItemId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KeepNote()
      ..id = id ?? this.id
      ..title = title ?? this.title
      ..content = content ?? this.content
      ..checkItems = checkItems ?? this.checkItems
      ..attachments = attachments ?? this.attachments
      ..colorIndex = colorIndex ?? this.colorIndex
      ..backgroundIndex = backgroundIndex ?? this.backgroundIndex
      ..backgroundBlur = backgroundBlur ?? this.backgroundBlur
      ..textColorIndex = textColorIndex ?? this.textColorIndex
      ..textSize = textSize ?? this.textSize
      ..textAlign = textAlign ?? this.textAlign
      ..isBold = isBold ?? this.isBold
      ..isItalic = isItalic ?? this.isItalic
      ..isUnderline = isUnderline ?? this.isUnderline
      ..isPinned = isPinned ?? this.isPinned
      ..sortOrder = sortOrder ?? this.sortOrder
      ..tags = tags ?? this.tags
      ..reminderAt = reminderAt ?? this.reminderAt
      ..reminderDone = reminderDone ?? this.reminderDone
      ..linkedItemType = linkedItemType ?? this.linkedItemType
      ..linkedItemId = linkedItemId ?? this.linkedItemId
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt;
  }
}
