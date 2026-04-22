import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:gati/app/data/repositories/auth_repository.dart';
import 'package:gati/app/routes/app_pages.dart';

class LoginController extends GetxController {
  LoginController(this._authRepository);

  final AuthRepository _authRepository;

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> login() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    isLoading.value = true;
    try {
      await _authRepository.login(
        email: emailController.text,
        password: passwordController.text,
      );
      Get.offAllNamed(Routes.home);
    } catch (error) {
      Get.snackbar('Login failed', error.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void goToRegister() {
    Get.toNamed(Routes.register);
  }
}
