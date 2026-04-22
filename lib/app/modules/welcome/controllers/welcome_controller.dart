import 'package:get/get.dart';

import 'package:gati/app/routes/app_pages.dart';

class WelcomeController extends GetxController {
  void getStarted() {
    Get.toNamed(Routes.onboarding);
  }

  void goToLogin() {
    Get.offAllNamed(Routes.login);
  }
}
