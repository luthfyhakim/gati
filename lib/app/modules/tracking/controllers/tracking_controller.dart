import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' show Position;
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:gati/app/core/exceptions/app_exception.dart';
import 'package:gati/app/data/models/activity_model.dart';
import 'package:gati/app/data/models/activity_point.dart';
import 'package:gati/app/data/models/activity_type.dart';
import 'package:gati/app/data/repositories/activity_repository.dart';
import 'package:gati/app/data/repositories/auth_repository.dart';
import 'package:gati/app/data/services/tracking_service.dart';
import 'package:gati/app/routes/app_pages.dart';

class TrackingController extends GetxController {
  TrackingController(
    this._trackingService,
    this._activityRepository,
    this._authRepository,
  );

  final TrackingService _trackingService;
  final ActivityRepository _activityRepository;
  final AuthRepository _authRepository;

  final Rx<ActivityType> selectedType = ActivityType.run.obs;
  final RxBool isSaving = false.obs;
  final RxBool isPaused = false.obs;
  final RxBool showComplete = false.obs;

  /// Text controllers for user-editable fields on the complete screen.
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final Rx<Position?> initialPosition = Rx<Position?>(null);
  final RxBool isLoading = true.obs;

  String? _userEmail;

  // Store completed activity data
  Activity? _completedActivity;
  List<ActivityPoint> _completedPointsData = [];

  RxList<ActivityPoint> get points => _trackingService.routePoints;
  RxDouble get distance => _trackingService.totalDistance;
  Rx<Duration> get duration => _trackingService.elapsed;
  RxBool get isTracking => _trackingService.isTracking;

  // Completed activity getters
  List<ActivityPoint> get completedPoints => _completedPointsData;

  String get completedDistance {
    if (_completedActivity == null) return '0.00';
    return (_completedActivity!.distanceMeters / 1000).toStringAsFixed(2);
  }

  String get completedDuration {
    if (_completedActivity == null) return '0m 0s';
    final d = _completedActivity!.duration;
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }

  String get completedSpeed {
    if (_completedActivity == null) return '0.0';
    return _completedActivity!.averageSpeedKmh.toStringAsFixed(1);
  }

  String get completedDate {
    if (_completedActivity == null) return '';
    return DateFormat('MMM d').format(_completedActivity!.startedAt);
  }

  @override
  void onInit() {
    getInitialPosition();
    super.onInit();
    _userEmail = _authRepository.currentUserEmail();
    if (_userEmail == null) {
      Get.offAllNamed(Routes.login);
    }

    // Check if activity type was passed as argument
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      final type = args['activityType'];
      if (type is ActivityType) {
        selectedType.value = type;
      }
    } else if (args is ActivityType) {
      selectedType.value = args;
    }
  }

  void getInitialPosition() async {
    try {
      Position? position = await _trackingService.getCurrentPosition();
      initialPosition.value = position;
    } catch (error) {
      print(error);
      Get.snackbar('Error', error.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  void changeType(ActivityType type) {
    selectedType.value = type;
  }

  Future<void> startTracking() async {
    try {
      await _trackingService.start();
      isPaused.value = false;
    } on PermissionException catch (error) {
      Get.snackbar('Permission error', error.message);
    } catch (error) {
      Get.snackbar('Error', error.toString());
    }
  }

  void togglePause() {
    if (isPaused.value) {
      _trackingService.resume();
    } else {
      _trackingService.pause();
    }
    isPaused.value = !isPaused.value;
  }

  Future<void> stopTracking() async {
    if (_userEmail == null) {
      Get.offAllNamed(Routes.login);
      return;
    }

    try {
      // Stop tracking and get the activity
      final activity = await _trackingService.stop(
        type: selectedType.value,
        userEmail: _userEmail!,
      );

      // Store completed data
      _completedActivity = activity;
      _completedPointsData = List.from(activity.route);

      // Pre-fill the name field with the auto-generated title
      nameController.text = activity.title;
      descriptionController.clear();

      // Show complete screen
      showComplete.value = true;
    } catch (error) {
      Get.snackbar('Unable to stop', error.toString());
    }
  }

  Future<void> saveActivity() async {
    if (_completedActivity == null) return;

    // Validate that the user has entered a name
    final name = nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
        'Name required',
        'Please enter a name for your activity',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSaving.value = true;
    try {
      // Apply user-inputted name and description
      final activityToSave = _completedActivity!.copyWith(
        title: name,
        description: descriptionController.text.trim(),
      );
      await _activityRepository.save(activityToSave);
      Get.snackbar('Saved', 'Activity stored successfully.');
      _resetAndGoBack();
    } catch (error) {
      Get.snackbar('Unable to save', error.toString());
    } finally {
      isSaving.value = false;
    }
  }

  void discardActivity() {
    _resetAndGoBack();
  }

  void _resetAndGoBack() {
    _completedActivity = null;
    _completedPointsData = [];
    nameController.clear();
    descriptionController.clear();
    showComplete.value = false;
    Get.back();
  }

  Future<void> cancelTracking() async {
    await _trackingService.cancel();
    isPaused.value = false;
  }

  void openHistory() {
    Get.toNamed(Routes.history);
  }

  Future<void> logout() async {
    await _trackingService.cancel();
    await _authRepository.logout();
    Get.offAllNamed(Routes.login);
  }

  String get formattedDistance => (distance.value / 1000).toStringAsFixed(2);

  String get formattedPace {
    final meters = distance.value;
    final seconds = duration.value.inSeconds;
    if (meters <= 0 || seconds <= 0) {
      return '0.0';
    }
    final speedKmh = (meters / 1000) / (seconds / 3600);
    return speedKmh.toStringAsFixed(1);
  }

  String get formattedDuration {
    final d = duration.value;
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String get formattedDurationShort {
    final d = duration.value;
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
