import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/job_controller.dart';
import '../../../core/helpers/number_extension.dart';
import '../../../data/models/work_profile_model.dart';

class JobSettingsView extends GetView<JobController> {
  const JobSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = controller.profile.value;
    
    // Local state controllers for explicitly typed data
    final titleController = TextEditingController(text: profile.jobTitle);
    final companyController = TextEditingController(text: profile.companyName);
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
              // Get current status from the toggle state (using profile status for simplicity, 
              // or just calling updateJobSettings with the employed status if they filled the form)
              controller.updateJobSettings(
                employmentStatus: controller.isUnemployed ? EmploymentStatus.unemployed : EmploymentStatus.employed,
                title: titleController.text,
                company: companyController.text,
                officialWorkHours: double.tryParse(hoursController.text),
              );
              Get.back();
              Get.snackbar('success'.tr, 'task_update_success'.tr, snackPosition: SnackPosition.BOTTOM);
            },
            child: Text('save'.tr, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
          ),
        ],
      ),
      body: Obx(() {
        final isUnemployed = controller.isUnemployed;
        
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 0: Employment Status
              _buildSectionHeader(context, CupertinoIcons.person_crop_circle_fill, 'employment_status'.tr),
              const SizedBox(height: 16),
              _buildCard(context, [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.setEmployed(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !isUnemployed ? AppTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'employed'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !isUnemployed ? Colors.white : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Show confirmation before marking as unemployed
                            Get.defaultDialog(
                              title: 'unemployed'.tr,
                              middleText: 'confirm_unemployed'.tr,
                              textConfirm: 'yes'.tr,
                              textCancel: 'cancel'.tr,
                              confirmTextColor: Colors.white,
                              onConfirm: () {
                                controller.setUnemployed();
                                Get.back();
                              },
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isUnemployed ? Colors.grey.withAlpha(50) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'unemployed'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isUnemployed ? theme.textTheme.bodyMedium?.color : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              
              if (!isUnemployed) ...[
                const SizedBox(height: 32),
                // Section 1: Professional Identity
                _buildSectionHeader(context, CupertinoIcons.briefcase_fill, 'job_title'.tr),
                const SizedBox(height: 16),
                _buildCard(context, [
                  _buildTextField(titleController, 'job_title'.tr, CupertinoIcons.tag),
                  const Divider(),
                  _buildTextField(companyController, 'company'.tr, CupertinoIcons.building_2_fill),
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
                    controller.profile.value.salaryDay.f,
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
                activeThumbColor: AppTheme.primary,
              )),
            ]),

              ], // End of employed settings block
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title, 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
                label: Text(DateFormat.E(Get.locale?.languageCode).format(DateTime(2024, 1, 7 + i))),
                selected: isSelected,
                onSelected: (val) {
                  final days = List<int>.from(controller.profile.value.workingDays);
                  if (val) {
                    days.add(i);
                  } else {
                    days.remove(i);
                  }
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
        children: [
          ...workingDays.map((day) {
            final shifts = controller.getShiftsForDay(day);
            final hasOverride = controller.getCustomSchedules().containsKey(day.toString());
            final isHoliday = controller.isDayHoliday(day);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: isHoliday 
                        ? Colors.green.withAlpha(80) 
                        : (hasOverride ? AppTheme.primary.withAlpha(80) : Theme.of(context).dividerColor.withAlpha(20))),
                boxShadow: isHoliday 
                    ? [BoxShadow(color: Colors.green.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))] 
                    : (hasOverride ? [BoxShadow(color: AppTheme.primary.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))] : []),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.calendar_today, size: 18, color: isHoliday ? Colors.green : (hasOverride ? AppTheme.primary : Colors.grey)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                DateFormat.EEEE(Get.locale?.languageCode).format(DateTime(2024, 1, 7 + day)), 
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 15, 
                                  color: (hasOverride || isHoliday) ? null : Colors.grey
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                        CupertinoSlidingSegmentedControl<bool>(
                          groupValue: isHoliday,
                          onValueChanged: (bool? val) {
                            if (val != null) {
                              controller.setCustomShifts(day, shifts, isHoliday: val);
                            }
                          },
                        children: {
                          false: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: FittedBox(fit: BoxFit.scaleDown, child: Text('work_shift'.tr, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
                          true: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: FittedBox(fit: BoxFit.scaleDown, child: Text('holiday'.tr, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isHoliday)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: Colors.green.withAlpha(20), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.tree, size: 18, color: Colors.green),
                          const SizedBox(width: 8),
                          Text('holiday'.tr, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    )
                  else ...[
                    ...shifts.asMap().entries.map((entry) {
                      final i = entry.key;
                      final s = entry.value;
                      final start = s['start'] as int;
                      final end = s['end'] as int;
                      
                      final durationMinutes = end >= start ? (end - start) : ((24 * 60 - start) + end);
                      final durationHours = (durationMinutes / 60).toStringAsFixed(1);
                      
                      return Padding(
                        padding: EdgeInsets.only(bottom: i < shifts.length - 1 ? 12.0 : 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  final time = await showTimePicker(context: context, initialTime: TimeOfDay(hour: start ~/ 60, minute: start % 60));
                                  if (time != null) {
                                    final newShifts = List<Map<String, dynamic>>.from(shifts);
                                    newShifts[i] = {'start': time.hour * 60 + time.minute, 'end': end};
                                    controller.setCustomShifts(day, newShifts, isHoliday: false);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: hasOverride ? AppTheme.primary.withAlpha(15) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: hasOverride ? AppTheme.primary.withAlpha(30) : Theme.of(context).dividerColor.withAlpha(20)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(CupertinoIcons.sun_min_fill, size: 14, color: hasOverride ? AppTheme.primary : Colors.grey),
                                          const SizedBox(width: 4),
                                          Flexible(child: Text('start_time'.tr, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(controller.formatMinutes(start).f, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: hasOverride ? AppTheme.primary : null)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: hasOverride ? AppTheme.primary.withAlpha(20) : Colors.grey.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                              child: Text('${durationHours.f}h', style: TextStyle(fontSize: 10, color: hasOverride ? AppTheme.primary : Colors.grey, fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  final time = await showTimePicker(context: context, initialTime: TimeOfDay(hour: end ~/ 60, minute: end % 60));
                                  if (time != null) {
                                    final newShifts = List<Map<String, dynamic>>.from(shifts);
                                    newShifts[i] = {'start': start, 'end': time.hour * 60 + time.minute};
                                    controller.setCustomShifts(day, newShifts, isHoliday: false);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: hasOverride ? Colors.orange.withAlpha(15) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: hasOverride ? Colors.orange.withAlpha(30) : Theme.of(context).dividerColor.withAlpha(20)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Flexible(child: Text('end_time'.tr, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                                          const SizedBox(width: 4),
                                          Icon(CupertinoIcons.moon_stars_fill, size: 14, color: hasOverride ? Colors.orange : Colors.grey),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(controller.formatMinutes(end).f, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: hasOverride ? Colors.orange : null)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (hasOverride && !isHoliday)
                              IconButton(
                                padding: const EdgeInsets.only(left: 8),
                                constraints: const BoxConstraints(),
                                icon: Icon(shifts.length == 1 ? CupertinoIcons.clear_circled_solid : CupertinoIcons.minus_circle_fill, size: 22, color: Colors.redAccent),
                                onPressed: () {
                                  if (shifts.length == 1) {
                                    controller.setCustomShifts(day, null, isHoliday: null);
                                  } else {
                                    final newShifts = List<Map<String, dynamic>>.from(shifts);
                                    newShifts.removeAt(i);
                                    controller.setCustomShifts(day, newShifts, isHoliday: false);
                                  }
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                    if (!isHoliday && hasOverride)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              final newShifts = List<Map<String, dynamic>>.from(shifts);
                              int newStart = 480; // Default 8:00 AM
                              int newEnd = 1020; // Default 5:00 PM
                              
                              if (newShifts.isNotEmpty) {
                                final lastEnd = newShifts.last['end'] as int;
                                newStart = (lastEnd + 60) % (24 * 60); // Default 1 hour break
                                newEnd = (newStart + 4 * 60) % (24 * 60); // Default 4 hour shift addition
                              }
                              
                              newShifts.add({'start': newStart, 'end': newEnd});
                              controller.setCustomShifts(day, newShifts, isHoliday: false);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(CupertinoIcons.plus_circle, size: 16, color: AppTheme.primary),
                                  const SizedBox(width: 6),
                                  Text('work_shift'.tr, style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            );
          }),
        ],
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
                  child: Text(controller.formatMinutes(controller.profile.value.startMinutes).f, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  child: Text(controller.formatMinutes(controller.profile.value.endMinutes).f, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
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
                children: List.generate(31, (index) => Center(child: Text((index + 1).f))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
