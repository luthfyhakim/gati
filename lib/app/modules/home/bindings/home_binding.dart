import 'package:get/get.dart';

import 'package:gati/app/data/repositories/activity_repository.dart';
import 'package:gati/app/data/repositories/auth_repository.dart';
import 'package:gati/app/data/services/sport_gear_service.dart';
import 'package:gati/app/modules/home/controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      () => HomeController(
        Get.find<AuthRepository>(),
        Get.find<ActivityRepository>(),
        Get.find<SportGearService>(),
      ),
    );
  }
}
