import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../job/controllers/job_controller.dart';

import '../../keep/controllers/keep_controller.dart';
import '../../../data/providers/keep_repository.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<JobController>(() => JobController());
    Get.lazyPut<KeepController>(() => KeepController(Get.find<KeepRepository>()));
  }
}
