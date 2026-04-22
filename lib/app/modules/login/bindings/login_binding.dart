import 'package:get/get.dart';

import 'package:gati/app/data/repositories/auth_repository.dart';
import 'package:gati/app/modules/login/controllers/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(
      () => LoginController(Get.find<AuthRepository>()),
    );
  }
}
