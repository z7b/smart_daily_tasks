import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:isar/isar.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/journal_model.dart';
import '../../../core/helpers/log_helper.dart';

class BookController extends GetxController {
  final _isar = Get.find<Isar>();
  static const platform = MethodChannel('com.example.smart_daily_tasks/security');
  
  final books = <Book>[].obs;
  final isLoading = false.obs;

  StreamSubscription? _watcherSubscription;

  @override
  void onInit() {
    super.onInit();
    talker.info('📚 BookController initialized');
    
    // 🛡️ ANR Fix: Defer initial load to after the first frame is rendered
    // This prevents state mutation during the widget tree's first build cycle.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBooks();
    });
    
    // 🛡️ ANR Fix: Debounce the Isar watcher to prevent rapid-fire rebuilds
    _watcherSubscription = _isar.books.watchLazy()
        .transform(StreamTransformer.fromHandlers(
          handleData: (_, sink) {
            Future.delayed(const Duration(milliseconds: 300), () => sink.add(null));
          },
        ))
        .listen((_) => _loadBooks());
  }

  @override
  void onClose() {
    _watcherSubscription?.cancel();
    super.onClose();
  }

  Future<void> _loadBooks() async {
    try {
      books.value = await _isar.books.where().findAll();
    } catch (e) {
      talker.error('🔴 Error loading books: $e');
    }
  }

  Future<void> pickAndAddBook() async {
    if (isLoading.value) return;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        isLoading.value = true;
        final file = result.files.first;
        final newBook = Book(
          title: file.name.replaceAll('.pdf', ''),
          filePath: file.path,
          createdAt: DateTime.now(),
          totalPages: 100, // Fallback
        );

        await _isar.writeTxn(() async {
          await _isar.books.put(newBook);
        });
        Get.snackbar('success'.tr, 'book_added'.tr);
      }
    } catch (e) {
      talker.error('🔴 Error picking book: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ Pro Fix: Call Native Engine to open PDF securely
  Future<void> openBookFile(Book book) async {
    if (book.filePath == null) {
      Get.snackbar('error'.tr, 'file_not_found'.tr);
      return;
    }

    try {
      talker.info('🚀 Requesting Native PDF Opener for: ${book.title}');
      await platform.invokeMethod('openPdf', {"path": book.filePath});
      
      // Update last read timestamp
      final updated = book.copyWith(lastReadAt: DateTime.now());
      await _isar.writeTxn(() async => await _isar.books.put(updated));
      
    } catch (e) {
      talker.error('🔴 Native PDF opening failed: $e');
      Get.snackbar('error'.tr, 'no_pdf_viewer'.tr);
    }
  }

  Future<void> updateProgress(Book book, int page, int total) async {
    // 🛡️ Governance: Strict Progress Validation
    if (page < 0 || total <= 0 || page > total) {
      Get.snackbar('error'.tr, 'invalid_progress_data'.tr, 
        backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
        colorText: Colors.redAccent);
      return;
    }

    final updated = book.copyWith(
      currentPage: page, 
      totalPages: total, 
      lastReadAt: DateTime.now(),
      isCompleted: page == total,
      completedAt: (page == total && !book.isCompleted) ? DateTime.now() : book.completedAt,
    );
    await _isar.writeTxn(() async => await _isar.books.put(updated));
    talker.info('📚 Progress updated for: ${book.title} ($page/$total)');
  }

  Future<void> updateMetadata(Book book, {String? title, int? totalPages}) async {
    final updated = book.copyWith(
      title: title ?? book.title, 
      totalPages: totalPages ?? book.totalPages
    );
    await _isar.writeTxn(() async => await _isar.books.put(updated));
    Get.snackbar('success'.tr, 'book_updated'.tr);
  }

  Future<void> markAsCompleted(Book book) async {
    final updated = book.copyWith(isCompleted: true, currentPage: book.totalPages, completedAt: DateTime.now());
    await _isar.writeTxn(() async => await _isar.books.put(updated));
    Get.snackbar('success'.tr, 'task_completed'.tr);
  }

  Future<void> setRating(Book book, double rating) async {
    final updated = book.copyWith(rating: rating);
    await _isar.writeTxn(() async => await _isar.books.put(updated));
  }

  Future<void> setMood(Book book, Mood mood) async {
    final updated = book.copyWith(readingMood: mood);
    await _isar.writeTxn(() async => await _isar.books.put(updated));
  }

  Future<void> deleteBook(Book book) async {
    await _isar.writeTxn(() async => await _isar.books.delete(book.id));
  }
}
