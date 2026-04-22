import 'package:get/get.dart';
import 'package:gati/app/data/models/sport_gear_model.dart';

class SportGearDetailController extends GetxController {
  final Rx<SportGear?> gear = Rx<SportGear?>(null);

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is SportGear) {
      gear.value = args;
    }
  }

  void viewDeal() {
    // Dummy action for viewing the deal
    Get.snackbar(
      'Redirecting',
      'Opening store link for ${gear.value?.name}...',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
