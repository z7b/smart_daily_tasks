import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/bookmark_model.dart';
import 'package:isar/isar.dart';
import '../controllers/bookmarks_controller.dart';

class AddBookmarkView extends GetView<BookmarksController> {
  const AddBookmarkView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Bookmark? existing = Get.arguments is Bookmark ? Get.arguments : null;
    if (existing != null) {
      controller.loadBookmarkIntoForm(existing);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          existing != null ? 'bookmark_updated'.tr : 'bookmark_added'.tr,
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
                    final title = controller.titleController.text.trim();
                    final url = controller.urlController.text.trim();
                    if (title.isEmpty || url.isEmpty) {
                      Get.snackbar('Required', 'Please fill in title and URL', snackPosition: SnackPosition.BOTTOM);
                      return;
                    }

                      final bookmark = Bookmark(
                        id: existing?.id ?? Isar.autoIncrement,
                        title: title,
                        url: url,
                        category: controller.categoryController.text.trim().isEmpty ? null : controller.categoryController.text.trim(),
                        description: controller.descriptionController.text.trim().isEmpty ? null : controller.descriptionController.text.trim(),
                        createdAt: existing?.createdAt ?? DateTime.now(),
                      );

                      if (existing != null) {
                        controller.updateBookmark(bookmark);
                      } else {
                        controller.addBookmark(bookmark);
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CupertinoActivityIndicator(radius: 8),
                    )
                  : Text(
                      'save'.tr,
                      style: const TextStyle(
                        color: AppTheme.primary,
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
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildTextField(
                    context,
                    controller: controller.titleController,
                    focusNode: controller.titleFocusNode,
                    hint: 'title'.tr,
                    icon: CupertinoIcons.bookmark_solid,
                    iconColor: const Color(0xFFFF9500),
                    autofocus: true,
                    onSubmitted: (_) => FocusScope.of(context).requestFocus(controller.urlFocusNode),
                  ),
                  Divider(height: 1, indent: 48, color: theme.dividerColor.withValues(alpha: 0.1)),
                  _buildTextField(
                    context,
                    controller: controller.urlController,
                    focusNode: controller.urlFocusNode,
                    hint: 'url_hint'.tr,
                    icon: CupertinoIcons.link,
                    iconColor: const Color(0xFF007AFF),
                    keyboardType: TextInputType.url,
                    onSubmitted: (_) => FocusScope.of(context).requestFocus(controller.categoryFocusNode),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildTextField(
                    context,
                    controller: controller.categoryController,
                    focusNode: controller.categoryFocusNode,
                    hint: 'category'.tr,
                    icon: CupertinoIcons.folder_solid,
                    iconColor: const Color(0xFF5E5CE6),
                    onSubmitted: (_) => FocusScope.of(context).requestFocus(controller.descriptionFocusNode),
                  ),
                  Divider(height: 1, indent: 48, color: theme.dividerColor.withValues(alpha: 0.1)),
                  _buildTextField(
                    context,
                    controller: controller.descriptionController,
                    focusNode: controller.descriptionFocusNode,
                    hint: 'notes_hint'.tr,
                    icon: CupertinoIcons.text_alignleft,
                    iconColor: const Color(0xFFFF2D55),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    required Color iconColor,
    TextInputType keyboardType = TextInputType.text,
    bool autofocus = false,
    void Function(String)? onSubmitted,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              keyboardType: keyboardType,
              onSubmitted: onSubmitted,
              style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: theme.dividerColor, fontSize: 16),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
