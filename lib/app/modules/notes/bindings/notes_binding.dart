import 'package:get/get.dart';

import '../../../data/providers/note_repository.dart';
import '../controllers/notes_controller.dart';

class NotesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotesController>(
      () => NotesController(Get.find<NoteRepository>()),
    );
  }
}
