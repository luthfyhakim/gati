import 'package:get/get.dart';

import 'package:gati/app/modules/activity_detail/bindings/activity_detail_binding.dart';
import 'package:gati/app/modules/activity_detail/views/activity_detail_view.dart';
import 'package:gati/app/modules/home/bindings/home_binding.dart';
import 'package:gati/app/modules/home/views/home_view.dart';
import 'package:gati/app/modules/login/bindings/login_binding.dart';
import 'package:gati/app/modules/login/views/login_view.dart';
import 'package:gati/app/modules/onboarding/bindings/onboarding_binding.dart';
import 'package:gati/app/modules/onboarding/views/onboarding_view.dart';
import 'package:gati/app/modules/register/bindings/register_binding.dart';
import 'package:gati/app/modules/register/views/register_view.dart';
import 'package:gati/app/modules/sport_gear_detail/bindings/sport_gear_detail_binding.dart';
import 'package:gati/app/modules/sport_gear_detail/views/sport_gear_detail_view.dart';
import 'package:gati/app/modules/tracking/bindings/tracking_binding.dart';
import 'package:gati/app/modules/tracking/views/tracking_view.dart';
import 'package:gati/app/modules/welcome/bindings/welcome_binding.dart';
import 'package:gati/app/modules/welcome/views/welcome_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.welcome;

  static final routes = [
    GetPage(
      name: _Paths.welcome,
      page: () => const WelcomeView(),
      binding: WelcomeBinding(),
    ),
    GetPage(
      name: _Paths.onboarding,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: _Paths.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.register,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: _Paths.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.tracking,
      page: () => const TrackingView(),
      binding: TrackingBinding(),
    ),
    GetPage(
      name: _Paths.activityDetail,
      page: () => const ActivityDetailView(),
      binding: ActivityDetailBinding(),
    ),
    GetPage(
      name: _Paths.sportGearDetail,
      page: () => const SportGearDetailView(),
      binding: SportGearDetailBinding(),
    ),
  ];
}
