import 'package:get/get.dart';

import 'package:gati/app/modules/splash/controllers/splash_controller.dart';
import 'package:gati/app/data/repositories/auth_repository.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashController>(
      () => SplashController(Get.find<AuthRepository>()),
    );
  }
}
