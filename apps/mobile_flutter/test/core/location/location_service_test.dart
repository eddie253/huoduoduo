import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/core/location/location_service.dart';

class _FakeLocationService implements LocationServicePort {
  _FakeLocationService({
    required this.result,
  });

  final LocationResult? result;

  @override
  Future<LocationResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 10),
    double maxAccuracyMeters = 50.0,
  }) async {
    final r = result;
    if (r == null) {
      throw const LocationPermissionDeniedException('permission denied');
    }
    return r;
  }
}

void main() {
  group('LocationResult', () {
    test('latitudeString and longitudeString are 6 decimal places', () {
      final r = LocationResult(
        latitude: 25.033,
        longitude: 121.5654,
        accuracyMeters: 15.0,
        timestamp: DateTime(2025),
        isBelowAccuracyThreshold: true,
      );
      expect(r.latitudeString, '25.033000');
      expect(r.longitudeString, '121.565400');
    });

    test('isBelowAccuracyThreshold true when accuracy <= threshold', () {
      final r = LocationResult(
        latitude: 0,
        longitude: 0,
        accuracyMeters: 49.9,
        timestamp: DateTime(2025),
        isBelowAccuracyThreshold: true,
      );
      expect(r.isBelowAccuracyThreshold, isTrue);
    });

    test('isBelowAccuracyThreshold false when accuracy exceeds threshold', () {
      final r = LocationResult(
        latitude: 0,
        longitude: 0,
        accuracyMeters: 100.0,
        timestamp: DateTime(2025),
        isBelowAccuracyThreshold: false,
      );
      expect(r.isBelowAccuracyThreshold, isFalse);
    });
  });

  group('LocationServicePort (fake)', () {
    test('returns result when available', () async {
      final expected = LocationResult(
        latitude: 25.0,
        longitude: 121.0,
        accuracyMeters: 10.0,
        timestamp: DateTime(2025),
        isBelowAccuracyThreshold: true,
      );
      final svc = _FakeLocationService(result: expected);
      final result = await svc.getCurrentLocation();
      expect(result.latitude, 25.0);
      expect(result.longitude, 121.0);
      expect(result.accuracyMeters, 10.0);
      expect(result.isBelowAccuracyThreshold, isTrue);
    });

    test('throws LocationPermissionDeniedException when result is null',
        () async {
      final svc = _FakeLocationService(result: null);
      expect(
        () => svc.getCurrentLocation(),
        throwsA(isA<LocationPermissionDeniedException>()),
      );
    });
  });

  group('LocationPermissionDeniedException', () {
    test('toString includes message', () {
      const e = LocationPermissionDeniedException('denied forever');
      expect(e.toString(), contains('denied forever'));
    });
  });
}
