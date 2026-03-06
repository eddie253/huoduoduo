import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../domain/shipment_models.dart';
import '../domain/shipment_repository.dart';

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
    String? signatureBase64,
    required String idempotencyKey,
  }) async {
    await _dio.post<void>(
      '/shipments/$trackingNo/delivery',
      data: <String, dynamic>{
        'imageBase64': imageBase64,
        'imageFileName': imageFileName,
        'latitude': latitude,
        'longitude': longitude,
        if (signatureBase64 != null) 'signatureBase64': signatureBase64,
      },
      options: Options(
        headers: <String, String>{'X-Idempotency-Key': idempotencyKey},
      ),
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
    required String idempotencyKey,
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
      options: Options(
        headers: <String, String>{'X-Idempotency-Key': idempotencyKey},
      ),
    );
  }

  @override
  Future<ShipmentDetail> fetchShipment(String trackingNo) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/shipments/$trackingNo',
    );
    return ShipmentDetail.fromJson(response.data ?? <String, dynamic>{});
  }
}

final shipmentRepositoryProvider = Provider<ShipmentRepository>((ref) {
  return ShipmentRepositoryImpl(ref.watch(uploadDioProvider));
});
