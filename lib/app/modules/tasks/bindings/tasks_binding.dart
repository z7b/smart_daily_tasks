import 'package:get/get.dart';

import '../../../data/providers/task_repository.dart';
import '../controllers/task_list_controller.dart';
import '../controllers/task_form_controller.dart';

class TasksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TaskListController>(
      () => TaskListController(Get.find<TaskRepository>()),
    );
    Get.lazyPut<TaskFormController>(
      () => TaskFormController(Get.find<TaskRepository>()),
    );
  }
}
