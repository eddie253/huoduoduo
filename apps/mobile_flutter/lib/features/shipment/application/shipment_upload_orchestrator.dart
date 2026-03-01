import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/media_local_provider.dart';
import '../data/local/media_local_repository.dart';
import '../data/shipment_repository.dart';
import '../domain/media_queue_models.dart';

const int defaultMaxRetryCount = 5;
const Duration defaultUploadedRetention = Duration(days: 7);

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

class RetryBatchResult {
  const RetryBatchResult({
    required this.processed,
    required this.uploaded,
    required this.failed,
    required this.deadLetter,
  });

  final int processed;
  final int uploaded;
  final int failed;
  final int deadLetter;
}

class ShipmentUploadOrchestrator {
  ShipmentUploadOrchestrator({
    required ShipmentRepository shipmentRepository,
    required MediaLocalRepository mediaLocalRepository,
  })  : _shipmentRepository = shipmentRepository,
        _mediaLocalRepository = mediaLocalRepository;

  final ShipmentRepository _shipmentRepository;
  final MediaLocalRepository _mediaLocalRepository;

  Future<void> runStartupMaintenance({
    Duration uploadedRetention = defaultUploadedRetention,
    int maxRetryCount = defaultMaxRetryCount,
  }) async {
    await _mediaLocalRepository.cleanupUploadedOlderThan(
      DateTime.now().toUtc().subtract(uploadedRetention),
    );

    final failedItems = await _mediaLocalRepository.listByStatus(
      MediaQueueStatus.failed,
      limit: 200,
    );
    for (final item in failedItems) {
      if (item.retryCount >= maxRetryCount) {
        await _mediaLocalRepository.markDeadLetter(
          item.id,
          errorCode: item.lastErrorCode ?? 'MAX_RETRY_EXCEEDED',
        );
      }
    }
  }

  Future<ShipmentUploadResult> uploadDelivery({
    required String trackingNo,
    required String filePath,
    required String fileName,
    required String latitude,
    required String longitude,
    Map<String, String> metadata = const <String, String>{},
    int maxRetryCount = defaultMaxRetryCount,
  }) {
    return _enqueueAndUpload(
      draft: MediaQueueDraft(
        trackingNo: trackingNo,
        filePath: filePath,
        fileName: fileName,
        mediaType: MediaType.deliveryPhoto,
        metadata: <String, String>{
          ...metadata,
          'latitude': latitude,
          'longitude': longitude,
          'operation': 'delivery',
        },
      ),
      maxRetryCount: maxRetryCount,
    );
  }

  Future<ShipmentUploadResult> uploadException({
    required String trackingNo,
    required String filePath,
    required String fileName,
    required String reasonCode,
    String? reasonMessage,
    required String latitude,
    required String longitude,
    Map<String, String> metadata = const <String, String>{},
    int maxRetryCount = defaultMaxRetryCount,
  }) {
    return _enqueueAndUpload(
      draft: MediaQueueDraft(
        trackingNo: trackingNo,
        filePath: filePath,
        fileName: fileName,
        mediaType: MediaType.exceptionPhoto,
        metadata: <String, String>{
          ...metadata,
          'reasonCode': reasonCode,
          'reasonMessage': reasonMessage ?? '',
          'latitude': latitude,
          'longitude': longitude,
          'operation': 'exception',
        },
      ),
      maxRetryCount: maxRetryCount,
    );
  }

  Future<RetryBatchResult> retryFailedUploads({
    int maxRetryCount = defaultMaxRetryCount,
    int limit = 20,
  }) async {
    final failedItems = await _mediaLocalRepository.listByStatus(
      MediaQueueStatus.failed,
      limit: limit,
    );

    var uploaded = 0;
    var failed = 0;
    var deadLetter = 0;

    for (final item in failedItems) {
      if (item.retryCount >= maxRetryCount) {
        await _mediaLocalRepository.markDeadLetter(
          item.id,
          errorCode: item.lastErrorCode ?? 'MAX_RETRY_EXCEEDED',
        );
        deadLetter++;
        continue;
      }

      final success = await _attemptUpload(item);
      if (success) {
        await _mediaLocalRepository.markUploaded(item.id);
        uploaded++;
        continue;
      }

      final freshItem = await _mediaLocalRepository.getById(item.id);
      if (freshItem != null && freshItem.retryCount >= maxRetryCount) {
        await _mediaLocalRepository.markDeadLetter(
          freshItem.id,
          errorCode: freshItem.lastErrorCode ?? 'MAX_RETRY_EXCEEDED',
        );
        deadLetter++;
      } else {
        failed++;
      }
    }

    return RetryBatchResult(
      processed: failedItems.length,
      uploaded: uploaded,
      failed: failed,
      deadLetter: deadLetter,
    );
  }

  Future<ShipmentUploadResult> _enqueueAndUpload({
    required MediaQueueDraft draft,
    required int maxRetryCount,
  }) async {
    final queued = await _mediaLocalRepository.enqueue(draft);
    final success = await _attemptUpload(queued);
    if (success) {
      await _mediaLocalRepository.markUploaded(queued.id);
      return ShipmentUploadResult(
        queueId: queued.id,
        status: MediaQueueStatus.uploaded,
      );
    }

    final failedItem = await _mediaLocalRepository.getById(queued.id);
    if (failedItem != null && failedItem.retryCount >= maxRetryCount) {
      await _mediaLocalRepository.markDeadLetter(
        failedItem.id,
        errorCode: failedItem.lastErrorCode ?? 'MAX_RETRY_EXCEEDED',
      );
      return ShipmentUploadResult(
        queueId: failedItem.id,
        status: MediaQueueStatus.deadLetter,
        errorCode: failedItem.lastErrorCode,
      );
    }

    final refreshed = await _mediaLocalRepository.getById(queued.id);
    return ShipmentUploadResult(
      queueId: queued.id,
      status: MediaQueueStatus.failed,
      errorCode: refreshed?.lastErrorCode,
    );
  }

  Future<bool> _attemptUpload(MediaQueueItem item) async {
    try {
      final imageBase64 = await _toBase64(item.filePath);
      switch (item.mediaType) {
        case MediaType.deliveryPhoto:
          await _shipmentRepository.submitDelivery(
            trackingNo: item.trackingNo,
            imageBase64: imageBase64,
            imageFileName: item.fileName,
            latitude: item.metadata['latitude'] ?? '0',
            longitude: item.metadata['longitude'] ?? '0',
          );
          return true;
        case MediaType.exceptionPhoto:
          await _shipmentRepository.submitException(
            trackingNo: item.trackingNo,
            imageBase64: imageBase64,
            imageFileName: item.fileName,
            reasonCode: item.metadata['reasonCode'] ?? 'UNKNOWN',
            reasonMessage: item.metadata['reasonMessage'],
            latitude: item.metadata['latitude'] ?? '0',
            longitude: item.metadata['longitude'] ?? '0',
          );
          return true;
        case MediaType.signature:
          await _shipmentRepository.submitDelivery(
            trackingNo: item.trackingNo,
            imageBase64: imageBase64,
            imageFileName: item.fileName,
            latitude: item.metadata['latitude'] ?? '0',
            longitude: item.metadata['longitude'] ?? '0',
          );
          return true;
      }
    } catch (error) {
      final code = _extractErrorCode(error);
      await _mediaLocalRepository.markFailed(item.id, errorCode: code);
      return false;
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
