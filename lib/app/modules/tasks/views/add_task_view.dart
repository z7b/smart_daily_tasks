import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/task_form_controller.dart';
import 'package:smart_daily_tasks/app/data/models/task_model.dart';
import '../../../core/helpers/number_extension.dart';

class AddTaskView extends GetView<TaskFormController> {
  const AddTaskView({super.key});

  Task? get _task => Get.arguments as Task?;
  bool get _isEdit => _task != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Get.locale?.languageCode ?? 'en';
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          _isEdit ? 'edit_task'.tr : 'add_task'.tr,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        leading: IconButton(
          icon: Icon(CupertinoIcons.clear_circled_solid, size: 26, color: theme.dividerColor),
          onPressed: () {
            FocusScope.of(context).unfocus();
            Future.delayed(const Duration(milliseconds: 100), () => Get.back());
          },
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Input Section ───
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withAlpha(isDark ? 10 : 20),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: controller.titleController,
                            focusNode: controller.titleFocusNode,
                            autofocus: !_isEdit,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: theme.textTheme.titleLarge?.color,
                            ),
                            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(controller.noteFocusNode),
                            decoration: InputDecoration(
                              hintText: 'title_hint'.tr,
                              hintStyle: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: theme.dividerColor.withAlpha(100),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Divider(height: 1, color: theme.dividerColor.withAlpha(20)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: controller.noteController,
                            focusNode: controller.noteFocusNode,
                            maxLines: null,
                            minLines: 3,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: theme.textTheme.bodyLarge?.color?.withAlpha(200),
                            ),
                            decoration: InputDecoration(
                              hintText: 'notes_hint'.tr,
                              hintStyle: TextStyle(
                                fontSize: 16,
                                color: theme.dividerColor.withAlpha(100),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── Schedule Section ───
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withAlpha(isDark ? 10 : 20),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildModernListTile(
                            context,
                            title: 'date'.tr,
                            icon: CupertinoIcons.calendar,
                            iconColor: const Color(0xFFFF2D55),
                            trailing: Obx(() => _buildModernPickerPill(
                              context,
                              DateFormat.yMMMMd(locale).format(controller.selectedDate.value).f,
                            )),
                            onTap: () => _getDateFromUser(context),
                          ),
                          Divider(height: 1, indent: 56, color: theme.dividerColor.withAlpha(20)),
                          _buildModernListTile(
                            context,
                            title: 'start_time'.tr,
                            icon: CupertinoIcons.time,
                            iconColor: const Color(0xFF007AFF),
                            trailing: Obx(() => _buildModernPickerPill(
                              context,
                              controller.startTime.value.format(context).f,
                            )),
                            onTap: () => _getTimeFromUser(isStartTime: true, context: context),
                          ),
                          Divider(height: 1, indent: 56, color: theme.dividerColor.withAlpha(20)),
                          _buildModernListTile(
                            context,
                            title: 'end_time'.tr,
                            icon: CupertinoIcons.time_solid,
                            iconColor: const Color(0xFF5E5CE6),
                            trailing: Obx(() {
                              final start = controller.startTime.value;
                              final end = controller.endTime.value;
                              bool isInvalid = false;
                              final s = DateTime(2000, 1, 1, start.hour, start.minute);
                              final e = DateTime(2000, 1, 1, end.hour, end.minute);
                              if (e.isBefore(s) || e.isAtSameMomentAs(s)) isInvalid = true;

                              return _buildModernPickerPill(
                                context,
                                end.format(context).f,
                                isError: isInvalid,
                              );
                            }),
                            onTap: () => _getTimeFromUser(isStartTime: false, context: context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── Settings Section ───
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withAlpha(isDark ? 10 : 20),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildModernSwitchTile(
                            context,
                            title: 'remind_me'.tr,
                            icon: CupertinoIcons.bell_fill,
                            iconColor: const Color(0xFF32ADE6),
                            valueGetter: () => controller.isNotificationEnabled.value,
                            onChanged: (val) {
                              FocusScope.of(context).unfocus();
                              controller.isNotificationEnabled.value = val;
                            },
                          ),
                          Divider(height: 1, indent: 56, color: theme.dividerColor.withAlpha(20)),
                          _buildModernSwitchTile(
                            context,
                            title: 'daily_recurrence'.tr,
                            icon: CupertinoIcons.repeat,
                            iconColor: const Color(0xFF34C759),
                            valueGetter: () => controller.recurrence.value == TaskRecurrence.daily,
                            onChanged: (val) {
                              FocusScope.of(context).unfocus();
                              controller.recurrence.value = val ? TaskRecurrence.daily : TaskRecurrence.none;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── Color Selection ───
                    _buildModernColorPalette(theme),
                    const SizedBox(height: 40), // Bottom spacing
                  ],
                ),
              ),
            ),
            
            // ─── Sticky Bottom Button ───
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withAlpha(isDark ? 10 : 20),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Obx(() {
                  final isLoading = controller.isLoading.value;
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              _isEdit ? controller.updateTask(_task!) : controller.addTask();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isLoading
                          ? const CupertinoActivityIndicator(color: Colors.white)
                          : Text(
                              _isEdit ? 'update'.tr : 'save'.tr,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernListTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        FocusScope.of(context).unfocus();
        onTap();
      },
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildModernSwitchTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool Function() valueGetter,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Obx(() => CupertinoSwitch(
                value: valueGetter(),
                onChanged: onChanged,
                activeTrackColor: AppTheme.primary,
              )),
        ],
      ),
    );
  }

  Widget _buildModernPickerPill(BuildContext context, String text, {bool isError = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isError 
            ? Colors.red.withAlpha(isDark ? 40 : 20)
            : theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? Colors.red.withAlpha(100) : theme.dividerColor.withAlpha(20),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isError 
              ? Colors.red 
              : theme.textTheme.bodyMedium?.color,
        ),
      ),
    );
  }

  Widget _buildModernColorPalette(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withAlpha(isDark ? 10 : 20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'color'.tr,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.dividerColor),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              return GestureDetector(
                onTap: () {
                  FocusScope.of(Get.context!).unfocus();
                  controller.selectedColor.value = index;
                },
                child: Obx(() {
                  final isSelected = controller.selectedColor.value == index;
                  final colorOptions = [
                    const Color(0xFF007AFF),
                    const Color(0xFFFF2D55),
                    const Color(0xFFFF9500),
                  ];
                  final color = colorOptions[index];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    width: isSelected ? 48 : 36,
                    height: isSelected ? 48 : 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: isSelected ? theme.cardColor : Colors.transparent,
                        width: isSelected ? 3 : 0,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: color.withAlpha(100),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(CupertinoIcons.checkmark_alt, color: Colors.white, size: 20)
                        : null,
                  );
                }),
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _getDateFromUser(BuildContext context) async {
    DateTime? pickerDate = await showDatePicker(
      context: context,
      helpText: 'select_date'.tr,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (pickerDate != null) {
      controller.selectedDate.value = pickerDate;
    }
  }

  Future<void> _getTimeFromUser({
    required bool isStartTime,
    required BuildContext context,
  }) async {
    var pickedTime = await showTimePicker(
      initialEntryMode: TimePickerEntryMode.input,
      context: context,
      initialTime: isStartTime ? controller.startTime.value : controller.endTime.value,
    );
    if (pickedTime == null) return;
    if (isStartTime) {
      controller.startTime.value = pickedTime;
    } else {
      controller.endTime.value = pickedTime;
    }
  }
}
