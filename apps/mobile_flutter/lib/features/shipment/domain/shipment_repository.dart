import 'shipment_models.dart';

abstract class ShipmentRepository {
  Future<void> submitDelivery({
    required String trackingNo,
    required String imageBase64,
    required String imageFileName,
    required String latitude,
    required String longitude,
    String? signatureBase64,
    required String idempotencyKey,
  });

  Future<void> submitException({
    required String trackingNo,
    required String imageBase64,
    required String imageFileName,
    required String reasonCode,
    String? reasonMessage,
    required String latitude,
    required String longitude,
    required String idempotencyKey,
  });

  Future<ShipmentDetail> fetchShipment(String trackingNo);
}
