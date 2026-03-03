import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_flutter/features/shipment/data/shipment_repository.dart';

import '../../../test_helpers/recording_dio_adapter.dart';

void main() {
  test('submitDelivery posts delivery payload to tracking endpoint', () async {
    final adapter = RecordingDioAdapter(responder: (RequestOptions options) {
      expect(options.path, '/shipments/907563299214/delivery');
      expect(options.method, 'POST');
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
    );

    expect(adapter.requests, hasLength(1));
  });

  test('submitException posts exception payload to tracking endpoint',
      () async {
    final adapter = RecordingDioAdapter(responder: (RequestOptions options) {
      expect(options.path, '/shipments/907563299214/exception');
      expect(options.method, 'POST');
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
    );

    expect(adapter.requests, hasLength(1));
  });
}
