import 'package:get/get.dart';

import 'package:gati/app/data/repositories/activity_repository.dart';
import 'package:gati/app/data/repositories/auth_repository.dart';
import 'package:gati/app/modules/activity_detail/controllers/activity_detail_controller.dart';

class ActivityDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ActivityDetailController>(
      () => ActivityDetailController(
        Get.find<ActivityRepository>(),
        Get.find<AuthRepository>(),
      ),
    );
  }
}
