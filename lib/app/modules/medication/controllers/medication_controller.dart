import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import '../../../data/models/medication_model.dart';
import '../../../core/helpers/log_helper.dart';
import 'package:smart_daily_tasks/app/core/services/notification_service.dart';
import '../../../core/helpers/number_extension.dart';
import 'package:get_storage/get_storage.dart';

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
      
      await _loadMedications(); // ✅ Fix: Load data BEFORE navigating back
      Get.back();
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
      _cancelAllReminders(med);
      if (med.isNotificationEnabled) {
        _scheduleAllReminders(med);
      }
      
      await _loadMedications(); // ✅ Fix: Load data BEFORE navigating back
      Get.back();
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
      if (intervalHours <= 0) return times;
      int count = (24 / intervalHours).ceil(); 
      for (int i = 0; i < count; i++) {
        int hour = (startTime.hour + (i * intervalHours)) % 24;
        
        // ✅ Phase 3: Sleep-Zone Clamping (Prevent doses during 00:00 - 05:00)
        // Shift midnight doses to 23:00 (before sleep) or 06:00 (upon waking) depending on proximity
        // ✅ Fix: hour == 0 (midnight) is valid for some medications
        if (hour >= 1 && hour <= 5) {
          hour = hour < 3 ? 23 : 6;
        }
        
        // Prevent duplicate hours after clamping
        final time = TimeOfDay(hour: hour, minute: startTime.minute);
        final formatted = _formatTimeOfDay(time);
        if (!times.contains(formatted)) times.add(formatted);
      }
    } else if (frequency != null) {
      if (frequency <= 0 || frequency > 24) return times;
      // ✅ Phase 3: Spread frequency over Waking Hours (configurable, defaults to 16)
      final int wakingHours = GetStorage().read<int>('wakingHours') ?? 16;  
      final int interval = frequency > 1 ? wakingHours ~/ (frequency - 1) : 0;
      for (int i = 0; i < frequency; i++) {
        int hour = ((startTime.hour + (i * interval)) % 24).toInt();
        final time = TimeOfDay(hour: hour, minute: startTime.minute);
        final formatted = _formatTimeOfDay(time);
        if (!times.contains(formatted)) times.add(formatted);
      }
    }
    
    times.sort((a, b) => _parseRobustTime(a).compareTo(_parseRobustTime(b)));
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
        
        // ✅ Concept A1 Fix: Clamp lead minutes to prevent logical inversion (subtraction adding time)
        int leadMins = med.reminderLeadMinutes.clamp(0, 60);
        if (leadMins != med.reminderLeadMinutes) {
          talker.warning('⚠️ Lead minutes out of 0-60 range for ${med.name}, clamped to $leadMins');
        }
        scheduledDate = scheduledDate.subtract(Duration(minutes: leadMins));

        // If time already passed today, schedule for tomorrow
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        final notifyService = Get.find<NotificationService>();
        final deterministicId = notifyService.getDeterministicId(
          '${med.name}_$timeStr', 
          offset: NotificationService.medOffset
        );

        notifyService.scheduleNotification(
          id: deterministicId, 
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

  void _cancelAllReminders(Medication med) {
    // Phase 4: Use deterministic keys to cancel
    final notifyService = Get.find<NotificationService>();
    for (final timeStr in med.reminderTimes) {
       final deterministicId = notifyService.getDeterministicId(
         '${med.name}_$timeStr', 
         offset: NotificationService.medOffset
       );
       notifyService.cancelNotification(deterministicId);
    }
  }

  Future<void> recordIntake(Medication med) async {
    final now = DateTime.now();
    
    // ✅ Duplicate Request Debounce Logic
    if (med.intakeHistory.isNotEmpty) {
      // Phase 3 Fix: Check against today's intakes to avoid double-logging the exact same dose period
      final todaysIntakes = med.intakeHistory.where((dt) => 
        dt.year == now.year && dt.month == now.month && dt.day == now.day
      ).toList();
      
      if (todaysIntakes.isNotEmpty) {
        final lastIntake = todaysIntakes.last;
        // Debounce boosted to 30 mins to prevent spamming multiple doses accidentally
        // ✅ Fix: Reduced from 30 to 5 min — some meds are taken every 15-20 min
        if (now.difference(lastIntake).inMinutes < 5) {
          talker.warning('⚠️ Duplicate intake ignored (Debounce guard: < 5m).');
          Get.snackbar('warning'.tr, 'duplicate_intake'.tr);
          return;
        }
      }
    }

    final updatedIntake = List<DateTime>.from(med.intakeHistory)..add(now);
    final updatedMed = med.copyWith(intakeHistory: updatedIntake);
    
    await _isar.writeTxn(() async {
      await _isar.medications.put(updatedMed);
    });
    Get.snackbar('success'.tr, 'dose_taken'.trParams({'time': DateFormat.jm().format(now).replaceAll('AM', 'AM'.tr).replaceAll('PM', 'PM'.tr).f}));
  }

  Future<void> toggleActive(Medication med) async {
    final updated = med.copyWith(isActive: !med.isActive);
    await _isar.writeTxn(() async {
      await _isar.medications.put(updated);
    });
  }

  Future<void> deleteMedication(Medication med) async {
    try {
      _cancelAllReminders(med);
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
