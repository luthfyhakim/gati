class ActivityPoint {
  ActivityPoint({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAt;

  Map<String, dynamic> toMap() => {
        'lat': latitude,
        'lng': longitude,
        'recordedAt': recordedAt.toIso8601String(),
      };

  static ActivityPoint fromMap(Map<String, dynamic> map) {
    return ActivityPoint(
      latitude: (map['lat'] as num).toDouble(),
      longitude: (map['lng'] as num).toDouble(),
      recordedAt: DateTime.parse(map['recordedAt'] as String),
    );
  }
}
