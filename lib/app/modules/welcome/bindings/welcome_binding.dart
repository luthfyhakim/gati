import 'package:get/get.dart';

import 'package:gati/app/modules/welcome/controllers/welcome_controller.dart';

class WelcomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WelcomeController>(() => WelcomeController());
  }
}
