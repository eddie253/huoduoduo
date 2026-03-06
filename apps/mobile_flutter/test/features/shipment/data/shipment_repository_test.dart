import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_flutter/features/shipment/data/shipment_repository.dart';

import '../../../test_helpers/recording_dio_adapter.dart';

void main() {
  test('submitDelivery posts delivery payload and idempotency header',
      () async {
    final adapter = RecordingDioAdapter(responder: (RequestOptions options) {
      expect(options.path, '/shipments/907563299214/delivery');
      expect(options.method, 'POST');
      expect(options.headers['X-Idempotency-Key'], 'idem-key-1');
      expect(options.data, <String, dynamic>{
        'imageBase64': 'BASE64_DATA',
        'imageFileName': 'delivery.jpg',
        'latitude': '25.03',
        'longitude': '121.56',
      });
      return jsonBody(<String, dynamic>{});
    });
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = ShipmentRepositoryImpl(dio);

    await repository.submitDelivery(
      trackingNo: '907563299214',
      imageBase64: 'BASE64_DATA',
      imageFileName: 'delivery.jpg',
      latitude: '25.03',
      longitude: '121.56',
      idempotencyKey: 'idem-key-1',
    );

    expect(adapter.requests, hasLength(1));
  });

  test('submitDelivery includes signatureBase64 when provided', () async {
    final adapter = RecordingDioAdapter(responder: (RequestOptions options) {
      expect((options.data as Map<String, dynamic>)['signatureBase64'],
          'SIG_BASE64');
      return jsonBody(<String, dynamic>{});
    });
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = ShipmentRepositoryImpl(dio);

    await repository.submitDelivery(
      trackingNo: '907563299214',
      imageBase64: '',
      imageFileName: 'sig.png',
      latitude: '25.03',
      longitude: '121.56',
      signatureBase64: 'SIG_BASE64',
      idempotencyKey: 'idem-key-sig',
    );

    expect(adapter.requests, hasLength(1));
  });

  test('submitException posts exception payload and idempotency header',
      () async {
    final adapter = RecordingDioAdapter(responder: (RequestOptions options) {
      expect(options.path, '/shipments/907563299214/exception');
      expect(options.method, 'POST');
      expect(options.headers['X-Idempotency-Key'], 'idem-key-2');
      expect(options.data, <String, dynamic>{
        'imageBase64': 'BASE64_DATA',
        'imageFileName': 'exception.jpg',
        'reasonCode': 'WEATHER',
        'reasonMessage': 'rain',
        'latitude': '25.03',
        'longitude': '121.56',
      });
      return jsonBody(<String, dynamic>{});
    });
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = ShipmentRepositoryImpl(dio);

    await repository.submitException(
      trackingNo: '907563299214',
      imageBase64: 'BASE64_DATA',
      imageFileName: 'exception.jpg',
      reasonCode: 'WEATHER',
      reasonMessage: 'rain',
      latitude: '25.03',
      longitude: '121.56',
      idempotencyKey: 'idem-key-2',
    );

    expect(adapter.requests, hasLength(1));
  });

  test('fetchShipment GETs and parses shipment detail', () async {
    final adapter = RecordingDioAdapter(responder: (RequestOptions options) {
      expect(options.path, '/shipments/907563299214');
      expect(options.method, 'GET');
      return jsonBody(<String, dynamic>{
        'trackingNo': '907563299214',
        'status': 'delivered',
      });
    });
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = ShipmentRepositoryImpl(dio);

    final detail = await repository.fetchShipment('907563299214');

    expect(detail.trackingNo, '907563299214');
    expect(detail.status, 'delivered');
  });
}
