import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/shipment_confirmation_provider.dart';
import '../application/transaction_event_bus.dart';
import '../data/local/media_local_provider.dart';
import '../data/shipment_repository.dart';
import '../domain/media_local_repository.dart';
import '../domain/shipment_models.dart';
import '../domain/shipment_repository.dart';
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

class QueueSnapshot {
  const QueueSnapshot({
    required this.pending,
    required this.failed,
    required this.uploaded,
    required this.deadLetter,
  });

  factory QueueSnapshot.empty() {
    return const QueueSnapshot(
      pending: <MediaQueueItem>[],
      failed: <MediaQueueItem>[],
      uploaded: <MediaQueueItem>[],
      deadLetter: <MediaQueueItem>[],
    );
  }

  final List<MediaQueueItem> pending;
  final List<MediaQueueItem> failed;
  final List<MediaQueueItem> uploaded;
  final List<MediaQueueItem> deadLetter;
}

class ShipmentUploadOrchestrator {
  ShipmentUploadOrchestrator({
    required ShipmentRepository shipmentRepository,
    required MediaLocalRepository mediaLocalRepository,
    void Function(String trackingNo, ShipmentDetail detail)?
        onShipmentConfirmed,
  })  : _shipmentRepository = shipmentRepository,
        _mediaLocalRepository = mediaLocalRepository,
        _onShipmentConfirmed = onShipmentConfirmed;

  final ShipmentRepository _shipmentRepository;
  final MediaLocalRepository _mediaLocalRepository;
  final void Function(String trackingNo, ShipmentDetail detail)?
      _onShipmentConfirmed;
  final Set<String> _activeTrackingNos = <String>{};

  Future<QueueSnapshot> getQueueSnapshot() async {
    final pending = await _mediaLocalRepository.listByStatus(
      MediaQueueStatus.pending,
    );
    final failed = await _mediaLocalRepository.listByStatus(
      MediaQueueStatus.failed,
    );
    final uploaded = await _mediaLocalRepository.listByStatus(
      MediaQueueStatus.uploaded,
    );
    final deadLetter = await _mediaLocalRepository.listByStatus(
      MediaQueueStatus.deadLetter,
    );
    return QueueSnapshot(
      pending: pending,
      failed: failed,
      uploaded: uploaded,
      deadLetter: deadLetter,
    );
  }

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
  }) async {
    if (_activeTrackingNos.contains(trackingNo)) {
      return const ShipmentUploadResult(
        queueId: -1,
        status: MediaQueueStatus.pending,
      );
    }
    _activeTrackingNos.add(trackingNo);
    try {
      return await _enqueueAndUpload(
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
    } finally {
      _activeTrackingNos.remove(trackingNo);
    }
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
  }) async {
    if (_activeTrackingNos.contains(trackingNo)) {
      return const ShipmentUploadResult(
        queueId: -1,
        status: MediaQueueStatus.pending,
      );
    }
    _activeTrackingNos.add(trackingNo);
    try {
      return await _enqueueAndUpload(
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
    } finally {
      _activeTrackingNos.remove(trackingNo);
    }
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
        TransactionEventBus.instance
            .emit(TransactionEvent(trackingNo: item.trackingNo));
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

  Future<ShipmentUploadResult> retryFailedUploadById(
    int queueId, {
    int maxRetryCount = defaultMaxRetryCount,
  }) async {
    final item = await _mediaLocalRepository.getById(queueId);
    if (item == null) {
      throw StateError('Queue item not found: $queueId');
    }

    final retryable = item.status == MediaQueueStatus.failed ||
        item.status == MediaQueueStatus.deadLetter;
    if (!retryable) {
      return ShipmentUploadResult(
        queueId: item.id,
        status: item.status,
        errorCode: item.lastErrorCode,
      );
    }

    if (item.retryCount >= maxRetryCount) {
      await _mediaLocalRepository.markDeadLetter(
        item.id,
        errorCode: item.lastErrorCode ?? 'MAX_RETRY_EXCEEDED',
      );
      return ShipmentUploadResult(
        queueId: item.id,
        status: MediaQueueStatus.deadLetter,
        errorCode: item.lastErrorCode ?? 'MAX_RETRY_EXCEEDED',
      );
    }

    final success = await _attemptUpload(item);
    if (success) {
      await _mediaLocalRepository.markUploaded(item.id);
      TransactionEventBus.instance
          .emit(TransactionEvent(trackingNo: item.trackingNo));
      return ShipmentUploadResult(
        queueId: item.id,
        status: MediaQueueStatus.uploaded,
      );
    }

    final refreshed = await _mediaLocalRepository.getById(item.id);
    if (refreshed != null && refreshed.retryCount >= maxRetryCount) {
      await _mediaLocalRepository.markDeadLetter(
        refreshed.id,
        errorCode: refreshed.lastErrorCode ?? 'MAX_RETRY_EXCEEDED',
      );
      return ShipmentUploadResult(
        queueId: refreshed.id,
        status: MediaQueueStatus.deadLetter,
        errorCode: refreshed.lastErrorCode ?? 'MAX_RETRY_EXCEEDED',
      );
    }

    return ShipmentUploadResult(
      queueId: item.id,
      status: MediaQueueStatus.failed,
      errorCode: refreshed?.lastErrorCode,
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
      TransactionEventBus.instance
          .emit(TransactionEvent(trackingNo: queued.trackingNo));
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
    final idempotencyKey = '${item.id}_${item.retryCount}';
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
            idempotencyKey: idempotencyKey,
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
            idempotencyKey: idempotencyKey,
          );
          return true;
        case MediaType.signature:
          await _shipmentRepository.submitDelivery(
            trackingNo: item.trackingNo,
            imageBase64: '',
            imageFileName: item.fileName,
            latitude: item.metadata['latitude'] ?? '0',
            longitude: item.metadata['longitude'] ?? '0',
            signatureBase64: imageBase64,
            idempotencyKey: idempotencyKey,
          );
          final detail =
              await _shipmentRepository.fetchShipment(item.trackingNo);
          _onShipmentConfirmed?.call(item.trackingNo, detail);
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
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final code = data['code'] as String?;
        if (code != null && code.isNotEmpty) return code;
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'TIMEOUT';
      }
    }
    return 'UPLOAD_FAILED';
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
    onShipmentConfirmed: (trackingNo, detail) {
      ref
          .read(shipmentConfirmationProvider.notifier)
          .confirm(trackingNo, detail);
    },
  );
});
