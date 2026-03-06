import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_flutter/features/maps/application/maps_view_model.dart';

void main() {
  const vm = MapsViewModel();

  group('buildMapUri', () {
    test('returns valid URI for correct coordinates', () {
      final (:uri, :error) = vm.buildMapUri('25.0330', '121.5654');
      expect(error, isNull);
      expect(uri, isNotNull);
      expect(uri!.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters['destination'], '25.033,121.5654');
      expect(uri.queryParameters['travelmode'], 'driving');
    });

    test('returns error for non-numeric latitude', () {
      final (:uri, :error) = vm.buildMapUri('abc', '121.5654');
      expect(uri, isNull);
      expect(error, 'Latitude/longitude format is invalid.');
    });

    test('returns error for latitude out of range', () {
      final (:uri, :error) = vm.buildMapUri('91.0', '0.0');
      expect(uri, isNull);
      expect(error, isNotNull);
    });

    test('returns error for longitude out of range', () {
      final (:uri, :error) = vm.buildMapUri('0.0', '181.0');
      expect(uri, isNull);
      expect(error, isNotNull);
    });

    test('returns error for empty strings', () {
      final (:uri, :error) = vm.buildMapUri('', '');
      expect(uri, isNull);
      expect(error, isNotNull);
    });

    test('accepts boundary values -90/90 and -180/180', () {
      expect(vm.buildMapUri('-90', '-180').uri, isNotNull);
      expect(vm.buildMapUri('90', '180').uri, isNotNull);
    });
  });

  group('sanitizePhone', () {
    test('strips non-numeric chars and returns sanitized number', () {
      final (:phone, :error) = vm.sanitizePhone('(02) 1234-5678');
      expect(error, isNull);
      expect(phone, '0212345678');
    });

    test('preserves + # * characters', () {
      final (:phone, :error) = vm.sanitizePhone('+886-2-1234#5678');
      expect(error, isNull);
      expect(phone, '+88621234#5678');
    });

    test('returns error when sanitized length < 5', () {
      final (:phone, :error) = vm.sanitizePhone('12');
      expect(phone, isNull);
      expect(error, 'Phone number is invalid.');
    });

    test('returns error for empty input', () {
      final (:phone, :error) = vm.sanitizePhone('');
      expect(phone, isNull);
      expect(error, isNotNull);
    });
  });
}
