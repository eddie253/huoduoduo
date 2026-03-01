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
}

class _SuccessShipmentRepository implements ShipmentRepository {
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
  }) async {}
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
