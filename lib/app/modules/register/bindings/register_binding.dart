import 'package:get/get.dart';

import 'package:gati/app/data/repositories/auth_repository.dart';
import 'package:gati/app/modules/register/controllers/register_controller.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegisterController>(
      () => RegisterController(Get.find<AuthRepository>()),
    );
  }
}
