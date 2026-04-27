import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/providers/appointment_repository.dart';

class AppointmentFormController extends GetxController {
  final _appointmentRepo = Get.find<AppointmentRepository>();

  final patientNameController = TextEditingController();
  final doctorNameController = TextEditingController();
  final clinicNameController = TextEditingController();
  final clinicLocationController = TextEditingController();
  final noteController = TextEditingController();
  
  final selectedDate = DateTime.now().obs;
  final selectedTime = TimeOfDay.now().obs;
  final reminderEnabled = true.obs;
  final alarmEnabled = false.obs;
  final reminderOffset = 60.obs; // Default 1 hour

  /// ✅ H-1: Edit Mode Support
  final isEditing = false.obs;
  int? _editingId;

  /// ✅ H-1: Load an existing appointment for editing
  void loadAppointment(Appointment appt) {
    isEditing.value = true;
    _editingId = appt.id;
    patientNameController.text = appt.patientName;
    doctorNameController.text = appt.doctorName;
    clinicNameController.text = appt.clinicName ?? '';
    clinicLocationController.text = appt.clinicLocation ?? '';
    noteController.text = appt.note ?? '';
    selectedDate.value = appt.scheduledAt;
    selectedTime.value = TimeOfDay.fromDateTime(appt.scheduledAt);
    reminderEnabled.value = appt.remindersEnabled;
    alarmEnabled.value = appt.alarmEnabled;
    reminderOffset.value = appt.reminderOffsets.isNotEmpty ? appt.reminderOffsets.first : 60;
  }

  void saveAppointment() async {
    if (doctorNameController.text.isEmpty) {
      Get.snackbar('error'.tr, 'please_enter_doctor_name'.tr);
      return;
    }

    final scheduledAt = DateTime(
      selectedDate.value.year,
      selectedDate.value.month,
      selectedDate.value.day,
      selectedTime.value.hour,
      selectedTime.value.minute,
    );

    final appointment = Appointment(
      patientName: patientNameController.text,
      doctorName: doctorNameController.text,
      clinicName: clinicNameController.text.isNotEmpty ? clinicNameController.text : null,
      clinicLocation: clinicLocationController.text.isNotEmpty ? clinicLocationController.text : null,
      note: noteController.text.isNotEmpty ? noteController.text : null,
      scheduledAt: scheduledAt,
      remindersEnabled: reminderEnabled.value,
      alarmEnabled: alarmEnabled.value,
      reminderOffsets: [reminderOffset.value],
    );

    // ✅ H-1: Preserve ID when editing
    if (isEditing.value && _editingId != null) {
      appointment.id = _editingId!;
    }

    await _appointmentRepo.saveAppointment(appointment);
    Get.back();
    Get.snackbar('success'.tr, 'appointment_saved'.tr);
  }

  @override
  void onClose() {
    patientNameController.dispose();
    doctorNameController.dispose();
    clinicNameController.dispose();
    clinicLocationController.dispose();
    noteController.dispose();
    super.onClose();
  }
}
