import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../data/models/journal_model.dart';
import '../../../core/helpers/log_helper.dart';
import '../../../data/providers/journal_repository.dart';
import 'dart:async';
import '../../../core/extensions/string_extensions.dart';

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
  StreamSubscription? _journalsSub;

  // Life OS: Mood Insights (O(1) Memory Stable)
  final moodInsights = <int, int>{}.obs;
  final journalsByDate = <DateTime, Journal>{}.obs;

  void _processJournalData() {
    final counts = <int, int>{};
    final mapByDate = <DateTime, Journal>{};
    
    for (var journal in journals) {
      counts[journal.mood.index] = (counts[journal.mood.index] ?? 0) + 1;
      final midnight = DateTime(journal.date.year, journal.date.month, journal.date.day);
      mapByDate[midnight] = journal;
    }
    
    moodInsights.clear();
    moodInsights.addAll(counts);
    journalsByDate.clear();
    journalsByDate.addAll(mapByDate);
  }

  @override
  void onInit() {
    super.onInit();
    _journalsSub = _repository.watchAllJournals().listen((data) => journals.value = data);
    ever(journals, (_) => _processJournalData());
    debounce(searchQuery, (_) => _applySearchFilter(), time: const Duration(milliseconds: 300));
    ever(journals, (_) => _applySearchFilter());
  }

  void _applySearchFilter() {
    if (searchQuery.value.isEmpty) {
      filteredJournals.assignAll(journals);
      return;
    }
    final query = searchQuery.value.searchNormalized;
    final filtered = journals.where((j) =>
      (j.note?.searchNormalized.contains(query) ?? false)
    ).toList();
    filteredJournals.assignAll(filtered);
  }

  @override
  void onClose() {
    _journalsSub?.cancel();
    noteController.dispose();
    noteFocusNode.dispose();
    super.onClose();
  }

  Journal? getJournalForDate(DateTime date) {
    try {
      final key = DateTime(date.year, date.month, date.day);
      return journalsByDate[key];
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Error finding journal in hash map');
      return null;
    }
  }

  Future<void> addEntry(int moodIndex, String note, DateTime date) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      FocusManager.instance.primaryFocus?.unfocus();
      await Future.delayed(const Duration(milliseconds: 100));

      final validNote = note.trim().isEmpty ? null : note.trim();
      final validMood = Mood.values[moodIndex.clamp(0, 4)];
      
      final success = await _repository.addOrUpdateJournalForDate(date, validMood, validNote);

      if (success) {
        Get.back();
        _showSnackbar('success'.tr, 'journal_entry_saved'.tr);
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
