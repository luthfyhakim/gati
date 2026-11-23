import 'package:gati/app/data/models/activity_point.dart';
import 'package:gati/app/data/models/activity_type.dart';

class Activity {
  Activity({
    required this.id,
    required this.userEmail,
    required this.type,
    required this.startedAt,
    required this.endedAt,
    required this.distanceMeters,
    required this.duration,
    required this.elapsedDuration,
    required this.route,
    required this.title,
    this.description = '',
    this.elevationGain = 0.0,
    this.maxElevation = 0.0,
    this.splits = const [],
  });

  final String id;
  final String userEmail;
  final ActivityType type;
  final DateTime startedAt;
  final DateTime endedAt;
  final double distanceMeters;
  final Duration duration; // Moving Time
  final Duration elapsedDuration; // Total Time
  final List<ActivityPoint> route;
  final String title;
  final String description;
  final double elevationGain;
  final double maxElevation;
  final List<double> splits; // Pace in seconds per km

  double get distanceKm => distanceMeters / 1000;

  double get averageSpeedKmh {
    if (duration.inSeconds == 0) {
      return 0;
    }
    final hours = duration.inSeconds / 3600;
    return distanceKm / hours;
  }

  String get averagePace {
    if (distanceMeters <= 0 || duration.inSeconds == 0) {
      return '0:00';
    }
    final totalSeconds = duration.inSeconds;
    final secondsPerKm = totalSeconds / distanceKm;
    
    final minutes = (secondsPerKm / 60).floor();
    final seconds = (secondsPerKm % 60).round();
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Creates a copy of this activity with optional overrides.
  Activity copyWith({String? title, String? description}) {
    return Activity(
      id: id,
      userEmail: userEmail,
      type: type,
      startedAt: startedAt,
      endedAt: endedAt,
      distanceMeters: distanceMeters,
      duration: duration,
      elapsedDuration: elapsedDuration,
      route: route,
      title: title ?? this.title,
      description: description ?? this.description,
      elevationGain: elevationGain,
      maxElevation: maxElevation,
      splits: splits,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userEmail': userEmail,
    'type': type.apiValue,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'distanceMeters': distanceMeters,
    'durationSeconds': duration.inSeconds,
    'elapsedSeconds': elapsedDuration.inSeconds,
    'title': title,
    'description': description,
    'elevationGain': elevationGain,
    'maxElevation': maxElevation,
    'splits': splits,
    'route': route.map((point) => point.toMap()).toList(),
  };

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] as String,
      userEmail: map['userEmail'] as String,
      type: ActivityTypeX.fromApiValue(map['type'] as String),
      startedAt: DateTime.parse(map['startedAt'] as String),
      endedAt: DateTime.parse(map['endedAt'] as String),
      distanceMeters: (map['distanceMeters'] as num).toDouble(),
      duration: Duration(seconds: map['durationSeconds'] as int),
      elapsedDuration: Duration(seconds: (map['elapsedSeconds'] as int? ?? map['durationSeconds'] as int)),
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      elevationGain: (map['elevationGain'] as num? ?? 0.0).toDouble(),
      maxElevation: (map['maxElevation'] as num? ?? 0.0).toDouble(),
      splits: (map['splits'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      route: ((map['route'] as List<dynamic>).cast<Map<String, dynamic>>())
          .map(ActivityPoint.fromMap)
          .toList(),
    );
  }
}
