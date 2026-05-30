import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:isar/isar.dart';


import '../../../core/helpers/bottom_sheet_helper.dart';
import '../controllers/medication_controller.dart';
import '../../../data/models/medication_model.dart';
import '../../../core/helpers/number_extension.dart';
import '../../../widgets/ad_banner_widget.dart';

import 'widgets/medication_tile.dart';

class MedicationView extends GetView<MedicationController> {
  const MedicationView({super.key});

  // ─── Theme Color ──────────────────────────────────────────────
  static const Color _themeColor = Color(0xFFFF3B30); // Medical Red

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── iOS Large-Title AppBar ──────────────────────────
            SliverAppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: _themeColor, size: 22),
                onPressed: () => Get.back(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
                title: Text(
                  'my_medications'.tr,
                  style: TextStyle(
                    color: theme.textTheme.titleLarge?.color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(CupertinoIcons.add_circled_solid,
                      color: _themeColor, size: 28),
                  onPressed: () => _showAddMedicationSheet(context),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // ── Smart Summary Strip ─────────────────────────────
            SliverToBoxAdapter(
              child: Obx(() {
                final meds = controller.medications;
                if (meds.isEmpty) return const SizedBox.shrink();
                final active = meds.where((m) => m.isActive).length;
                final totalCompliance = meds.isEmpty
                    ? 0.0
                    : (meds.fold(0.0, (s, m) => s + m.todayCompliance.clamp(0.0, 1.0)) /
                        meds.length).clamp(0.0, 1.0);

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      _miniChip(
                        icon: CupertinoIcons.capsule,
                        label: '${active.f} ${'active'.tr}',
                        color: _themeColor,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _miniChip(
                          icon: CupertinoIcons.checkmark_circle,
                          label:
                              '${(totalCompliance * 100).toInt().f}% ${'med_today_status'.tr}',
                          color: totalCompliance >= 1.0
                              ? const Color(0xFF34C759)
                              : const Color(0xFFFF9500),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),

            // ── Ad Banner ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: AdBannerWidget(),
              ),
            ),

            // ── Medication List ─────────────────────────────────
            Obx(() {
              if (controller.medications.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF2D55).withValues(alpha: 0.1),
                          ),
                          child: Icon(CupertinoIcons.heart_fill,
                              size: 56,
                              color: const Color(0xFFFF2D55).withValues(alpha: 0.3)),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'add_medication'.tr,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
                  ),
                );
              }

              return SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final med = controller.medications[index];
                      return _buildMedicationCard(context, med, index);
                    },
                    childCount: controller.medications.length,
                  ),
                ),
              );
            }),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ─── Medication Card ──────────────────────────────────────────
  Widget _buildMedicationCard(
      BuildContext context, Medication med, int index) {
    return MedicationTile(
      med: med,
      index: index,
      onDelete: () => controller.deleteMedication(med),
      onRecordIntake: () => controller.recordIntake(med),
      onEdit: () => _showAddMedicationSheet(context, med: med),
    ).animate(delay: Duration(milliseconds: 80 * index)).fadeIn(
        duration: const Duration(milliseconds: 400)).scale(
        begin: const Offset(0.95, 0.95));
  }

  Widget _miniChip(
      {required IconData icon,
      required String label,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────
  String _getTypeText(MedicationType type) {
    switch (type) {
      case MedicationType.pill: return 'pill'.tr;
      case MedicationType.syrup: return 'syrup'.tr;
      case MedicationType.injection: return 'med_injection'.tr;
      case MedicationType.cream: return 'topical'.tr;
      case MedicationType.drops: return 'drops'.tr;
      default: return 'other'.tr;
    }
  }

  String _getInstructionText(MedicationInstruction ins) {
    switch (ins) {
      case MedicationInstruction.beforeFood: return 'before_food'.tr;
      case MedicationInstruction.afterFood: return 'after_food'.tr;
      case MedicationInstruction.withFood: return 'with_food'.tr;
      case MedicationInstruction.emptyStomach: return 'empty_stomach'.tr;
      case MedicationInstruction.beforeSleep: return 'before_sleep'.tr;
      default: return 'normal'.tr;
    }
  }

  // ─── Add / Edit sheet (unchanged logic, improved shell) ───────
  void _showAddMedicationSheet(BuildContext context, {Medication? med}) {
    final isEdit = med != null;
    final nameController = TextEditingController(text: med?.name);
    final dosageController = TextEditingController(text: med?.dosage);
    final selectedType = (med?.type ?? MedicationType.pill).obs;
    final selectedInstruction =
        (med?.instruction ?? MedicationInstruction.none).obs;
    final startDate = (med?.startDate ?? DateTime.now()).obs;
    final rawDuration = med?.totalDurationDays ?? 7;
    final durationDays = (rawDuration > 0 ? rawDuration : 7).obs;
    final notificationsEnabled = (med?.isNotificationEnabled ?? true).obs;
    final scheduleType = 'frequency'.obs;
    final frequencyCount = 1.obs;
    final intervalHours = 8.obs;
    final firstDoseTime = TimeOfDay.now().obs;
    if (isEdit && med.reminderTimes.isNotEmpty) {
      try {
        final time = controller.parseTimeStr(med.reminderTimes.first);
        firstDoseTime.value = time;
      } catch (_) {}
    }
    final reminderTimes = <String>[].obs;
    if (isEdit) reminderTimes.assignAll(med.reminderTimes);

    final theme = Theme.of(context);

    BottomSheetHelper.showSafeBottomSheet(
      isScrollControlled: true,
      builder: (context, setState) => Container(
        height: Get.height * 0.92,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle + title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                          color: theme.dividerColor.withAlpha(60),
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        isEdit ? 'edit_medication'.tr : 'add_medication'.tr,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (isEdit)
                        GestureDetector(
                          onTap: () {
                            controller.deleteMedication(med);
                            Get.back();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFFF3B30).withAlpha(12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(CupertinoIcons.trash,
                                size: 18, color: Color(0xFFFF3B30)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 24),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                            labelText: 'medication_name'.tr,
                            prefixIcon:
                                const Icon(CupertinoIcons.pencil))),
                    const SizedBox(height: 14),
                    TextField(
                        controller: dosageController,
                        decoration: InputDecoration(
                            labelText: 'strength'.tr,
                            prefixIcon:
                                const Icon(CupertinoIcons.lab_flask))),
                    const SizedBox(height: 24),
                    _buildSectionHeader('treatment_duration'.tr, theme),
                    Row(
                      children: [
                        const Icon(CupertinoIcons.calendar,
                            size: 20, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text('duration'.tr,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Obx(() => DropdownButton<int>(
                              value: durationDays.value <= 0
                                  ? 7
                                  : durationDays.value,
                              underline: const SizedBox(),
                              items: ({3, 5, 7, 10, 14, 30, durationDays.value}.toList()..sort())
                                  .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text('${e.f} ${'days'.tr}')))
                                  .toList(),
                              onChanged: (val) =>
                                  durationDays.value = val ?? 7,
                            )),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('med_type'.tr, theme),
                    Obx(() => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: MedicationType.values
                              .map((type) => ChoiceChip(
                                    label: Text(_getTypeText(type)),
                                    selected: selectedType.value == type,
                                    onSelected: (_) =>
                                        selectedType.value = type,
                                  ))
                              .toList(),
                        )),
                    const SizedBox(height: 24),
                    _buildSectionHeader('med_instruction'.tr, theme),
                    Obx(() => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            MedicationInstruction.beforeFood,
                            MedicationInstruction.afterFood,
                            MedicationInstruction.withFood,
                            MedicationInstruction.emptyStomach,
                            MedicationInstruction.beforeSleep,
                            MedicationInstruction.none,
                          ]
                              .map((ins) => ChoiceChip(
                                    label: Text(_getInstructionText(ins)),
                                    selected: selectedInstruction.value == ins,
                                    onSelected: (_) =>
                                        selectedInstruction.value = ins,
                                  ))
                              .toList(),
                        )),
                    const SizedBox(height: 24),
                    _buildSectionHeader('scheduling'.tr, theme),
                    Obx(() => Column(
                          children: [
                            Row(
                              children: [
                                ChoiceChip(
                                  label: Text('frequency'.tr),
                                  selected:
                                      scheduleType.value == 'frequency',
                                  onSelected: (_) =>
                                      scheduleType.value = 'frequency',
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: Text('interval'.tr),
                                  selected:
                                      scheduleType.value == 'interval',
                                  onSelected: (_) =>
                                      scheduleType.value = 'interval',
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (scheduleType.value == 'frequency')
                              Row(
                                children: [
                                  Text('times_per_day'.tr),
                                  const Spacer(),
                                  DropdownButton<int>(
                                    value: frequencyCount.value,
                                    items: ({1, 2, 3, 4, 5, 6, frequencyCount.value}.toList()..sort())
                                        .map((e) => DropdownMenuItem(
                                            value: e,
                                            child:
                                                Text('${e.f} ${'times'.tr}')))
                                        .toList(),
                                    onChanged: (val) {
                                      frequencyCount.value = val ?? 1;
                                      reminderTimes.assignAll(
                                          controller.generateReminderTimes(
                                              startTime:
                                                  firstDoseTime.value,
                                              frequency:
                                                  frequencyCount.value));
                                    },
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Text('every'.tr),
                                  const Spacer(),
                                  DropdownButton<int>(
                                    value: intervalHours.value,
                                    items: ({4, 6, 8, 12, intervalHours.value}.toList()..sort())
                                        .map((e) => DropdownMenuItem(
                                            value: e,
                                            child:
                                                Text('${e.f} ${'hours'.tr}')))
                                        .toList(),
                                    onChanged: (val) {
                                      intervalHours.value = val ?? 8;
                                      reminderTimes.assignAll(
                                          controller.generateReminderTimes(
                                              startTime:
                                                  firstDoseTime.value,
                                              intervalHours:
                                                  intervalHours.value));
                                    },
                                  ),
                                ],
                              ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('first_dose_time'.tr),
                              trailing: Text(
                                  firstDoseTime.value.format(context).replaceAll('AM', 'AM'.tr).replaceAll('PM', 'PM'.tr).f,
                                  style: const TextStyle(
                                      color: _themeColor,
                                      fontWeight: FontWeight.bold)),
                              onTap: () async {
                                final time = await showTimePicker(
                                    context: context,
                                    initialTime: firstDoseTime.value);
                                if (time != null) {
                                  firstDoseTime.value = time;
                                  reminderTimes.assignAll(
                                      controller.generateReminderTimes(
                                          startTime: time,
                                          frequency: scheduleType.value ==
                                                  'frequency'
                                              ? frequencyCount.value
                                              : null,
                                          intervalHours:
                                              scheduleType.value ==
                                                      'interval'
                                                  ? intervalHours.value
                                                  : null));
                                }
                              },
                            ),
                          ],
                        )),
                    const SizedBox(height: 24),
                    _buildSectionHeader('reminders_alerts'.tr, theme),
                    Obx(() => SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text('enable_notifications'.tr),
                          subtitle: Text('will_alert_at'.trParams(
                              {'times': reminderTimes.map((t) => t.replaceAll('AM', 'am_short'.tr).replaceAll('PM', 'pm_short'.tr).f).join(', ')}),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          value: notificationsEnabled.value,
                          onChanged: (val) =>
                              notificationsEnabled.value = val,
                        )),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Save button
            Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 0, 24, MediaQuery.of(context).padding.bottom + 16),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: _themeColor,
                  borderRadius: BorderRadius.circular(16),
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      Get.snackbar('error'.tr, 'title_required'.tr, 
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.redAccent.withAlpha(30),
                        colorText: Colors.redAccent);
                      return;
                    }

                    final endDateValue = startDate.value
                        .add(Duration(days: durationDays.value));
                    final updatedMed = Medication(
                      id: isEdit ? med.id : Isar.autoIncrement,
                      name: nameController.text.trim(),
                      dosage: dosageController.text.trim(),
                      type: selectedType.value,
                      instruction: selectedInstruction.value,
                      startDate: startDate.value,
                      endDate: endDateValue,
                      reminderTimes: reminderTimes.isEmpty
                          ? [firstDoseTime.value.format(context)]
                          : reminderTimes.toList(),
                      isNotificationEnabled: notificationsEnabled.value,
                      createdAt:
                          isEdit ? med.createdAt : DateTime.now(),
                      intakeHistory:
                          isEdit ? med.intakeHistory : [],
                    );
                    if (isEdit) {
                      controller.updateMedication(updatedMed);
                    } else {
                      controller.addMedication(updatedMed);
                    }
                  },
                  child: Text('save'.tr,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: theme.textTheme.bodySmall?.color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
