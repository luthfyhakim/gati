import 'package:get/get.dart';

import 'package:gati/app/data/repositories/activity_repository.dart';
import 'package:gati/app/data/repositories/auth_repository.dart';
import 'package:gati/app/data/services/tracking_service.dart';
import 'package:gati/app/modules/tracking/controllers/tracking_controller.dart';

class TrackingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TrackingController>(
      () => TrackingController(
        Get.find<TrackingService>(),
        Get.find<ActivityRepository>(),
        Get.find<AuthRepository>(),
      ),
    );
  }
}
