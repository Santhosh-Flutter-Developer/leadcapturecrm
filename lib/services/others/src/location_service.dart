import 'package:geolocator/geolocator.dart';

/// Detailed outcome of a geofence / location check.
enum LocationCheckResult {
  /// User is within the allowed radius – all clear.
  success,

  /// Device GPS / location service is turned off.
  serviceDisabled,

  /// Permission was denied by the user (can still be requested again).
  permissionDenied,

  /// Permission was permanently denied – must be opened from App Settings.
  permissionDeniedForever,

  /// User's position is outside the configured radius.
  outsideRadius,

  /// An unexpected error occurred while fetching the position.
  error,
}

class LocationService {
  /// Returns `true` if location permission is granted (whileInUse or always).
  static Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return false;
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Returns the current [Position], or `null` if permission is not granted.
  static Future<Position?> getCurrentPosition() async {
    final granted = await requestPermission();
    if (!granted) return null;
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Opens the device Location / GPS settings screen.
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Opens the application's permission settings screen so the user can
  /// manually grant location permission that was permanently denied.
  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Performs a full geofence validation and returns a [LocationCheckResult]
  /// describing the outcome in detail.
  ///
  /// Call order:
  ///   1. Check location service enabled
  ///   2. Check / request permission
  ///   3. Fetch current position
  ///   4. Compare distance against [radiusMeters]
  static Future<LocationCheckResult> checkGeofence({
    required double centerLat,
    required double centerLng,
    required double radiusMeters,
  }) async {
    // 1. GPS service
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationCheckResult.serviceDisabled;

    // 2. Permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationCheckResult.permissionDeniedForever;
    }
    if (permission == LocationPermission.denied) {
      return LocationCheckResult.permissionDenied;
    }

    // 3. Fetch position
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // 4. Radius check
      final inside = isWithinRadius(
        currentLat: position.latitude,
        currentLng: position.longitude,
        centerLat: centerLat,
        centerLng: centerLng,
        radiusMeters: radiusMeters,
      );

      return inside
          ? LocationCheckResult.success
          : LocationCheckResult.outsideRadius;
    } catch (_) {
      return LocationCheckResult.error;
    }
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
