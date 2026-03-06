import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile_flutter/features/shipment/application/connectivity_aware_flush_service.dart';
import 'package:mobile_flutter/features/shipment/application/shipment_upload_orchestrator.dart';
import 'package:mobile_flutter/features/shipment/data/local/media_local_repository.dart';
import 'package:mobile_flutter/features/shipment/domain/shipment_models.dart';
import 'package:mobile_flutter/features/shipment/domain/shipment_repository.dart';

class _TrackingShipmentRepository implements ShipmentRepository {
  int submitDeliveryCallCount = 0;

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
    submitDeliveryCallCount++;
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
  }) async {}

  @override
  Future<ShipmentDetail> fetchShipment(String trackingNo) async {
    return ShipmentDetail(trackingNo: trackingNo, status: 'uploaded');
  }
}

Future<ShipmentUploadOrchestrator> _buildOrchestrator(String dbName) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final dir = await Directory.systemTemp.createTemp('caf_test_');
  final db = MediaLocalDatabase(
    databaseFactory: databaseFactoryFfi,
    databasePath: p.join(dir.path, '$dbName.db'),
  );
  final repo = SqfliteMediaLocalRepository(db);
  await repo.init();
  return ShipmentUploadOrchestrator(
    shipmentRepository: _TrackingShipmentRepository(),
    mediaLocalRepository: repo,
  );
}

void main() {
  group('ConnectivityAwareFlushService', () {
    test('offline→online transition triggers retryFailedUploads', () async {
      final orchestrator = await _buildOrchestrator('caf1');
      final controller = StreamController<List<ConnectivityResult>>();

      var retryCalled = false;
      final service = ConnectivityAwareFlushService(
        orchestrator: orchestrator,
        connectivityStream: controller.stream,
        initiallyOnline: false,
      );
      service.start();

      service.onRetry = () => retryCalled = true;

      controller.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      service.stop();
      await controller.close();

      expect(retryCalled, isTrue);
    });

    test('online→online does not trigger retryFailedUploads', () async {
      final orchestrator = await _buildOrchestrator('caf2');
      final controller = StreamController<List<ConnectivityResult>>();

      var retryCalled = false;
      final service = ConnectivityAwareFlushService(
        orchestrator: orchestrator,
        connectivityStream: controller.stream,
        initiallyOnline: true,
      );
      service.start();
      service.onRetry = () => retryCalled = true;

      controller.add([ConnectivityResult.mobile]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      service.stop();
      await controller.close();

      expect(retryCalled, isFalse);
    });

    test('offline→offline does not trigger retryFailedUploads', () async {
      final orchestrator = await _buildOrchestrator('caf3');
      final controller = StreamController<List<ConnectivityResult>>();

      var retryCalled = false;
      final service = ConnectivityAwareFlushService(
        orchestrator: orchestrator,
        connectivityStream: controller.stream,
        initiallyOnline: false,
      );
      service.start();
      service.onRetry = () => retryCalled = true;

      controller.add([ConnectivityResult.none]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      service.stop();
      await controller.close();

      expect(retryCalled, isFalse);
    });

    test('stop prevents further retry calls', () async {
      final orchestrator = await _buildOrchestrator('caf4');
      final controller = StreamController<List<ConnectivityResult>>();

      var retryCalled = false;
      final service = ConnectivityAwareFlushService(
        orchestrator: orchestrator,
        connectivityStream: controller.stream,
        initiallyOnline: false,
      );
      service.start();
      service.onRetry = () => retryCalled = true;

      service.stop();
      controller.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await controller.close();
      expect(retryCalled, isFalse);
    });
  });
}
