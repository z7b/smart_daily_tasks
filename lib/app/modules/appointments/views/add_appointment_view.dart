import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/appointment_form_controller.dart';


class AddAppointmentView extends GetView<AppointmentFormController> {
  const AddAppointmentView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medicalBlue = const Color(0xFF4A90E2);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Obx(() => Text(
          controller.isEditing.value ? 'edit_appointment'.tr : 'add_appointment'.tr,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
          ),
        )),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: controller.patientNameController,
              label: 'patient_name'.tr,
              icon: CupertinoIcons.person_crop_circle,
              theme: theme,
              accentColor: medicalBlue,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: controller.doctorNameController,
              label: 'doctor_name'.tr,
              icon: CupertinoIcons.person_solid,
              theme: theme,
              accentColor: medicalBlue,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: controller.clinicNameController,
              label: 'clinic_name'.tr,
              icon: CupertinoIcons.building_2_fill,
              theme: theme,
              accentColor: medicalBlue,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: controller.clinicLocationController,
              label: 'clinic_location'.tr,
              icon: CupertinoIcons.location_solid,
              theme: theme,
              accentColor: medicalBlue,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: controller.noteController,
              label: 'notes'.tr,
              icon: CupertinoIcons.text_quote,
              theme: theme,
              accentColor: medicalBlue,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('scheduled_at'.tr, theme, medicalBlue),
            const SizedBox(height: 12),
            _buildDateTimePicker(context, theme, medicalBlue),
            const SizedBox(height: 32),
            _buildSectionTitle('reminder'.tr, theme, medicalBlue),
            const SizedBox(height: 12),
            _buildReminderSettings(theme, medicalBlue),
            const SizedBox(height: 48),
            Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [medicalBlue, medicalBlue.withValues(alpha: 0.8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: medicalBlue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: controller.saveAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: Text(
                  'save'.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    required Color accentColor,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: theme.disabledColor, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, size: 20, color: accentColor.withValues(alpha: 0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          floatingLabelStyle: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: accentColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(BuildContext context, ThemeData theme, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildPickerRow(
            icon: CupertinoIcons.calendar,
            label: 'appointment_date'.tr,
            accentColor: accentColor,
            valueWidget: Obx(() => Text(
                  DateFormat.yMMMMd(Get.locale?.languageCode ?? 'en').format(controller.selectedDate.value),
                  style: TextStyle(fontWeight: FontWeight.w800, color: accentColor),
                )),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: controller.selectedDate.value,
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: accentColor,
                        brightness: theme.brightness,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) controller.selectedDate.value = date;
            },
            theme: theme,
          ),
          const Divider(height: 1, indent: 40, endIndent: 20),
          _buildPickerRow(
            icon: CupertinoIcons.time,
            label: 'appointment_time'.tr,
            accentColor: accentColor,
            valueWidget: Obx(() => Text(
                  controller.selectedTime.value.format(context),
                  style: TextStyle(fontWeight: FontWeight.w800, color: accentColor),
                )),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: controller.selectedTime.value,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: accentColor,
                        brightness: theme.brightness,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (time != null) controller.selectedTime.value = time;
            },
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildPickerRow({
    required IconData icon,
    required String label,
    required Widget valueWidget,
    required VoidCallback onTap,
    required ThemeData theme,
    required Color accentColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Icon(icon, size: 20, color: accentColor.withValues(alpha: 0.7)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            valueWidget,
            const SizedBox(width: 8),
            Icon(CupertinoIcons.chevron_right, size: 14, color: theme.disabledColor),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSettings(ThemeData theme, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(CupertinoIcons.bell_fill, size: 20, color: accentColor.withValues(alpha: 0.7)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'reminder'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Obx(() => CupertinoSwitch(
                      value: controller.reminderEnabled.value,
                      onChanged: (v) => controller.reminderEnabled.value = v,
                      activeTrackColor: accentColor,
                    )),
              ],
            ),
          ),
          Obx(() {
            if (!controller.reminderEnabled.value) return const SizedBox.shrink();
            return Column(
              children: [
                const Divider(height: 1, indent: 40, endIndent: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.alarm_fill, size: 20, color: theme.disabledColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text('enable_alarm'.tr, style: TextStyle(color: theme.disabledColor, fontWeight: FontWeight.w600)),
                      ),
                      Obx(() => CupertinoSwitch(
                            value: controller.alarmEnabled.value,
                            onChanged: (v) => controller.alarmEnabled.value = v,
                            activeTrackColor: accentColor,
                          )),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
