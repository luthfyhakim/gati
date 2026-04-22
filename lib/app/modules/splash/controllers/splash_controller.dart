import 'package:get/get.dart';

import 'package:gati/app/data/repositories/auth_repository.dart';
import 'package:gati/app/data/services/storage_service.dart';
import 'package:gati/app/routes/app_pages.dart';

class SplashController extends GetxController {
  SplashController(this._authRepository);

  final AuthRepository _authRepository;

  final RxBool isBusy = true.obs;

  @override
  void onInit() {
    super.onInit();
    Future.delayed(const Duration(milliseconds: 100), _resolveNavigation);
  }

  Future<void> _resolveNavigation() async {
    try {
      final storage = Get.find<StorageService>();
      final hasCompletedOnboarding = storage.isOnboardingCompleted();
      final hasSession = await _authRepository.hasActiveSession();

      await Future.delayed(const Duration(milliseconds: 650));

      if (hasSession) {
        // User is logged in, go to home
        Get.offAllNamed(Routes.home);
      } else if (!hasCompletedOnboarding) {
        // First time user, show welcome screen
        Get.offAllNamed(Routes.welcome);
      } else {
        // Returning user but not logged in, go to login
        Get.offAllNamed(Routes.login);
      }
    } catch (error) {
      Get.snackbar('Startup error', error.toString());
      Get.offAllNamed(Routes.login);
    } finally {
      isBusy.value = false;
    }
  }
}
