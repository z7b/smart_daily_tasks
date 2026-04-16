import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../data/models/journal_model.dart';
import '../../../core/helpers/log_helper.dart';
import '../../../data/providers/journal_repository.dart';

class JournalController extends GetxController {
  final JournalRepository _repository;
  JournalController(this._repository);

  final journals = <Journal>[].obs;

  // For managing the view
  final selectedDate = DateTime.now().obs;
  
  // Search functionality
  final searchQuery = ''.obs;
  final filteredJournals = <Journal>[].obs;
  // Form Controls
  final noteController = TextEditingController();
  final noteFocusNode = FocusNode();

  final isLoading = false.obs;

  // Life OS: Mood Insights
  RxMap<int, int> get moodInsights {
    final counts = <int, int>{};
    for (var journal in journals) {
      counts[journal.mood.index] = (counts[journal.mood.index] ?? 0) + 1;
    }
    return counts.obs;
  }

  @override
  void onInit() {
    super.onInit();
    journals.bindStream(_repository.watchAllJournals());
    everAll([journals, searchQuery], (_) => _applySearchFilter());
  }

  void _applySearchFilter() {
    if (searchQuery.value.isEmpty) {
      filteredJournals.assignAll(journals);
      return;
    }

    final query = searchQuery.value.toLowerCase();
    final filtered = journals.where((j) =>
      (j.note?.toLowerCase().contains(query) ?? false)
    ).toList();
    
    filteredJournals.assignAll(filtered);
  }

  @override
  void onClose() {
    noteController.dispose();
    noteFocusNode.dispose();
    super.onClose();
  }

  Journal? getJournalForDate(DateTime date) {
    try {
      return journals.firstWhereOrNull(
        (element) =>
            element.date.year == date.year &&
            element.date.month == date.month &&
            element.date.day == date.day,
      );
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Error finding journal');
      return null;
    }
  }

  Future<void> addEntry(int moodIndex, String note, DateTime date) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      FocusManager.instance.primaryFocus?.unfocus();
      await Future.delayed(const Duration(milliseconds: 100));

      final existing = getJournalForDate(date);
      
      final journal = Journal(
        id: existing?.id ?? Isar.autoIncrement,
        date: date,
        mood: Mood.values[moodIndex.clamp(0, 4)],
        note: note.trim().isEmpty ? null : note.trim(),
        createdAt: existing?.createdAt ?? DateTime.now(),
      );
      
      bool success;
      if (existing != null) {
        success = await _repository.updateJournal(journal);
      } else {
        success = await _repository.addJournal(journal);
      }

      if (success) {
        Get.back();
        _showSnackbar(
          'success'.tr,
          existing != null ? 'journal_updated_status'.tr : 'journal_entry_saved'.tr,
        );
      } else {
        _showSnackbar('error'.tr, 'journal_save_error'.tr, isError: true);
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Journal entry exception');
      _showSnackbar('error'.tr, 'journal_save_error'.tr, isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteEntry(Journal journal) async {
    try {
      await _repository.deleteJournal(journal.id);
      _showSnackbar(
        'Success'.tr,
        'journal_entry_deleted'.tr,
      );
    } catch (e) {
      _showSnackbar('error'.tr, 'journal_delete_error'.tr, isError: true);
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
}
