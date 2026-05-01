import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../../../data/models/note_model.dart';
import '../../../data/providers/note_repository.dart';
import '../../../core/helpers/log_helper.dart';
import '../../../core/extensions/string_extensions.dart';

class NotesController extends GetxController {
  final NoteRepository _repository;
  NotesController(this._repository);

  final notes = <Note>[].obs;
  final searchQuery = ''.obs;
  final filteredNotes = <Note>[].obs;

  final titleController = TextEditingController();
  final contentController = TextEditingController();

  final titleFocusNode = FocusNode();
  final contentFocusNode = FocusNode();

  // 0: Blue, 1: Pink, 2: Orange, 3: Green, 4: Purple
  final selectedColor = 0.obs;

  // Filtered list based on search query
  // (Logic moved to _applySearchFilter for efficiency)

  final isLoading = false.obs;
  StreamSubscription? _notesSub;

  @override
  void onInit() {
    super.onInit();
    _notesSub = _repository.watchAllNotes()
        .listen((data) => notes.value = data);
    debounce(searchQuery, (_) => _applySearchFilter(), time: const Duration(milliseconds: 300));
    ever(notes, (_) => _applySearchFilter());
  }

  void _applySearchFilter() {
    if (searchQuery.value.isEmpty) {
      filteredNotes.assignAll(notes);
      return;
    }

    final query = searchQuery.value.searchNormalized;
    final filtered = notes.where((n) {
      return n.title.searchNormalized.contains(query) ||
          (n.content?.searchNormalized.contains(query) ?? false);
    }).toList();
    
    // Sort: Pinned first, then by updatedAt/createdAt desc
    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      final aDate = a.updatedAt ?? a.createdAt;
      final bDate = b.updatedAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });

    filteredNotes.assignAll(filtered);
  }

  void searchNotes(String query) {
    searchQuery.value = query;
  }

  Future<void> addNote() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      FocusManager.instance.primaryFocus?.unfocus();
      await Future.delayed(const Duration(milliseconds: 100));

      final title = titleController.text.trim();
      final content = contentController.text.trim();

      // 1. Hard Validation - Case where both are empty
      if (title.isEmpty && content.isEmpty) {
        _showSnackbar('Required'.tr, 'Please enter a title or some content', isError: true);
        return;
      }

      // 2. Create Note with safe defaults
      final note = Note(
        title: title.isEmpty ? 'Untitled Note' : title,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        color: selectedColor.value,
      );

      // 3. Save with result-driven repository
      final result = await _repository.addNote(note);

      if (result.isSuccess) {
        Get.back();
        _clearForm();
        _showSnackbar('success'.tr, 'note_added'.tr);
      } else {
        _showSnackbar('error'.tr, 'Could not save note to database', isError: true);
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Note creation exception');
      _showSnackbar('error'.tr, 'An unexpected error occurred', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateNote(Note note) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      FocusManager.instance.primaryFocus?.unfocus();
      await Future.delayed(const Duration(milliseconds: 100));

      final title = titleController.text.trim();
      final content = contentController.text.trim();

      if (title.isEmpty && content.isEmpty) return;

      final updatedNote = note.copyWith(
        title: title.isEmpty ? 'Untitled Note' : title,
        content: content,
        updatedAt: DateTime.now(),
        color: selectedColor.value,
      );

      final result = await _repository.updateNote(updatedNote);

      if (result.isSuccess) {
        Get.back();
        _clearForm();
        _showSnackbar('success'.tr, 'note_updated'.tr);
      } else {
        _showSnackbar('error'.tr, 'Could not update note', isError: true);
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Note update exception');
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

  void loadNoteIntoForm(Note note) {
    titleController.text = note.title;
    contentController.text = note.content ?? '';
    selectedColor.value = note.color ?? 0;
  }

  Future<void> deleteNote(int id) async {
    await _repository.deleteNote(id);
  }

  void _clearForm() {
    titleController.clear();
    contentController.clear();
    selectedColor.value = 0;
  }

  Future<void> togglePin(Note note) async {
    try {
      final updatedNote = note.copyWith(isPinned: !note.isPinned);
      await _repository.updateNote(updatedNote);
      talker.info('📌 Note ${note.id} pinned: ${updatedNote.isPinned}');
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Error toggling pin');
    }
  }

  @override
  void onClose() {
    _notesSub?.cancel();
    titleController.dispose();
    contentController.dispose();
    titleFocusNode.dispose();
    contentFocusNode.dispose();
    super.onClose();
  }
}
