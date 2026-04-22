import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:gati/app/data/repositories/auth_repository.dart';
import 'package:gati/app/routes/app_pages.dart';

class RegisterController extends GetxController {
  RegisterController(this._authRepository);

  final AuthRepository _authRepository;

  final formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final RxBool obscurePassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;
  final RxBool isLoading = false.obs;

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  void goToLogin() {
    Get.back();
  }

  Future<void> register() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }
    isLoading.value = true;
    try {
      await _authRepository.register(
        email: emailController.text,
        password: passwordController.text,
        fullName: fullNameController.text,
      );
      Get.offAllNamed(Routes.home);
    } catch (error) {
      Get.snackbar('Registration failed', error.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
