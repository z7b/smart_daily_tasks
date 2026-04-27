import 'package:isar/isar.dart';
import 'package:get/get.dart';
import '../models/appointment_model.dart';
import '../../core/helpers/log_helper.dart';
import '../../core/services/notification_service.dart';

class AppointmentRepository {
  final Isar isar;
  NotificationService get _notifService => Get.find<NotificationService>();

  AppointmentRepository(this.isar);

  /// ✅ Reactive Stream of all active appointments
  Stream<List<Appointment>> listenToAppointments() {
    return isar.appointments
        .where()
        .sortByScheduledAt()
        .watch(fireImmediately: true);
  }

  /// ✅ Fetch upcoming appointments for a specific range
  Future<List<Appointment>> getUpcomingAppointments({int limit = 10}) async {
    return await isar.appointments
        .where()
        .filter()
        .scheduledAtGreaterThan(DateTime.now())
        .and()
        .statusEqualTo(AppointmentStatus.active)
        .sortByScheduledAt()
        .limit(limit)
        .findAll();
  }

  /// ✅ Fetch appointments for a specific day
  Future<List<Appointment>> getAppointmentsForDay(DateTime day) async {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await isar.appointments
        .where()
        .filter()
        .scheduledAtBetween(startOfDay, endOfDay)
        .sortByScheduledAt()
        .findAll();
  }

  /// ✅ Save or update an appointment (H-4 Fix: notifications outside transaction)
  Future<int> saveAppointment(Appointment appointment) async {
    final id = await isar.writeTxn(() async {
      return await isar.appointments.put(appointment);
    });

    // ✅ H-4 Fix: Handle Notifications AFTER successful DB write
    // Cancel 3 possible staged notifications
    await _cancelAllReminders(id, 3);

    if (appointment.remindersEnabled && appointment.status == AppointmentStatus.active) {
      await _notifService.scheduleStagedAppointmentReminders(
        appointmentId: id,
        patientName: appointment.patientName,
        doctorName: appointment.doctorName,
        clinicName: appointment.clinicName ?? '',
        clinicLocation: appointment.clinicLocation ?? '',
        scheduledTime: appointment.scheduledAt,
        alarmEnabled: appointment.alarmEnabled,
      );
    }

    talker.info('🩺 Appointment saved: ${appointment.doctorName} (ID: $id)');
    return id;
  }

  /// ✅ Delete an appointment
  Future<bool> deleteAppointment(int id) async {
    // Get reminder count before deleting
    // We now always use 3 staged offsets
    final offsetCount = 3;

    final success = await isar.writeTxn(() async {
      return await isar.appointments.delete(id);
    });

    if (success) {
      await _cancelAllReminders(id, offsetCount);
      talker.info('🩺 Appointment deleted (ID: $id)');
    }
    return success;
  }

  /// ✅ Update status
  Future<void> updateStatus(int id, AppointmentStatus status) async {
    await isar.writeTxn(() async {
      final appt = await isar.appointments.get(id);
      if (appt != null) {
        final updated = appt.copyWith(status: status);
        await isar.appointments.put(updated);
      }
    });

    if (status != AppointmentStatus.active) {
      await _cancelAllReminders(id, 3); // Cancel the 3 staged offsets
    }
  }

  /// ✅ H-2: Postpone an appointment by a duration
  Future<void> postponeAppointment(int id, Duration postponeBy) async {
    Appointment? updatedAppt;

    await isar.writeTxn(() async {
      final appt = await isar.appointments.get(id);
      if (appt != null) {
        updatedAppt = appt.copyWith(
          scheduledAt: appt.scheduledAt.add(postponeBy),
        );
        await isar.appointments.put(updatedAppt!);
      }
    });

    // Reschedule notifications for the new time
    if (updatedAppt != null) {
      await _cancelAllReminders(id, 3);

      if (updatedAppt!.remindersEnabled && updatedAppt!.status == AppointmentStatus.active) {
        await _notifService.scheduleStagedAppointmentReminders(
          appointmentId: id,
          patientName: updatedAppt!.patientName,
          doctorName: updatedAppt!.doctorName,
          clinicName: updatedAppt!.clinicName ?? '',
          clinicLocation: updatedAppt!.clinicLocation ?? '',
          scheduledTime: updatedAppt!.scheduledAt,
          alarmEnabled: updatedAppt!.alarmEnabled,
        );
      }

      talker.info('🩺 Appointment postponed: ${updatedAppt!.doctorName} → ${updatedAppt!.scheduledAt}');
    }
  }

  /// ✅ Cancel all reminder notifications for an appointment (C-2 safe)
  Future<void> _cancelAllReminders(int appointmentId, int offsetCount) async {
    for (int i = 0; i < offsetCount; i++) {
      await _notifService.cancelNotification(
        NotificationService.appointmentOffset + (appointmentId * 10) + i,
      );
    }
  }
}
