import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart' show Position;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import 'package:gati/app/core/exceptions/app_exception.dart';
import 'package:gati/app/data/models/activity_model.dart';
import 'package:gati/app/data/models/activity_point.dart';
import 'package:gati/app/data/models/activity_type.dart';
import 'package:gati/app/data/repositories/activity_repository.dart';
import 'package:gati/app/data/repositories/auth_repository.dart';
import 'package:gati/app/data/services/tracking_service.dart';
import 'package:gati/app/routes/app_pages.dart';

class TrackingController extends GetxController
    with GetSingleTickerProviderStateMixin {
  TrackingController(
    this._trackingService,
    this._activityRepository,
    this._authRepository,
  );

  final TrackingService _trackingService;
  final ActivityRepository _activityRepository;
  final AuthRepository _authRepository;

  final MapController mapController = MapController();
  final RxBool isAutoTracking = true.obs;
  final RxBool isSplitsExpanded = false.obs;

  AnimationController? _animationController;

  final Rx<ActivityType> selectedType = ActivityType.run.obs;
  final RxBool isSaving = false.obs;
  RxBool get isPaused => _trackingService.isPaused;
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
  Rx<Duration> get totalElapsed => _trackingService.totalElapsed;
  RxBool get isTracking => _trackingService.isTracking;
  RxDouble get elevationGain => _trackingService.elevationGain;
  RxList<double> get splits => _trackingService.splits;

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

  String get completedPace {
    if (_completedActivity == null) return '0:00';
    return _completedActivity!.averagePace;
  }

  String get completedElevationGain {
    if (_completedActivity == null) return '0';
    return _completedActivity!.elevationGain.toStringAsFixed(0);
  }

  String get completedMaxElevation {
    if (_completedActivity == null) return '0';
    return _completedActivity!.maxElevation.toStringAsFixed(0);
  }

  String get completedDate {
    if (_completedActivity == null) return '';
    return DateFormat('MMM d').format(_completedActivity!.startedAt);
  }

  @override
  void onInit() {
    super.onInit();
    _userEmail = _authRepository.currentUserEmail();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // Listen to points and update camera if auto-tracking is enabled
    ever(points, (List<ActivityPoint> p) {
      if (isAutoTracking.value && p.isNotEmpty && !showComplete.value) {
        final lastPoint = p.last;
        _animatedMapMove(
          LatLng(lastPoint.latitude, lastPoint.longitude),
          mapController.camera.zoom,
          offsetCenter: true,
        );
      }
    });

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

  /// Smoothly moves the map to a target position with an optional vertical offset.
  void _animatedMapMove(
    LatLng destLocation,
    double destZoom, {
    bool offsetCenter = false,
  }) {
    // Apply a vertical offset to push the center "up"
    final LatLng finalLocation = offsetCenter
        ? LatLng(destLocation.latitude - 0.002, destLocation.longitude)
        : destLocation;

    final AnimationController? controller = _animationController;
    if (controller == null) {
      try {
        mapController.move(finalLocation, destZoom);
      } catch (_) {
        // Map not ready
      }
      return;
    }

    try {
      final latTween = Tween<double>(
        begin: mapController.camera.center.latitude,
        end: finalLocation.latitude,
      );
      final lngTween = Tween<double>(
        begin: mapController.camera.center.longitude,
        end: finalLocation.longitude,
      );
      final zoomTween = Tween<double>(
        begin: mapController.camera.zoom,
        end: destZoom,
      );

      final Animation<double> animation = CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOutCubic,
      );

      controller.reset();

      animation.addListener(() {
        try {
          mapController.move(
            LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
            zoomTween.evaluate(animation),
          );
        } catch (_) {
          // Map disposed or not ready during animation
        }
      });

      controller.forward();
    } catch (e) {
      // mapController.camera might throw if not ready
      debugPrint('Map not ready: $e');
    }
  }

  void centerMap() {
    LatLng? target;
    if (points.isEmpty) {
      if (initialPosition.value != null) {
        target = LatLng(
          initialPosition.value!.latitude,
          initialPosition.value!.longitude,
        );
      }
    } else {
      target = LatLng(points.last.latitude, points.last.longitude);
    }

    if (target != null) {
      _animatedMapMove(target, 16, offsetCenter: true);
      isAutoTracking.value = true;
    }
  }

  void onMapEvent(MapEvent event) {
    // If the user manually drags the map, disable auto-tracking
    if (event is MapEventMoveStart &&
        event.source == MapEventSource.dragStart) {
      isAutoTracking.value = false;
    }
  }

  @override
  void onReady() {
    super.onReady();
    if (_userEmail == null) {
      Get.offAllNamed(Routes.login);
    } else {
      getInitialPosition();
    }
  }

  void getInitialPosition() async {
    try {
      Position? position = await _trackingService.getCurrentPosition();
      initialPosition.value = position;

      // First, set loading to false to render the map
      isLoading.value = false;

      // Wait for the next frame to ensure FlutterMap is rendered
      if (position != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _animatedMapMove(
            LatLng(position.latitude, position.longitude),
            16,
            offsetCenter: true,
          );
        });
      }
    } catch (error) {
      Get.snackbar('Error', error.toString());
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _animationController?.dispose();
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
      return '0:00';
    }
    final distanceKm = meters / 1000;
    final secondsPerKm = seconds / distanceKm;

    final minutes = (secondsPerKm / 60).floor();
    final remainingSeconds = (secondsPerKm % 60).round();

    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String get formattedSplitPace {
    final currentDist = distance.value;
    final lastSplitDist = _trackingService.lastSplitDistance;
    final distDiff = (currentDist - lastSplitDist) / 1000;

    if (distDiff <= 0.05) return '-:--'; // Need at least 50m for a stable pace

    final currentTime = duration.value;
    final lastSplitTime = _trackingService.lastSplitDuration;
    final timeDiff = (currentTime - lastSplitTime).inSeconds;

    final secondsPerKm = timeDiff / distDiff;
    final minutes = (secondsPerKm / 60).floor();
    final seconds = (secondsPerKm % 60).round();

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedElevationGain => elevationGain.value.toStringAsFixed(0);

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

  String get formattedElapsed {
    final d = totalElapsed.value;
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Returns the pace for the current (incomplete) kilometer split in seconds.
  double get currentSplitPaceSeconds {
    final currentDist = distance.value;
    final lastSplitDist = _trackingService.lastSplitDistance;
    final distDiff = (currentDist - lastSplitDist) / 1000;

    if (distDiff <= 0.005) return 0; // Need at least 5m for any calculation

    final currentTime = duration.value;
    final lastSplitTime = _trackingService.lastSplitDuration;
    final timeDiff = (currentTime - lastSplitTime).inSeconds;

    return timeDiff / distDiff;
  }

  /// Returns a list of split times (seconds per km) for display.
  /// Includes completed splits plus the current segment.
  /// Guaranteed to have at least 3 items (padded with 0) and at most 5 items (most recent).
  List<double> get displaySplits {
    final List<double> allSplits = List.from(splits);

    // Add current segment if tracking
    if (isTracking.value) {
      allSplits.add(currentSplitPaceSeconds);
    }

    // Take last 5
    final recentSplits = allSplits.length > 5
        ? allSplits.sublist(allSplits.length - 5)
        : allSplits;

    // Ensure at least 3 items
    while (recentSplits.length < 3) {
      recentSplits.add(0.0);
    }

    return recentSplits;
  }
}
