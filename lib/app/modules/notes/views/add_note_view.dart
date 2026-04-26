import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/notes_controller.dart';
import 'package:smart_daily_tasks/app/data/models/note_model.dart';

class AddNoteView extends GetView<NotesController> {
  const AddNoteView({super.key});

  Note? get _note => Get.arguments as Note?;
  bool get _isEdit => _note != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'edit_note'.tr : 'add_note'.tr,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.clear, size: 24),
          onPressed: () {
            FocusScope.of(context).unfocus();
            Future.delayed(const Duration(milliseconds: 100), () => Get.back());
          },
        ),
        actions: [
          Obx(() {
            final isLoading = controller.isLoading.value;
            return TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      if (_isEdit) {
                        controller.updateNote(_note!);
                      } else {
                        controller.addNote();
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CupertinoActivityIndicator(radius: 8),
                    )
                  : Text(
                      _isEdit ? 'update'.tr : 'save'.tr,
                      style: TextStyle(
                        color: isLoading ? theme.disabledColor : AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
            );
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // Title Input
            TextFormField(
              controller: controller.titleController,
              focusNode: controller.titleFocusNode,
              autofocus: true,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
              onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(controller.contentFocusNode),
              decoration: InputDecoration(
                hintText: 'title_hint'.tr,
                hintStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.dividerColor,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 16),
            
            // Color selection
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(CupertinoIcons.paintbrush, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text('color'.tr, style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color)),
                const Spacer(),
                _buildColorPalette(context),
              ],
            ),
            
            Divider(height: 32, color: theme.dividerColor.withValues(alpha: 0.1)),
            
            // Content Input
            TextFormField(
              controller: controller.contentController,
              focusNode: controller.contentFocusNode,
              maxLines: null,
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodyLarge?.color,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'start_writing_hint'.tr,
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: theme.dividerColor,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPalette(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () => controller.selectedColor.value = index,
          child: Obx(() {
            final isSelected = controller.selectedColor.value == index;
            final colorOptions = [
              const Color(0xFFFFF3CD), // Yellow
              const Color(0xFFD1E8FF), // Blue
              const Color(0xFFD4EDDA), // Green
              const Color(0xFFF8D7DA), // Red
              const Color(0xFFE2D9F3), // Purple
            ];
            final darkColors = [
              const Color(0xFF3D3415),
              const Color(0xFF153550),
              const Color(0xFF1A3D22),
              const Color(0xFF3D1A1C),
              const Color(0xFF2D2240),
            ];
            
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final color = isDark ? darkColors[index] : colorOptions[index];

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(left: 8),
              width: isSelected ? 28 : 24,
              height: isSelected ? 28 : 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: isSelected ? Border.all(color: AppTheme.primary, width: 2) : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)]
                    : null,
              ),
              child: isSelected ? const Icon(CupertinoIcons.checkmark_alt, color: AppTheme.primary, size: 16) : null,
            );
          }),
        );
      }),
    );
  }
}
