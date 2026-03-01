import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';

abstract class ShipmentRepository {
  Future<void> submitDelivery({
    required String trackingNo,
    required String imageBase64,
    required String imageFileName,
    required String latitude,
    required String longitude,
  });

  Future<void> submitException({
    required String trackingNo,
    required String imageBase64,
    required String imageFileName,
    required String reasonCode,
    String? reasonMessage,
    required String latitude,
    required String longitude,
  });
}

class ShipmentRepositoryImpl implements ShipmentRepository {
  ShipmentRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<void> submitDelivery({
    required String trackingNo,
    required String imageBase64,
    required String imageFileName,
    required String latitude,
    required String longitude,
  }) async {
    await _dio.post<void>(
      '/shipments/$trackingNo/delivery',
      data: <String, dynamic>{
        'imageBase64': imageBase64,
        'imageFileName': imageFileName,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  @override
  Future<void> submitException({
    required String trackingNo,
    required String imageBase64,
    required String imageFileName,
    required String reasonCode,
    String? reasonMessage,
    required String latitude,
    required String longitude,
  }) async {
    await _dio.post<void>(
      '/shipments/$trackingNo/exception',
      data: <String, dynamic>{
        'imageBase64': imageBase64,
        'imageFileName': imageFileName,
        'reasonCode': reasonCode,
        'reasonMessage': reasonMessage,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }
}

final shipmentRepositoryProvider = Provider<ShipmentRepository>((ref) {
  return ShipmentRepositoryImpl(ref.watch(dioProvider));
});
