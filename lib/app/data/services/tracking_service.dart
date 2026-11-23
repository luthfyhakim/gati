import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import 'package:gati/app/core/exceptions/app_exception.dart';
import 'package:gati/app/core/utils/geo_utils.dart';
import 'package:gati/app/data/models/activity_model.dart';
import 'package:gati/app/data/models/activity_point.dart';
import 'package:gati/app/data/models/activity_type.dart' as act_type;

class TrackingService extends GetxService {
  final RxList<ActivityPoint> routePoints = <ActivityPoint>[].obs;
  final RxDouble totalDistance = 0.0.obs;
  final Rx<Duration> elapsed = Duration.zero.obs; // Moving Time
  final Rx<Duration> totalElapsed = Duration.zero.obs; // Elapsed Time
  final RxBool isTracking = false.obs;
  final RxBool isPaused = false.obs;
  final RxDouble elevationGain = 0.0.obs;
  final RxDouble maxElevation = 0.0.obs;
  final RxList<double> splits = <double>[].obs; // Seconds per km

  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;
  DateTime? _startedAt;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pausedAt;
  double _lastSplitDistance = 0.0;
  Duration _lastSplitDuration = Duration.zero;

  LocationSettings _getLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0, // Lower filter for smoother real-time updates
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Gati is tracking your activity.",
          notificationTitle: "Tracking Active",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        activityType: ActivityType.fitness,
      );
    } else {
      return const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      );
    }
  }

  Future<Position?> getCurrentPosition() async {
    await _ensurePermissions();
    final position = await Geolocator.getCurrentPosition(
      locationSettings: _getLocationSettings(),
    );
    return position;
  }

  Future<void> start() async {
    await _ensurePermissions();
    _startedAt = DateTime.now();
    _pausedDuration = Duration.zero;
    _pausedAt = null;
    routePoints.clear();
    totalDistance.value = 0;
    elapsed.value = Duration.zero;
    totalElapsed.value = Duration.zero;
    isTracking.value = true;
    isPaused.value = false;
    elevationGain.value = 0;
    maxElevation.value = 0;
    splits.clear();
    _lastSplitDistance = 0.0;
    _lastSplitDuration = Duration.zero;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startedAt != null) {
        totalElapsed.value = DateTime.now().difference(_startedAt!);
        if (!isPaused.value) {
          elapsed.value = totalElapsed.value - _pausedDuration;
        }
      }
    });

    final initialPosition = await Geolocator.getCurrentPosition(
      locationSettings: _getLocationSettings(),
    );
    _addPoint(initialPosition);

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: _getLocationSettings(),
    ).listen(_addPoint);
  }

  void pause() {
    if (!isTracking.value || isPaused.value) return;
    isPaused.value = true;
    _pausedAt = DateTime.now();
    _positionSubscription?.pause();
  }

  void resume() {
    if (!isTracking.value || !isPaused.value) return;
    if (_pausedAt != null) {
      _pausedDuration += DateTime.now().difference(_pausedAt!);
    }
    _pausedAt = null;
    isPaused.value = false;
    _positionSubscription?.resume();
  }

  Future<Activity> stop({
    required act_type.ActivityType type,
    required String userEmail,
  }) async {
    if (!isTracking.value || _startedAt == null) {
      throw AppException('Tracking session is not active.');
    }

    await _disposeStreams();
    final finishedAt = DateTime.now();

    // Final split if remaining distance > 0
    if (totalDistance.value > _lastSplitDistance) {
      final distDiff = (totalDistance.value - _lastSplitDistance) / 1000;
      final timeDiff = (elapsed.value - _lastSplitDuration).inSeconds;
      if (distDiff > 0.1) {
        // Only add if at least 100m in the last segment
        splits.add(timeDiff / distDiff);
      }
    }

    final activity = Activity(
      id: finishedAt.millisecondsSinceEpoch.toString(),
      userEmail: userEmail,
      type: type,
      startedAt: _startedAt!,
      endedAt: finishedAt,
      distanceMeters: totalDistance.value,
      duration: elapsed.value,
      elapsedDuration: totalElapsed.value,
      route: routePoints.toList(),
      title: '${type.label} ${DateFormat('MMM d, HH:mm').format(_startedAt!)}',
      elevationGain: elevationGain.value,
      maxElevation: maxElevation.value,
      splits: splits.toList(),
    );

    _resetState();
    return activity;
  }

  Future<void> cancel() async {
    await _disposeStreams();
    _resetState();
  }

  Future<void> _ensurePermissions() async {
    // 1. Location Service
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw PermissionException('Location services are disabled.');
    }

    // 2. Notification Permission (Required for Foreground Service on Android 13+)
    if (defaultTargetPlatform == TargetPlatform.android) {
      await ph.Permission.notification.request();
    }

    // 3. Location Permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw PermissionException('Location permission denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw PermissionException(
        'Location permissions are permanently denied. Please enable them in settings.',
      );
    }

    // 4. Background Location Permission (Android 10+)
    // For background tracking to work reliably, we ideally need 'always' permission
    if (defaultTargetPlatform == TargetPlatform.android &&
        permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }
  }

  void _addPoint(Position position) {
    final point = ActivityPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      recordedAt: DateTime.now(),
    );

    if (routePoints.isNotEmpty) {
      final previous = routePoints.last;
      totalDistance.value += GeoUtils.haversineDistanceMeters(
        startLat: previous.latitude,
        startLng: previous.longitude,
        endLat: point.latitude,
        endLng: point.longitude,
      );

      // Elevation tracking
      if (point.altitude > previous.altitude) {
        elevationGain.value += (point.altitude - previous.altitude);
      }
      if (point.altitude > maxElevation.value) {
        maxElevation.value = point.altitude;
      }

      // Splits tracking (every 1 km)
      if (totalDistance.value >= _lastSplitDistance + 1000) {
        final timeDiff = (elapsed.value - _lastSplitDuration).inSeconds;
        splits.add(timeDiff.toDouble());
        _lastSplitDistance += 1000;
        _lastSplitDuration = elapsed.value;
      }
    } else {
      maxElevation.value = point.altitude;
    }

    routePoints.add(point);
  }

  Future<void> _disposeStreams() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _timer?.cancel();
    _timer = null;
  }

  double get lastSplitDistance => _lastSplitDistance;
  Duration get lastSplitDuration => _lastSplitDuration;

  void _resetState() {
    routePoints.clear();
    totalDistance.value = 0;
    elapsed.value = Duration.zero;
    totalElapsed.value = Duration.zero;
    isTracking.value = false;
    isPaused.value = false;
    elevationGain.value = 0;
    maxElevation.value = 0;
    splits.clear();
    _startedAt = null;
    _pausedDuration = Duration.zero;
    _pausedAt = null;
    _lastSplitDistance = 0.0;
    _lastSplitDuration = Duration.zero;
  }
}
