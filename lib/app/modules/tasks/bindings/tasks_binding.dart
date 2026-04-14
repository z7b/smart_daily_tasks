import 'package:get/get.dart';

import '../../../data/providers/task_repository.dart';
import '../controllers/task_controller.dart';

class TasksBinding extends Bindings {
  @override
  void dependencies() {
    // We assume TaskRepository is initialized in main or via a service
    // For now, let's lazy put it here or find it if it's a service.
    // Better to make TaskRepository a Service or put it here.
    // Given the Phase 1 setup used GetxServices, let's treat Repo as something that needs init.
    // For simplicity, we'll create it here.

    Get.lazyPut<TaskController>(
      () => TaskController(Get.find<TaskRepository>()),
    );
  }
}
