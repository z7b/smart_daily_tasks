import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import '../../../data/models/medication_model.dart';
import '../../../core/helpers/log_helper.dart';
import 'package:smart_daily_tasks/app/core/services/notification_service.dart';

class MedicationController extends GetxController {
  final _isar = Get.find<Isar>();
  final medications = <Medication>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    talker.info('💊 MedicationController initialized');
    _loadMedications();
    _isar.medications.watchLazy().listen((_) => _loadMedications());
  }

  Future<void> _loadMedications() async {
    try {
      medications.value = await _isar.medications.where().findAll();
    } catch (e) {
      talker.error('🔴 Error loading medications: $e');
    }
  }

  Future<void> addMedication(Medication med) async {
    if (isLoading.value) return;
    try {
      if (med.name.trim().isEmpty) {
        talker.warning('⚠️ Attempted to add medication with empty name');
        return;
      }
      isLoading.value = true;
      
      final Id id = await _isar.writeTxn(() async {
        return await _isar.medications.put(med);
      });
      
      if (med.isNotificationEnabled) {
        final savedMed = await _isar.medications.get(id);
        if (savedMed != null) {
          _scheduleAllReminders(savedMed);
        }
      }
      
      Get.back();
      _loadMedications(); // Explicit refresh
      Get.snackbar('success'.tr, 'medication_added'.tr);
    } catch (e) {
      talker.error('🔴 Error adding medication: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateMedication(Medication med) async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      
      await _isar.writeTxn(() async {
        await _isar.medications.put(med);
      });
      
      // Reschedule notifications
      _cancelAllReminders(med.id);
      if (med.isNotificationEnabled) {
        _scheduleAllReminders(med);
      }
      
      Get.back();
      _loadMedications();
      Get.snackbar('success'.tr, 'medication_updated'.tr);
    } catch (e) {
      talker.error('🔴 Error updating medication: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ Professional Scheduler Logic
  List<String> generateReminderTimes({
    required TimeOfDay startTime,
    int? frequency, // 1, 2, 3, 4 times a day
    int? intervalHours, // 4, 6, 8, 12 hours
  }) {
    final List<String> times = [];
    
    if (intervalHours != null) {
      int count = 24 ~/ intervalHours;
      for (int i = 0; i < count; i++) {
        final hour = (startTime.hour + (i * intervalHours)) % 24;
        final time = TimeOfDay(hour: hour, minute: startTime.minute);
        times.add(_formatTimeOfDay(time));
      }
    } else if (frequency != null) {
      final interval = 24 ~/ frequency;
      for (int i = 0; i < frequency; i++) {
        final hour = (startTime.hour + (i * interval)) % 24;
        final time = TimeOfDay(hour: hour, minute: startTime.minute);
        times.add(_formatTimeOfDay(time));
      }
    }
    
    return times;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt); // Consistent "08:00 AM" format
  }

  void _scheduleAllReminders(Medication med) {
    for (int i = 0; i < med.reminderTimes.length; i++) {
      final timeStr = med.reminderTimes[i];
      try {
        final time = _parseRobustTime(timeStr); // Robust localized parsing
        
        // Calculate scheduled time for today
        final now = DateTime.now();
        var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        
        // Subtract lead minutes (5m, 10m, etc.)
        scheduledDate = scheduledDate.subtract(Duration(minutes: med.reminderLeadMinutes));

        // If time already passed today, schedule for tomorrow
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        Get.find<NotificationService>().scheduleNotification(
          id: (med.id % 21474836) * 100 + i, // ✅ Professional Collision-Free Mapping
          title: '${'my_medications'.tr}: ${med.name}',
          body: '${med.dosage ?? ""} - ${med.instruction.name.tr}',
          scheduledTime: scheduledDate,
        );
        
        talker.info('⏰ Scheduled: ${med.name} at ${scheduledDate.toString()}');
      } catch (e) {
        talker.error('🔴 Reminder scheduling failed: $e');
      }
    }
  }

  void _cancelAllReminders(int medId) {
    // Cancel all potential slots (0-99) for this med
    for (int i = 0; i < 100; i++) {
      Get.find<NotificationService>().cancelNotification((medId % 21474836) * 100 + i);
    }
  }

  Future<void> recordIntake(Medication med) async {
    final now = DateTime.now();
    final updatedIntake = List<DateTime>.from(med.intakeHistory)..add(now);
    final updatedMed = med.copyWith(intakeHistory: updatedIntake);
    
    await _isar.writeTxn(() async {
      await _isar.medications.put(updatedMed);
    });
    
    Get.snackbar('success'.tr, 'dose_taken'.trParams({'time': DateFormat.jm().format(now)}));
  }

  Future<void> toggleActive(Medication med) async {
    final updated = med.copyWith(isActive: !med.isActive);
    await _isar.writeTxn(() async {
      await _isar.medications.put(updated);
    });
  }

  Future<void> deleteMedication(Medication med) async {
    try {
      _cancelAllReminders(med.id);
      await _isar.writeTxn(() async {
        await _isar.medications.delete(med.id);
      });
      Get.snackbar('success'.tr, 'med_delete_success'.tr);
    } catch (e) {
      talker.error('🔴 Med Delete Error: $e');
      Get.snackbar('error'.tr, 'med_delete_error'.tr);
    }
  }

  TimeOfDay parseTimeStr(String timeStr) {
    try {
      final dt = _parseRobustTime(timeStr);
      return TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (_) {
      return TimeOfDay.now();
    }
  }

  DateTime _parseRobustTime(String timeStr) {
    const english = ['0','1','2','3','4','5','6','7','8','9'];
    const arabic = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    String normalized = timeStr;
    for (int i = 0; i < english.length; i++) {
      normalized = normalized.replaceAll(arabic[i], english[i]);
    }
    normalized = normalized.replaceAll('ص', 'AM').replaceAll('م', 'PM');
    normalized = normalized.replaceAll('صباحاً', 'AM').replaceAll('مساءً', 'PM');
    return DateFormat.jm().parse(normalized);
  }
}
