import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/media_local_provider.dart';
import '../data/local/media_local_repository.dart';
import '../data/shipment_repository.dart';
import '../domain/media_queue_models.dart';

class ShipmentUploadResult {
  const ShipmentUploadResult({
    required this.queueId,
    required this.status,
    this.errorCode,
  });

  final int queueId;
  final MediaQueueStatus status;
  final String? errorCode;
}

class ShipmentUploadOrchestrator {
  ShipmentUploadOrchestrator({
    required ShipmentRepository shipmentRepository,
    required MediaLocalRepository mediaLocalRepository,
  })  : _shipmentRepository = shipmentRepository,
        _mediaLocalRepository = mediaLocalRepository;

  final ShipmentRepository _shipmentRepository;
  final MediaLocalRepository _mediaLocalRepository;

  Future<ShipmentUploadResult> uploadDelivery({
    required String trackingNo,
    required String filePath,
    required String fileName,
    required String latitude,
    required String longitude,
    Map<String, String> metadata = const <String, String>{},
  }) async {
    final queued = await _mediaLocalRepository.enqueue(
      MediaQueueDraft(
        trackingNo: trackingNo,
        filePath: filePath,
        fileName: fileName,
        mediaType: MediaType.deliveryPhoto,
        metadata: metadata,
      ),
    );

    try {
      final imageBase64 = await _toBase64(filePath);
      await _shipmentRepository.submitDelivery(
        trackingNo: trackingNo,
        imageBase64: imageBase64,
        imageFileName: fileName,
        latitude: latitude,
        longitude: longitude,
      );
      await _mediaLocalRepository.markUploaded(queued.id);
      return ShipmentUploadResult(
        queueId: queued.id,
        status: MediaQueueStatus.uploaded,
      );
    } catch (error) {
      final code = _extractErrorCode(error);
      await _mediaLocalRepository.markFailed(queued.id, errorCode: code);
      return ShipmentUploadResult(
        queueId: queued.id,
        status: MediaQueueStatus.failed,
        errorCode: code,
      );
    }
  }

  Future<String> _toBase64(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  String _extractErrorCode(Object error) {
    final raw = error.toString();
    final match = RegExp(r'LEGACY_[A-Z_]+').firstMatch(raw);
    return match?.group(0) ?? 'UPLOAD_FAILED';
  }
}

final shipmentUploadOrchestratorProvider =
    FutureProvider<ShipmentUploadOrchestrator>((
  Ref ref,
) async {
  final mediaLocalRepository =
      await ref.watch(mediaLocalRepositoryProvider.future);
  final shipmentRepository = ref.watch(shipmentRepositoryProvider);
  return ShipmentUploadOrchestrator(
    shipmentRepository: shipmentRepository,
    mediaLocalRepository: mediaLocalRepository,
  );
});
