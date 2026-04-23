import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:gati/app/data/models/activity_model.dart';
import 'package:gati/app/data/models/activity_type.dart';
import 'package:gati/app/data/models/sport_gear_model.dart';
import 'package:gati/app/data/repositories/activity_repository.dart';
import 'package:gati/app/data/repositories/auth_repository.dart';
import 'package:gati/app/data/services/sport_gear_service.dart';
import 'package:gati/app/routes/app_pages.dart';

class HomeController extends GetxController {
  HomeController(
    this._authRepository,
    this._activityRepository,
    this._sportGearService,
  );

  final AuthRepository _authRepository;
  final ActivityRepository _activityRepository;
  final SportGearService _sportGearService;

  final RxInt currentIndex = 0.obs;
  final RxList<Activity> activities = <Activity>[].obs;
  final RxBool isLoading = false.obs;

  // Sport Gear State
  final RxList<SportGear> sportGearList = <SportGear>[].obs;
  final RxList<SportGear> filteredSportGearList = <SportGear>[].obs;
  final RxString selectedCategory = 'All'.obs;
  final RxList<String> gearCategories = <String>['All'].obs;

  final RxString selectedShoeSubCategory = 'All'.obs;
  final RxList<String> shoeSubCategories = <String>['All'].obs;
  final RxString searchQuery = ''.obs;

  String? _userEmail;
  String? _userFullName;

  // Statistics
  int get totalActivities => activities.length;

  double get totalDistance {
    if (activities.isEmpty) return 0;
    return activities.fold(0.0, (sum, a) => sum + a.distanceMeters) / 1000;
  }

  Duration get totalTime {
    if (activities.isEmpty) return Duration.zero;
    return activities.fold(Duration.zero, (sum, a) => sum + a.duration);
  }

  int get thisWeekActivities {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return activities.where((a) => a.startedAt.isAfter(weekStart)).length;
  }

  String get userName {
    final email = _userEmail ?? '';
    if (email.isEmpty) return 'User';
    return email.split('@').first;
  }

  String get userEmail => _userEmail ?? '';

  String get displayName {
    return _userFullName ?? 'User';
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    if (hour < 19) return 'Good evening!';
    return 'Good night!';
  }

  String get formattedTotalTime {
    final d = totalTime;
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  @override
  void onInit() {
    super.onInit();
    _userEmail = _authRepository.currentUserEmail();
    _userFullName = _authRepository.currentUserFullName();
  }

  @override
  void onReady() {
    super.onReady();
    if (_userEmail == null) {
      Get.offAllNamed(Routes.login);
    } else {
      loadActivities();
      loadSportGear();
      loadGearCategories();
    }
  }

  Future<void> loadGearCategories() async {
    try {
      final categories = await _sportGearService.fetchGearCategories();
      if (categories.isNotEmpty) {
        gearCategories.assignAll(['All', ...categories.map((e) => e.name)]);
      }
    } catch (e) {
      debugPrint('Error loading gear categories: $e');
    }
  }

  Future<void> loadGearSubCategories(String categoryName) async {
    try {
      final subCategories = await _sportGearService.fetchGearSubcategories(
        categoryName,
      );
      shoeSubCategories.assignAll(['All', ...subCategories.map((e) => e.name)]);
    } catch (e) {
      debugPrint('Error loading gear subcategories: $e');
    }
  }

  Future<void> loadActivities() async {
    if (_userEmail == null) return;
    isLoading.value = true;
    try {
      final list = await _activityRepository.list(_userEmail!);
      activities.assignAll(list);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load activities');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadSportGear() async {
    isLoading.value = true;
    try {
      final list = await _sportGearService.fetchAllGear();
      sportGearList.assignAll(list);
      _filterGear();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load sport gear');
    } finally {
      isLoading.value = false;
    }
  }

  void setGearCategory(String category) {
    selectedCategory.value = category;
    selectedShoeSubCategory.value = 'All';
    if (category == 'Shoes') {
      loadGearSubCategories(category);
    } else {
      shoeSubCategories.assignAll(['All']);
    }
    _filterGear();
  }

  void setShoeSubCategory(String subCategory) {
    selectedShoeSubCategory.value = subCategory;
    _filterGear();
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
    _filterGear();
  }

  void _filterGear() {
    var filtered = sportGearList.toList();

    // Primary Category
    if (selectedCategory.value != 'All') {
      filtered = filtered
          .where((gear) => gear.category == selectedCategory.value)
          .toList();
    }

    // Secondary Category (Shoes)
    if (selectedCategory.value == 'Shoes' &&
        selectedShoeSubCategory.value != 'All') {
      filtered = filtered.where((gear) {
        final suitableFor = gear.suitableFor ?? [];
        return suitableFor
            .map((s) => s.toLowerCase())
            .contains(selectedShoeSubCategory.value.toLowerCase());
      }).toList();
    }

    // Search Query
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((gear) {
        final matchName = gear.name.toLowerCase().contains(query);
        final matchBrand = gear.brand.toLowerCase().contains(query);
        var matchSuitableFor = false;
        if (gear.category == 'Shoes' && gear.suitableFor != null) {
          matchSuitableFor = gear.suitableFor!.any(
            (s) => s.toLowerCase().contains(query),
          );
        }
        return matchName || matchBrand || matchSuitableFor;
      }).toList();
    }

    filteredSportGearList.assignAll(filtered);
  }

  void onTabChanged(int index) {
    currentIndex.value = index;
  }

  Future<void> openActivityDetail(Activity activity) async {
    await Get.toNamed(Routes.activityDetail, arguments: activity.id);
    loadActivities();
  }

  void editProfile() {
    Get.snackbar(
      'Coming Soon',
      'Edit profile feature will be available soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void changeEmail() {
    Get.snackbar(
      'Coming Soon',
      'Change email feature will be available soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> startActivity() async {
    await Get.toNamed(
      Routes.tracking,
      arguments: {'activityType': ActivityType.run},
    );
    loadActivities();
  }

  void logout() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Log Out',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _authRepository.logout();
              Get.offAllNamed(Routes.login);
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
