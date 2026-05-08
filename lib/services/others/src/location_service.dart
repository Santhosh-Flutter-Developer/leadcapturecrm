import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static Future<Position?> getCurrentPosition() async {
    final granted = await requestPermission();
    if (!granted) return null;
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Returns distance in metres between two lat/lng points.
  static double distanceBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  static bool isWithinRadius({
    required double currentLat,
    required double currentLng,
    required double centerLat,
    required double centerLng,
    required double radiusMeters,
  }) {
    final distance =
        distanceBetween(currentLat, currentLng, centerLat, centerLng);
    return distance <= radiusMeters;
  }
}
