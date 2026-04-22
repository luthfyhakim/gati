import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:gati/app/data/services/storage_service.dart';
import 'package:gati/app/routes/app_pages.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  final List<OnboardingPage> pages = [
    OnboardingPage(
      icon: Icons.location_on_outlined,
      title: 'Track Your Route',
      description:
          'Use GPS to track your running, walking, or cycling route in real-time with accurate mapping.',
    ),
    OnboardingPage(
      icon: Icons.timer_outlined,
      title: 'Monitor Your Stats',
      description:
          'View live statistics including distance, duration, and average speed during your activity.',
    ),
    OnboardingPage(
      icon: Icons.history,
      title: 'Review Your History',
      description:
          'Access your complete activity history and review detailed statistics from past workouts.',
    ),
  ];

  bool get isLastPage => currentPage.value == pages.length - 1;

  void onPageChanged(int page) {
    currentPage.value = page;
  }

  void nextPage() {
    if (isLastPage) {
      _completeOnboarding();
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void skip() {
    _completeOnboarding();
  }

  void _completeOnboarding() {
    final storage = Get.find<StorageService>();
    storage.setOnboardingCompleted();
    Get.offAllNamed(Routes.login);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}
