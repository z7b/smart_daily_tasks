import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

import '../../../data/models/bookmark_model.dart';
import '../../../data/providers/bookmark_repository.dart';
import '../../../core/helpers/log_helper.dart';

class BookmarksController extends GetxController {
  final BookmarkRepository _repository = Get.find<BookmarkRepository>();

  final bookmarks = <Bookmark>[].obs;
  final filteredBookmarks = <Bookmark>[].obs;
  final categories = <String>[].obs;
  final selectedCategory = Rxn<String>();
  final isLoading = false.obs;
  
  // Form controllers
  final titleController = TextEditingController();
  final urlController = TextEditingController();
  final categoryController = TextEditingController();
  final descriptionController = TextEditingController();

  // Focus nodes
  final titleFocusNode = FocusNode();
  final urlFocusNode = FocusNode();
  final categoryFocusNode = FocusNode();
  final descriptionFocusNode = FocusNode();

  @override
  void onInit() {
    super.onInit();
    // Bind stream from repository to observable list
    bookmarks.bindStream(_repository.watchAllBookmarks());
    talker.info('🔖 BookmarksController initialized');

    // Update filtered list and categories when bookmarks change
    everAll([bookmarks, selectedCategory], (_) {
      updateCategories();
      _applySearchFilter();
    });
  }

  void _applySearchFilter() {
    // If there is no specific search query handled by searchBookmarks,
    // we just default to category filtering
    _filterByCategoryInternal(selectedCategory.value);
  }

  void updateCategories() {
    final cats = <String>{};
    for (var b in bookmarks) {
      if (b.category?.isNotEmpty ?? false) {
        cats.add(b.category!);
      }
    }
    categories.assignAll(cats.toList()..sort());
  }

  Future<void> addBookmark(Bookmark bookmark) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      FocusManager.instance.primaryFocus?.unfocus();
      await Future.delayed(const Duration(milliseconds: 100));

      // 1. Hard Validation - Essential fields
      if (bookmark.title.trim().isEmpty || bookmark.url.trim().isEmpty) {
        _showSnackbar('error'.tr, 'title_url_required'.tr, isError: true);
        return;
      }

      final success = await _repository.addBookmark(bookmark);
      if (success) {
        Get.back();
        _showSnackbar(
          'success'.tr,
          'bookmark_added'.tr,
        );
      } else {
        _showSnackbar('error'.tr, 'Could not save bookmark', isError: true);
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Bookmark creation exception');
      _showSnackbar('error'.tr, 'An unexpected error occurred', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateBookmark(Bookmark bookmark) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      
      // 🛡️ Governance: Validation Alignment
      if (bookmark.title.trim().isEmpty || bookmark.url.trim().isEmpty) {
        _showSnackbar('error'.tr, 'title_required'.tr, isError: true);
        return;
      }

      final success = await _repository.updateBookmark(bookmark);
      if (success) {
        Get.back();
        _showSnackbar(
          'success'.tr,
          'bookmark_updated'.tr,
        );
      } else {
        _showSnackbar('error'.tr, 'Could not update bookmark', isError: true);
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Bookmark update exception');
      _showSnackbar('error'.tr, 'An unexpected error occurred', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  void _showSnackbar(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: isError ? SnackPosition.BOTTOM : SnackPosition.TOP,
      backgroundColor: (isError ? Colors.redAccent : Colors.green).withValues(alpha: 0.1),
      colorText: isError ? Colors.redAccent : Colors.green,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> deleteBookmark(Id id) async {
    try {
      await _repository.deleteBookmark(id);
      _showSnackbar('success'.tr, 'bookmark_deleted'.tr);
    } catch (e) {
      _showSnackbar('error'.tr, 'Failed to delete bookmark', isError: true);
    }
  }

  void filterByCategory(String? category) {
    selectedCategory.value = category;
  }

  void _filterByCategoryInternal(String? category) {
    if (category == null) {
      filteredBookmarks.assignAll(bookmarks);
    } else {
      filteredBookmarks.assignAll(
        bookmarks.where((b) => b.category == category).toList(),
      );
    }
  }

  Future<void> searchBookmarks(String query) async {
    if (query.isEmpty) {
      filterByCategory(selectedCategory.value);
      return;
    }

    try {
      final results = await _repository.searchBookmarks(query);
      filteredBookmarks.assignAll(results);
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Bookmark search failed');
      _showSnackbar('Error'.tr, 'Search failed', isError: true);
    }
  }

  Future<void> openUrl(String url) async {
    try {
      final validUrl = url.startsWith('http') ? url : 'https://$url';
      final uri = Uri.parse(validUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackbar('error'.tr, 'Could not open URL', isError: true);
      }
    } catch (e) {
      _showSnackbar('error'.tr, 'Invalid URL', isError: true);
    }
  }

  void loadBookmarkIntoForm(Bookmark bookmark) {
    titleController.text = bookmark.title;
    urlController.text = bookmark.url;
    categoryController.text = bookmark.category ?? '';
    descriptionController.text = bookmark.description ?? '';
  }

  @override
  void onClose() {
    titleController.dispose();
    urlController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    titleFocusNode.dispose();
    urlFocusNode.dispose();
    categoryFocusNode.dispose();
    descriptionFocusNode.dispose();
    super.onClose();
  }
}
