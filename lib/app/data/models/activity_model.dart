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
    required this.route,
    required this.title,
    this.description = '',
  });

  final String id;
  final String userEmail;
  final ActivityType type;
  final DateTime startedAt;
  final DateTime endedAt;
  final double distanceMeters;
  final Duration duration;
  final List<ActivityPoint> route;
  final String title;
  final String description;

  double get distanceKm => distanceMeters / 1000;

  double get averageSpeedKmh {
    if (duration.inSeconds == 0) {
      return 0;
    }
    final hours = duration.inSeconds / 3600;
    return distanceKm / hours;
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
      route: route,
      title: title ?? this.title,
      description: description ?? this.description,
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
    'title': title,
    'description': description,
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
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      route: ((map['route'] as List<dynamic>).cast<Map<String, dynamic>>())
          .map(ActivityPoint.fromMap)
          .toList(),
    );
  }
}
