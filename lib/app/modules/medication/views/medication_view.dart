import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/helpers/bottom_sheet_helper.dart';
import '../controllers/medication_controller.dart';
import '../../../data/models/medication_model.dart';
import '../../../data/models/task_model.dart';

class MedicationView extends GetView<MedicationController> {
  const MedicationView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('my_medications'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add_circled_solid, color: AppTheme.primary, size: 28),
            onPressed: () => _showAddMedicationSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.medications.isEmpty) {
          return _buildEmptyState(theme);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: controller.medications.length,
          itemBuilder: (context, index) {
            final med = controller.medications[index];
            return _buildMedicationCard(context, med, index);
          },
        );
      }),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.heart_fill, size: 80, color: Colors.red.withAlpha(50)),
          const SizedBox(height: 16),
          Text('add_medication'.tr, style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildMedicationCard(BuildContext context, Medication med, int index) {
    final theme = Theme.of(context);
    
    // ✅ Pro Fix: Proper Icons Map
    final typeIcons = {
      MedicationType.pill: CupertinoIcons.capsule,
      MedicationType.syrup: Icons.local_drink,
      MedicationType.injection: Icons.vaccines,
      MedicationType.cream: Icons.opacity,
      MedicationType.drops: Icons.water_drop,
      MedicationType.other: Icons.medical_services,
    };

    final isDark = theme.brightness == Brightness.dark;

    return Dismissible(
      key: Key(med.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => controller.deleteMedication(med),
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(24)),
        child: const Icon(CupertinoIcons.trash, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 20 : 5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(typeIcons[med.type] ?? Icons.medication, color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 2),
                        Text(
                          '${_getTypeText(med.type)} • ${_getInstructionText(med.instruction)}',
                          style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ✅ Life OS: Compliance Ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: med.todayCompliance,
                        strokeWidth: 4,
                        backgroundColor: theme.dividerColor.withAlpha(20),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          med.todayCompliance >= 1.0 ? Colors.green : AppTheme.primary,
                        ),
                      ),
                      Text(
                        '${(med.todayCompliance * 100).toInt()}%',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(CupertinoIcons.pencil_circle, color: Colors.grey, size: 24),
                    onPressed: () => _showAddMedicationSheet(context, med: med),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: med.todayCompliance >= 1.0 ? Colors.green.withAlpha(40) : AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () => controller.recordIntake(med),
                    child: Text(
                      'take_dose'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: med.todayCompliance >= 1.0 ? Colors.green : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              if (med.endDate != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text('${'remaining'.tr}: ${med.remainingDays} ${'days'.tr}', style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.1);
  }

  // ✅ Helper for Type Text (Avoiding function names in UI)
  String _getTypeText(MedicationType type) {
    switch (type) {
      case MedicationType.pill: return 'pill'.tr;
      case MedicationType.syrup: return 'syrup'.tr;
      case MedicationType.injection: return 'med_injection'.tr; // Matches message keys
      case MedicationType.cream: return 'topical'.tr;
      case MedicationType.drops: return 'drops'.tr;
      default: return 'other'.tr;
    }
  }

  // ✅ Helper for Instruction Text
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

  void _showAddMedicationSheet(BuildContext context, {Medication? med}) {
    final isEdit = med != null;
    final nameController = TextEditingController(text: med?.name);
    final dosageController = TextEditingController(text: med?.dosage);
    final selectedType = (med?.type ?? MedicationType.pill).obs;
    final selectedInstruction = (med?.instruction ?? MedicationInstruction.none).obs;
    final startDate = (med?.startDate ?? DateTime.now()).obs;
    final durationDays = (med?.totalDurationDays ?? 7).obs;
    final notificationsEnabled = (med?.isNotificationEnabled ?? true).obs;
    
    // Scheduling Logic
    final scheduleType = 'frequency'.obs; // 'frequency' or 'interval'
    final frequencyCount = 1.obs;
    final intervalHours = 8.obs;
    final firstDoseTime = TimeOfDay.now().obs;
    final reminderTimes = <String>[].obs;
    if (isEdit) reminderTimes.assignAll(med!.reminderTimes);

    final theme = Theme.of(context);

    BottomSheetHelper.showSafeBottomSheet(
      builder: (context, setState) => Container(
        height: Get.height * 0.9,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Container(width: 40, height: 5, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: theme.dividerColor.withAlpha(20), borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEdit ? 'edit_medication'.tr : 'add_medication'.tr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    TextField(controller: nameController, decoration: InputDecoration(labelText: 'medication_name'.tr, prefixIcon: const Icon(CupertinoIcons.pencil))),
                    const SizedBox(height: 16),
                    TextField(controller: dosageController, decoration: InputDecoration(labelText: 'strength'.tr, prefixIcon: const Icon(CupertinoIcons.lab_flask))),
                    
                    const SizedBox(height: 24),
                    _buildSectionHeader('treatment_duration'.tr),
                    Row(
                      children: [
                        const Icon(CupertinoIcons.calendar, size: 20, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text('duration'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Obx(() => DropdownButton<int>(
                          value: durationDays.value <= 0 ? 7 : durationDays.value,
                          underline: const SizedBox(),
                          items: [3, 5, 7, 10, 14, 30].map((e) => DropdownMenuItem(value: e, child: Text('$e ${'days'.tr}'))).toList(),
                          onChanged: (val) => durationDays.value = val ?? 7,
                        )),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader('med_type'.tr),
                    Obx(() => Wrap(
                      spacing: 8,
                      children: MedicationType.values.map((type) => ChoiceChip(
                        label: Text(_getTypeText(type)),
                        selected: selectedType.value == type,
                        onSelected: (val) => selectedType.value = type,
                      )).toList(),
                    )),

                    const SizedBox(height: 24),
                    _buildSectionHeader('scheduling'.tr),
                    Obx(() => Column(
                      children: [
                        Row(
                          children: [
                            ChoiceChip(
                              label: Text('frequency'.tr),
                              selected: scheduleType.value == 'frequency',
                              onSelected: (_) => scheduleType.value = 'frequency',
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text('interval'.tr),
                              selected: scheduleType.value == 'interval',
                              onSelected: (_) => scheduleType.value = 'interval',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (scheduleType.value == 'frequency')
                          Row(
                            children: [
                              Text('times_per_day'.tr),
                              const Spacer(),
                              DropdownButton<int>(
                                value: frequencyCount.value,
                                items: [1, 2, 3, 4, 5, 6].map((e) => DropdownMenuItem(value: e, child: Text('$e ${'times'.tr}'))).toList(),
                                onChanged: (val) {
                                  frequencyCount.value = val ?? 1;
                                  reminderTimes.assignAll(controller.generateReminderTimes(startTime: firstDoseTime.value, frequency: frequencyCount.value));
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
                                items: [4, 6, 8, 12].map((e) => DropdownMenuItem(value: e, child: Text('$e ${'hours'.tr}'))).toList(),
                                onChanged: (val) {
                                  intervalHours.value = val ?? 8;
                                  reminderTimes.assignAll(controller.generateReminderTimes(startTime: firstDoseTime.value, intervalHours: intervalHours.value));
                                },
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('first_dose_time'.tr),
                          trailing: Text(firstDoseTime.value.format(context), style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                          onTap: () async {
                            final time = await showTimePicker(context: context, initialTime: firstDoseTime.value);
                            if (time != null) {
                              firstDoseTime.value = time;
                              reminderTimes.assignAll(controller.generateReminderTimes(
                                startTime: time, 
                                frequency: scheduleType.value == 'frequency' ? frequencyCount.value : null,
                                intervalHours: scheduleType.value == 'interval' ? intervalHours.value : null,
                              ));
                            }
                          },
                        ),
                      ],
                    )),

                    const SizedBox(height: 24),
                    _buildSectionHeader('reminders_alerts'.tr),
                    Obx(() => SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text('enable_notifications'.tr),
                      subtitle: Text('will_alert_at'.trParams({'times': reminderTimes.join(', ')})),
                      value: notificationsEnabled.value,
                      onChanged: (val) => notificationsEnabled.value = val,
                    )),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: AppTheme.primary,
                  onPressed: () {
                    final entDateValue = startDate.value.add(Duration(days: durationDays.value));
                    final updatedMed = Medication(
                      id: isEdit ? med!.id : Isar.autoIncrement,
                      name: nameController.text.trim(),
                      dosage: dosageController.text.trim(),
                      type: selectedType.value,
                      instruction: selectedInstruction.value,
                      startDate: startDate.value,
                      endDate: entDateValue,
                      reminderTimes: reminderTimes.isEmpty ? [firstDoseTime.value.format(context)] : reminderTimes.toList(),
                      isNotificationEnabled: notificationsEnabled.value,
                      createdAt: isEdit ? med!.createdAt : DateTime.now(),
                      intakeHistory: isEdit ? med!.intakeHistory : [],
                    );
                    
                    if (isEdit) {
                      controller.updateMedication(updatedMed);
                    } else {
                      controller.addMedication(updatedMed);
                    }
                  },
                  child: Text('save'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
    );
  }
}
