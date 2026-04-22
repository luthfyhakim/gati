import 'dart:async';

import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:gati/app/core/exceptions/app_exception.dart';
import 'package:gati/app/core/utils/geo_utils.dart';
import 'package:gati/app/data/models/activity_model.dart';
import 'package:gati/app/data/models/activity_point.dart';
import 'package:gati/app/data/models/activity_type.dart';

class TrackingService extends GetxService {
  final RxList<ActivityPoint> routePoints = <ActivityPoint>[].obs;
  final RxDouble totalDistance = 0.0.obs;
  final Rx<Duration> elapsed = Duration.zero.obs;
  final RxBool isTracking = false.obs;
  final RxBool isPaused = false.obs;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;
  DateTime? _startedAt;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pausedAt;

  Future<Position> getCurrentPosition() async {
    await _ensurePermissions();
    final position = await Geolocator.getCurrentPosition(
      locationSettings: AppleSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      ),
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
    isTracking.value = true;
    isPaused.value = false;

    _timer?.cancel();
    // Update duration on a fixed interval so UI reflects progress instantly.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startedAt != null && !isPaused.value) {
        elapsed.value =
            DateTime.now().difference(_startedAt!) - _pausedDuration;
      }
    });

    final initialPosition = await Geolocator.getCurrentPosition();
    _addPoint(initialPosition);

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: AppleSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      ),
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
    required ActivityType type,
    required String userEmail,
  }) async {
    if (!isTracking.value || _startedAt == null) {
      throw AppException('Tracking session is not active.');
    }

    await _disposeStreams();
    final finishedAt = DateTime.now();
    final duration = finishedAt.difference(_startedAt!);

    final activity = Activity(
      id: finishedAt.millisecondsSinceEpoch.toString(),
      userEmail: userEmail,
      type: type,
      startedAt: _startedAt!,
      endedAt: finishedAt,
      distanceMeters: totalDistance.value,
      duration: duration,
      route: routePoints.toList(),
      title: '${type.label} ${DateFormat('MMM d, HH:mm').format(_startedAt!)}',
    );

    _resetState();
    return activity;
  }

  Future<void> cancel() async {
    await _disposeStreams();
    _resetState();
  }

  Future<void> _ensurePermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw PermissionException('Location services are disabled.');
    }

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
  }

  void _addPoint(Position position) {
    final point = ActivityPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      recordedAt: DateTime.now(),
    );

    if (routePoints.isNotEmpty) {
      final previous = routePoints.last;
      // Incrementally accumulate distance between last and current coordinate.
      totalDistance.value += GeoUtils.haversineDistanceMeters(
        startLat: previous.latitude,
        startLng: previous.longitude,
        endLat: point.latitude,
        endLng: point.longitude,
      );
    }

    routePoints.add(point);
  }

  Future<void> _disposeStreams() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _timer?.cancel();
    _timer = null;
  }

  void _resetState() {
    routePoints.clear();
    totalDistance.value = 0;
    elapsed.value = Duration.zero;
    isTracking.value = false;
    isPaused.value = false;
    _startedAt = null;
    _pausedDuration = Duration.zero;
    _pausedAt = null;
  }
}
