import 'dart:math';

class GeoUtils {
  const GeoUtils._();

  static double haversineDistanceMeters({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(endLat - startLat);
    final dLon = _toRadians(endLng - startLng);

    final a = pow(sin(dLat / 2), 2) +
        cos(_toRadians(startLat)) *
            cos(_toRadians(endLat)) *
            pow(sin(dLon / 2), 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
