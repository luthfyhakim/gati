import 'package:get/get.dart';
import 'package:gati/app/modules/sport_gear_detail/controllers/sport_gear_detail_controller.dart';

class SportGearDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SportGearDetailController>(() => SportGearDetailController());
  }
}
