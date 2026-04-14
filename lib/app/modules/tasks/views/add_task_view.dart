import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/task_controller.dart';
import 'package:smart_daily_tasks/app/data/models/task_model.dart';

class AddTaskView extends GetView<TaskController> {
  const AddTaskView({super.key});

  Task? get _task => Get.arguments as Task?;
  bool get _isEdit => _task != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Get.locale?.languageCode ?? 'en';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'edit_task'.tr : 'add_task'.tr,
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
                  : () => _isEdit ? controller.updateTask(_task!) : controller.addTask(),
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
              onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(controller.noteFocusNode),
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

            // Note Input
            TextFormField(
              controller: controller.noteController,
              focusNode: controller.noteFocusNode,
              maxLines: null,
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                hintText: 'notes_hint'.tr,
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: theme.dividerColor,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                prefixIcon: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: Icon(CupertinoIcons.text_alignleft, color: theme.dividerColor),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              ),
            ),
            const SizedBox(height: 32),

            // Details Grouped Container
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildListTile(
                    context,
                    title: 'date'.tr,
                    icon: CupertinoIcons.calendar,
                    iconColor: const Color(0xFFFF2D55),
                    trailing: Obx(() => Text(
                      DateFormat.yMMMMd(locale).format(controller.selectedDate.value),
                      style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
                    )),
                    onTap: () => _getDateFromUser(context),
                  ),
                  Divider(height: 1, indent: 56, color: theme.dividerColor.withAlpha(20)),
                  _buildListTile(
                    context,
                    title: 'start_time'.tr,
                    icon: CupertinoIcons.time,
                    iconColor: const Color(0xFF007AFF),
                    trailing: Obx(() => Text(
                      controller.startTime.value,
                      style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
                    )),
                    onTap: () => _getTimeFromUser(isStartTime: true, context: context),
                  ),
                  Divider(height: 1, indent: 56, color: theme.dividerColor.withAlpha(20)),
                  _buildListTile(
                    context,
                    title: 'end_time'.tr,
                    icon: CupertinoIcons.time_solid,
                    iconColor: const Color(0xFF5E5CE6),
                    trailing: Obx(() => Text(
                      controller.endTime.value,
                      style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
                    )),
                    onTap: () => _getTimeFromUser(isStartTime: false, context: context),
                  ),
                  Divider(height: 1, indent: 56, color: theme.dividerColor.withAlpha(20)),
                  _buildSwitchTile(
                    context,
                    title: 'remind_me'.tr,
                    icon: CupertinoIcons.bell_fill,
                    iconColor: const Color(0xFF32ADE6),
                    value: controller.isNotificationEnabled,
                  ),
                  Divider(height: 1, indent: 56, color: theme.dividerColor.withAlpha(20)),
                  _buildSwitchTile(
                    context,
                    title: 'daily_recurrence'.tr,
                    icon: CupertinoIcons.repeat,
                    iconColor: const Color(0xFF5856D6),
                    value: RxBool(controller.recurrence.value == TaskRecurrence.daily),
                    onChanged: (val) {
                      controller.recurrence.value = val ? TaskRecurrence.daily : TaskRecurrence.none;
                    },
                  ),
                  Divider(height: 1, indent: 56, color: theme.dividerColor.withAlpha(20)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
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
                        Text('color'.tr, style: const TextStyle(fontSize: 16)),
                        const Spacer(),
                        _colorPalette(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required RxBool value,
    Function(bool)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Obx(() => CupertinoSwitch(
            value: value.value,
            onChanged: onChanged ?? (val) => value.value = val,
            activeColor: AppTheme.primary,
          )),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor.withAlpha(100),
          borderRadius: BorderRadius.circular(10),
        ),
        child: trailing,
      ),
    );
  }

  Future<void> _getDateFromUser(BuildContext context) async {
    DateTime? pickerDate = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime(2015),
      lastDate: DateTime(2121),
    );
    if (pickerDate != null) {
      controller.selectedDate.value = pickerDate;
    }
  }

  Future<void> _getTimeFromUser({
    required bool isStartTime,
    required BuildContext context,
  }) async {
    var pickedTime = await _showTimePicker(context);
    if (pickedTime == null) return;
    if (!context.mounted) return;
    String formatedTime = pickedTime.format(context);
    if (isStartTime) {
      controller.startTime.value = formatedTime;
    } else {
      controller.endTime.value = formatedTime;
    }
  }

  Future<TimeOfDay?> _showTimePicker(BuildContext context) {
    return showTimePicker(
      initialEntryMode: TimePickerEntryMode.input,
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(controller.startTime.value.split(":")[0]) ?? 9,
        minute: int.tryParse(controller.startTime.value.split(":")[1].split(" ")[0]) ?? 30,
      ),
    );
  }

  Widget _colorPalette() {
    return Row(
      children: List.generate(3, (index) {
        return GestureDetector(
          onTap: () => controller.selectedColor.value = index,
          child: Obx(() {
            final isSelected = controller.selectedColor.value == index;
            final colorOptions = [
              const Color(0xFF007AFF),
              const Color(0xFFFF2D55),
              const Color(0xFFFF9500),
            ];
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsetsDirectional.only(start: 8),
              width: isSelected ? 28 : 24,
              height: isSelected ? 28 : 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorOptions[index],
                border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                boxShadow: isSelected
                    ? [BoxShadow(color: colorOptions[index].withAlpha(100), blurRadius: 8)]
                    : null,
              ),
              child: isSelected ? const Icon(Icons.done, color: Colors.white, size: 16) : null,
            );
          }),
        );
      }),
    );
  }
}
