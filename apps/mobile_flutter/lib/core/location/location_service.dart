import 'package:geolocator/geolocator.dart';

class LocationResult {
  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.timestamp,
    required this.isBelowAccuracyThreshold,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime timestamp;
  final bool isBelowAccuracyThreshold;

  String get latitudeString => latitude.toStringAsFixed(6);
  String get longitudeString => longitude.toStringAsFixed(6);
}

class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException(this.message);
  final String message;
  @override
  String toString() => 'LocationPermissionDeniedException: $message';
}

abstract class LocationServicePort {
  Future<LocationResult> getCurrentLocation({
    Duration timeout,
    double maxAccuracyMeters,
  });
}

class LocationService implements LocationServicePort {
  const LocationService();

  static const double _defaultMaxAccuracyMeters = 50.0;
  static const Duration _defaultTimeout = Duration(seconds: 10);

  @override
  Future<LocationResult> getCurrentLocation({
    Duration timeout = _defaultTimeout,
    double maxAccuracyMeters = _defaultMaxAccuracyMeters,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationPermissionDeniedException(
          'Location service disabled');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationPermissionDeniedException('Permission denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedException(
          'Permission permanently denied');
    }

    Position? bestPosition;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(timeout);
      bestPosition = position;
    } catch (_) {
      bestPosition = await Geolocator.getLastKnownPosition();
    }

    if (bestPosition != null) {
      return _toResult(
        bestPosition,
        isBelowThreshold: bestPosition.accuracy <= maxAccuracyMeters,
      );
    }

    throw const LocationPermissionDeniedException(
        'Could not obtain location within timeout');
  }

  LocationResult _toResult(Position p, {required bool isBelowThreshold}) {
    return LocationResult(
      latitude: p.latitude,
      longitude: p.longitude,
      accuracyMeters: p.accuracy,
      timestamp: p.timestamp,
      isBelowAccuracyThreshold: isBelowThreshold,
    );
  }
}
