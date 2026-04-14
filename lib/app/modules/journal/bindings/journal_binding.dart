import 'package:get/get.dart';

import '../../../data/providers/journal_repository.dart';
import '../controllers/journal_controller.dart';

class JournalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JournalController>(
      () => JournalController(Get.find<JournalRepository>()),
    );
  }
}
