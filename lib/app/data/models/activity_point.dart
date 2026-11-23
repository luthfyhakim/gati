class ActivityPoint {
  ActivityPoint({
    required this.latitude,
    required this.longitude,
    this.altitude = 0.0,
    required this.recordedAt,
  });

  final double latitude;
  final double longitude;
  final double altitude;
  final DateTime recordedAt;

  Map<String, dynamic> toMap() => {
        'lat': latitude,
        'lng': longitude,
        'altitude': altitude,
        'recordedAt': recordedAt.toIso8601String(),
      };

  static ActivityPoint fromMap(Map<String, dynamic> map) {
    return ActivityPoint(
      latitude: (map['lat'] as num).toDouble(),
      longitude: (map['lng'] as num).toDouble(),
      altitude: (map['altitude'] as num? ?? 0.0).toDouble(),
      recordedAt: DateTime.parse(map['recordedAt'] as String),
    );
  }
}
