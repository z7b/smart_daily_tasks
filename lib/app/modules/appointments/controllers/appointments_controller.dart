import 'dart:async';
import 'package:get/get.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/providers/appointment_repository.dart';

class AppointmentsController extends GetxController {
  final _appointmentRepo = Get.find<AppointmentRepository>();

  final upcomingAppointments = <Appointment>[].obs;
  final pastAppointments = <Appointment>[].obs;

  StreamSubscription? _streamSub;

  @override
  void onInit() {
    super.onInit();
    _listenToAppointments();
  }

  /// ✅ M-1 Fix: Single stream, split reactively
  void _listenToAppointments() {
    _streamSub?.cancel();
    _streamSub = _appointmentRepo.listenToAppointments().listen((list) {
      final now = DateTime.now();

      // ✅ M-3 Fix: Proper classification
      // Upcoming = future + active only
      upcomingAppointments.value = list
          .where((a) => a.scheduledAt.isAfter(now) && a.status == AppointmentStatus.active)
          .toList();

      // Past = time has passed (any status) OR status is completed/cancelled (any time)
      pastAppointments.value = list
          .where((a) => a.scheduledAt.isBefore(now) || a.status != AppointmentStatus.active)
          .toList()
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt)); // Most recent first
    });
  }

  void deleteAppointment(int id) async {
    await _appointmentRepo.deleteAppointment(id);
  }

  void markAsCompleted(int id) async {
    await _appointmentRepo.updateStatus(id, AppointmentStatus.completed);
  }

  /// ✅ H-2: Postpone appointment
  void postponeAppointment(int id, Duration postponeBy) async {
    await _appointmentRepo.postponeAppointment(id, postponeBy);
    Get.snackbar('success'.tr, 'appointment_postponed'.tr);
  }

  /// ✅ M-2 Fix: Proper cleanup
  @override
  void onClose() {
    _streamSub?.cancel();
    super.onClose();
  }
}
