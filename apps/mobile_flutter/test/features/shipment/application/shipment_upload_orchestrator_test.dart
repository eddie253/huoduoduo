import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile_flutter/features/shipment/application/shipment_upload_orchestrator.dart';
import 'package:mobile_flutter/features/shipment/data/local/media_local_repository.dart';
import 'package:mobile_flutter/features/shipment/data/shipment_repository.dart';
import 'package:mobile_flutter/features/shipment/domain/media_queue_models.dart';

void main() {
  sqfliteFfiInit();

  late Directory tempDir;
  late MediaLocalDatabase mediaLocalDatabase;
  late SqfliteMediaLocalRepository mediaLocalRepository;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('shipment-orchestrator-test-');
    mediaLocalDatabase = MediaLocalDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: p.join(tempDir.path, 'media_local_test.db'),
    );
    mediaLocalRepository = SqfliteMediaLocalRepository(mediaLocalDatabase);
    await mediaLocalRepository.init();
  });

  tearDown(() async {
    await mediaLocalRepository.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('marks uploaded when repository call succeeds', () async {
    final imageFile = File(p.join(tempDir.path, 'delivery_ok.jpg'));
    await imageFile.writeAsBytes(<int>[1, 2, 3, 4]);

    final orchestrator = ShipmentUploadOrchestrator(
      shipmentRepository: _SuccessShipmentRepository(),
      mediaLocalRepository: mediaLocalRepository,
    );

    final result = await orchestrator.uploadDelivery(
      trackingNo: '907563299214',
      filePath: imageFile.path,
      fileName: 'delivery_ok.jpg',
      latitude: '25.03',
      longitude: '121.56',
      metadata: const <String, String>{'source': 'unit-test'},
    );

    expect(result.status, MediaQueueStatus.uploaded);
    final uploaded =
        await mediaLocalRepository.listByStatus(MediaQueueStatus.uploaded);
    expect(uploaded, hasLength(1));
    expect(uploaded.first.id, result.queueId);
  });

  test('marks failed and increments retry count when repository call fails',
      () async {
    final imageFile = File(p.join(tempDir.path, 'delivery_fail.jpg'));
    await imageFile.writeAsBytes(<int>[7, 8, 9]);

    final orchestrator = ShipmentUploadOrchestrator(
      shipmentRepository: _FailShipmentRepository(),
      mediaLocalRepository: mediaLocalRepository,
    );

    final result = await orchestrator.uploadDelivery(
      trackingNo: '907563299214',
      filePath: imageFile.path,
      fileName: 'delivery_fail.jpg',
      latitude: '25.03',
      longitude: '121.56',
    );

    expect(result.status, MediaQueueStatus.failed);
    expect(result.errorCode, 'LEGACY_TIMEOUT');
    final failed =
        await mediaLocalRepository.listByStatus(MediaQueueStatus.failed);
    expect(failed, hasLength(1));
    expect(failed.first.retryCount, 1);
    expect(failed.first.lastErrorCode, 'LEGACY_TIMEOUT');
  });

  test('moves failed item to dead letter when retry limit is exceeded',
      () async {
    final imageFile = File(p.join(tempDir.path, 'delivery_dead_letter.jpg'));
    await imageFile.writeAsBytes(<int>[7, 8, 9]);

    final orchestrator = ShipmentUploadOrchestrator(
      shipmentRepository: _FailShipmentRepository(),
      mediaLocalRepository: mediaLocalRepository,
    );

    final first = await orchestrator.uploadDelivery(
      trackingNo: '907563299214',
      filePath: imageFile.path,
      fileName: 'delivery_dead_letter.jpg',
      latitude: '25.03',
      longitude: '121.56',
      maxRetryCount: 5,
    );
    expect(first.status, MediaQueueStatus.failed);

    final retry = await orchestrator.retryFailedUploads(maxRetryCount: 1);
    expect(retry.processed, 1);
    expect(retry.deadLetter, 1);

    final deadLetter =
        await mediaLocalRepository.listByStatus(MediaQueueStatus.deadLetter);
    expect(deadLetter, hasLength(1));
  });

  test('uploads exception payload successfully', () async {
    final imageFile = File(p.join(tempDir.path, 'exception_ok.jpg'));
    await imageFile.writeAsBytes(<int>[1, 2, 3, 4]);

    final repository = _SuccessShipmentRepository();
    final orchestrator = ShipmentUploadOrchestrator(
      shipmentRepository: repository,
      mediaLocalRepository: mediaLocalRepository,
    );

    final result = await orchestrator.uploadException(
      trackingNo: '907563299214',
      filePath: imageFile.path,
      fileName: 'exception_ok.jpg',
      reasonCode: 'WEATHER',
      reasonMessage: 'rain',
      latitude: '25.03',
      longitude: '121.56',
    );

    expect(result.status, MediaQueueStatus.uploaded);
    expect(repository.exceptionSubmitCount, 1);
  });

  test('rejects sensitive metadata before enqueue', () async {
    final imageFile = File(p.join(tempDir.path, 'delivery_sensitive.jpg'));
    await imageFile.writeAsBytes(<int>[1, 2, 3]);

    final orchestrator = ShipmentUploadOrchestrator(
      shipmentRepository: _SuccessShipmentRepository(),
      mediaLocalRepository: mediaLocalRepository,
    );

    await expectLater(
      orchestrator.uploadDelivery(
        trackingNo: '907563299214',
        filePath: imageFile.path,
        fileName: 'delivery_sensitive.jpg',
        latitude: '25.03',
        longitude: '121.56',
        metadata: const <String, String>{'access_token': 'forbidden'},
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('runStartupMaintenance moves retry-exceeded failed rows to dead letter',
      () async {
    final imageFile = File(p.join(tempDir.path, 'maintenance_dead_letter.jpg'));
    await imageFile.writeAsBytes(<int>[3, 4, 5]);

    final queued = await mediaLocalRepository.enqueue(
      MediaQueueDraft(
        trackingNo: '907563299214',
        filePath: imageFile.path,
        fileName: 'maintenance_dead_letter.jpg',
        mediaType: MediaType.deliveryPhoto,
        metadata: const <String, String>{
          'latitude': '25.03',
          'longitude': '121.56',
        },
      ),
    );

    await mediaLocalRepository.markFailed(queued.id,
        errorCode: 'LEGACY_TIMEOUT');
    await mediaLocalRepository.markFailed(queued.id,
        errorCode: 'LEGACY_TIMEOUT');

    final orchestrator = ShipmentUploadOrchestrator(
      shipmentRepository: _SuccessShipmentRepository(),
      mediaLocalRepository: mediaLocalRepository,
    );
    await orchestrator.runStartupMaintenance(maxRetryCount: 1);

    final deadLetter =
        await mediaLocalRepository.listByStatus(MediaQueueStatus.deadLetter);
    expect(deadLetter, hasLength(1));
    expect(deadLetter.first.id, queued.id);
  });

  test('retryFailedUploads uploads failed rows when repository is healthy',
      () async {
    final imageFile = File(p.join(tempDir.path, 'retry_success.jpg'));
    await imageFile.writeAsBytes(<int>[8, 8, 8]);

    final queued = await mediaLocalRepository.enqueue(
      MediaQueueDraft(
        trackingNo: '907563299214',
        filePath: imageFile.path,
        fileName: 'retry_success.jpg',
        mediaType: MediaType.deliveryPhoto,
        metadata: const <String, String>{
          'latitude': '25.03',
          'longitude': '121.56',
        },
      ),
    );
    await mediaLocalRepository.markFailed(queued.id,
        errorCode: 'LEGACY_TIMEOUT');

    final orchestrator = ShipmentUploadOrchestrator(
      shipmentRepository: _SuccessShipmentRepository(),
      mediaLocalRepository: mediaLocalRepository,
    );
    final result = await orchestrator.retryFailedUploads();

    expect(result.processed, 1);
    expect(result.uploaded, 1);
    expect(result.failed, 0);
    expect(result.deadLetter, 0);
  });

  test('UPLOAD_ERROR_SINGLE_RETRY_SUCCESS retries by queue id', () async {
    final imageFile = File(p.join(tempDir.path, 'retry_single_success.jpg'));
    await imageFile.writeAsBytes(<int>[8, 8, 8]);

    final queued = await mediaLocalRepository.enqueue(
      MediaQueueDraft(
        trackingNo: '907563299214',
        filePath: imageFile.path,
        fileName: 'retry_single_success.jpg',
        mediaType: MediaType.deliveryPhoto,
        metadata: const <String, String>{
          'latitude': '25.03',
          'longitude': '121.56',
        },
      ),
    );
    await mediaLocalRepository.markFailed(queued.id,
        errorCode: 'LEGACY_TIMEOUT');

    final orchestrator = ShipmentUploadOrchestrator(
      shipmentRepository: _SuccessShipmentRepository(),
      mediaLocalRepository: mediaLocalRepository,
    );

    final result = await orchestrator.retryFailedUploadById(queued.id);
    expect(result.status, MediaQueueStatus.uploaded);
  });

  test('UPLOAD_ERROR_SINGLE_RETRY_FAILURE keeps failed/dead_letter semantics',
      () async {
    final imageFile = File(p.join(tempDir.path, 'retry_single_fail.jpg'));
    await imageFile.writeAsBytes(<int>[8, 8, 8]);

    final queued = await mediaLocalRepository.enqueue(
      MediaQueueDraft(
        trackingNo: '907563299214',
        filePath: imageFile.path,
        fileName: 'retry_single_fail.jpg',
        mediaType: MediaType.deliveryPhoto,
        metadata: const <String, String>{
          'latitude': '25.03',
          'longitude': '121.56',
        },
      ),
    );
    await mediaLocalRepository.markFailed(queued.id,
        errorCode: 'LEGACY_TIMEOUT');

    final orchestrator = ShipmentUploadOrchestrator(
      shipmentRepository: _FailShipmentRepository(),
      mediaLocalRepository: mediaLocalRepository,
    );

    final result = await orchestrator.retryFailedUploadById(
      queued.id,
      maxRetryCount: 1,
    );
    expect(result.status, MediaQueueStatus.deadLetter);
  });

  test('extracts UPLOAD_FAILED when error has no legacy error code', () async {
    final imageFile = File(p.join(tempDir.path, 'unknown_fail.jpg'));
    await imageFile.writeAsBytes(<int>[6, 6, 6]);

    final orchestrator = ShipmentUploadOrchestrator(
      shipmentRepository: _UnknownFailShipmentRepository(),
      mediaLocalRepository: mediaLocalRepository,
    );

    final result = await orchestrator.uploadDelivery(
      trackingNo: '907563299214',
      filePath: imageFile.path,
      fileName: 'unknown_fail.jpg',
      latitude: '25.03',
      longitude: '121.56',
    );

    expect(result.status, MediaQueueStatus.failed);
    expect(result.errorCode, 'UPLOAD_FAILED');
  });
}

class _SuccessShipmentRepository implements ShipmentRepository {
  int exceptionSubmitCount = 0;

  @override
  Future<void> submitDelivery({
    required String trackingNo,
    required String imageBase64,
    required String imageFileName,
    required String latitude,
    required String longitude,
  }) async {}

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
    exceptionSubmitCount++;
  }
}

class _FailShipmentRepository extends _SuccessShipmentRepository {
  @override
  Future<void> submitDelivery({
    required String trackingNo,
    required String imageBase64,
    required String imageFileName,
    required String latitude,
    required String longitude,
  }) async {
    throw Exception('LEGACY_TIMEOUT: failed to submit delivery');
  }
}

class _UnknownFailShipmentRepository extends _SuccessShipmentRepository {
  @override
  Future<void> submitDelivery({
    required String trackingNo,
    required String imageBase64,
    required String imageFileName,
    required String latitude,
    required String longitude,
  }) async {
    throw Exception('socket closed by peer');
  }
}
