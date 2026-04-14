import 'package:get/get.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // InitialBinding is now clean. 
    // Repositories and Global Services are injected in main.dart or via their respective modules.
    // This prevents the "Permanent Controller" trap where onClose() is called during route transitions.
  }
}
