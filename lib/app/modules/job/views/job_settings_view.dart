import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/job_controller.dart';

class JobSettingsView extends GetView<JobController> {
  const JobSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = controller.profile.value;
    
    // Local state controllers for explicitly typed data
    final titleController = TextEditingController(text: profile.jobTitle);
    final companyController = TextEditingController(text: profile.companyName);
    final positionController = TextEditingController(text: profile.jobPosition);
    final hoursController = TextEditingController(text: (profile.officialWorkHours ?? 8.0).toString());

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('work_settings'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Get.back(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.updateJobSettings(
                title: titleController.text,
                company: companyController.text,
                position: positionController.text,
                officialWorkHours: double.tryParse(hoursController.text),
              );
              Get.back();
              Get.snackbar('success'.tr, 'task_update_success'.tr, snackPosition: SnackPosition.BOTTOM);
            },
            child: Text('save'.tr, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Professional Identity
            _buildSectionHeader(context, CupertinoIcons.briefcase_fill, 'job_title'.tr),
            const SizedBox(height: 16),
            _buildCard(context, [
              _buildTextField(titleController, 'job_title'.tr, CupertinoIcons.tag),
              const Divider(),
              _buildTextField(companyController, 'company'.tr, CupertinoIcons.building_2_fill),
              const Divider(),
              _buildTextField(positionController, 'job_position'.tr, CupertinoIcons.person_badge_minus),
            ]),

            const SizedBox(height: 32),

            // Section 2: Shift Schedule
            _buildSectionHeader(context, CupertinoIcons.clock_fill, 'working_days'.tr),
            const SizedBox(height: 16),
            _buildCard(context, [
              _buildWorkingDaysPicker(context),
              const Divider(),
              _buildGlobalShiftTimes(context),
              const Divider(),
              _buildTextField(hoursController, 'official_work_hours'.tr, CupertinoIcons.timer, isNumber: true),
            ]),

            const SizedBox(height: 32),

            // Section 3: Financial
            _buildSectionHeader(context, CupertinoIcons.money_dollar_circle_fill, 'salary_day'.tr),
            const SizedBox(height: 16),
            _buildCard(context, [
              Obx(() => ListTile(
                leading: const Icon(CupertinoIcons.calendar, color: Colors.grey),
                title: Text('salary_day'.tr),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    controller.profile.value.salaryDay.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ),
                onTap: () => _showSalaryDayPicker(context),
              )),
            ]),

            const SizedBox(height: 32),

            // Section 4: Individual Day Overrides
            _buildSectionHeader(context, CupertinoIcons.clock_fill, 'custom_schedules'.tr),
            const SizedBox(height: 16),
            _buildCustomOverridesList(context),

            const SizedBox(height: 32),

            // Section 5: Preferences
            _buildSectionHeader(context, CupertinoIcons.bell_fill, 'reminders'.tr),
            const SizedBox(height: 16),
            _buildCard(context, [
              Obx(() => SwitchListTile(
                title: Text('shift_reminders'.tr),
                value: controller.profile.value.remindersEnabled,
                onChanged: (val) => controller.updateJobSettings(reminders: val),
                activeColor: AppTheme.primary,
              )),
            ]),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(10)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          icon: Icon(icon, size: 20, color: Colors.grey),
          labelText: label,
          border: InputBorder.none,
          labelStyle: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildWorkingDaysPicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('working_days'.tr, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 12),
          Obx(() => Wrap(
            spacing: 8,
            children: List.generate(7, (i) {
              final isSelected = controller.profile.value.workingDays.contains(i);
              return ChoiceChip(
                label: Text(DateFormat.E().format(DateTime(2024, 1, 7 + i)).substring(0, 2)),
                selected: isSelected,
                onSelected: (val) {
                  final days = List<int>.from(controller.profile.value.workingDays);
                  if (val) days.add(i); else days.remove(i);
                  controller.updateJobSettings(workDays: days);
                },
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(color: isSelected ? Colors.white : null, fontSize: 12),
              );
            }),
          )),
        ],
      ),
    );
  }

  Widget _buildCustomOverridesList(BuildContext context) {
    return Obx(() {
      final workingDays = controller.profile.value.workingDays;
      if (workingDays.isEmpty) return const SizedBox.shrink();

    return Column(
        children: workingDays.map((day) {
          final start = controller.getStartMinutesForDay(day);
          final end = controller.getEndMinutesForDay(day);
          final hasOverride = controller.getCustomSchedules().containsKey(day.toString());
          
          final durationMinutes = end >= start ? (end - start) : ((24 * 60 - start) + end);
          final durationHours = (durationMinutes / 60).toStringAsFixed(1);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: hasOverride 
                      ? AppTheme.primary.withAlpha(80) 
                      : Theme.of(context).dividerColor.withAlpha(20)),
              boxShadow: hasOverride 
                  ? [BoxShadow(color: AppTheme.primary.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))] 
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(CupertinoIcons.calendar_today, size: 18, color: hasOverride ? AppTheme.primary : Colors.grey),
                        const SizedBox(width: 8),
                        Text(DateFormat.EEEE().format(DateTime(2024, 1, 7 + day)), 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: hasOverride ? null : Colors.grey)),
                      ],
                    ),
                    if (hasOverride)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.primary.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                        child: Text('${durationHours}h Shift', style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                      )
                    else 
                      Text('${durationHours}h Shift', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.zero,
                          foregroundColor: hasOverride ? AppTheme.primary : Colors.grey,
                        ),
                        icon: const Icon(CupertinoIcons.sun_min_fill, size: 16),
                        onPressed: () async {
                          final time = await showTimePicker(context: context, initialTime: TimeOfDay(hour: start ~/ 60, minute: start % 60));
                          if (time != null) controller.setCustomSchedule(day, time.hour * 60 + time.minute, end);
                        },
                        label: Text(controller.formatMinutes(start), style: const TextStyle(fontSize: 14)),
                      ),
                    ),
                    const Icon(CupertinoIcons.arrow_right, size: 14, color: Colors.grey),
                    Expanded(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.zero,
                          foregroundColor: hasOverride ? Colors.orange : Colors.grey,
                        ),
                        icon: const Icon(CupertinoIcons.moon_stars_fill, size: 16),
                        onPressed: () async {
                          final time = await showTimePicker(context: context, initialTime: TimeOfDay(hour: end ~/ 60, minute: end % 60));
                          if (time != null) controller.setCustomSchedule(day, start, time.hour * 60 + time.minute);
                        },
                        label: Text(controller.formatMinutes(end), style: const TextStyle(fontSize: 14)),
                      ),
                    ),
                    if (hasOverride)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(CupertinoIcons.clear_circled_solid, size: 20, color: Colors.redAccent),
                        onPressed: () => controller.setCustomSchedule(day, null, null),
                      ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildGlobalShiftTimes(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('start_time'.tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Obx(() => TextButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context, 
                      initialTime: TimeOfDay(hour: controller.profile.value.startMinutes ~/ 60, minute: controller.profile.value.startMinutes % 60)
                    );
                    if (time != null) controller.updateJobSettings(startMin: time.hour * 60 + time.minute);
                  },
                  child: Text(controller.formatMinutes(controller.profile.value.startMinutes), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                )),
              ],
            ),
          ),
          const Icon(CupertinoIcons.arrow_right, color: Colors.grey, size: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('end_time'.tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Obx(() => TextButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context, 
                      initialTime: TimeOfDay(hour: controller.profile.value.endMinutes ~/ 60, minute: controller.profile.value.endMinutes % 60)
                    );
                    if (time != null) controller.updateJobSettings(endMin: time.hour * 60 + time.minute);
                  },
                  child: Text(controller.formatMinutes(controller.profile.value.endMinutes), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSalaryDayPicker(BuildContext context) {
    int tempDay = controller.profile.value.salaryDay;
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Theme.of(context).cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
                  TextButton(
                    onPressed: () {
                      controller.updateJobSettings(salDay: tempDay);
                      Get.back();
                    },
                    child: Text('confirm'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                scrollController: FixedExtentScrollController(initialItem: tempDay - 1),
                onSelectedItemChanged: (index) => tempDay = index + 1,
                children: List.generate(31, (index) => Center(child: Text('${index + 1}'))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
