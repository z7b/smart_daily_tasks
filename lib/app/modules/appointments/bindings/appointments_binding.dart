import 'package:get/get.dart';
import '../controllers/appointments_controller.dart';
import '../controllers/appointment_form_controller.dart';

class AppointmentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppointmentsController>(
      () => AppointmentsController(),
    );
    Get.lazyPut<AppointmentFormController>(
      () => AppointmentFormController(),
    );
  }
}
