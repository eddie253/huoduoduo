import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_flutter/features/shipment/application/shipment_upload_orchestrator.dart';
import 'package:mobile_flutter/features/shipment/domain/media_local_repository.dart';
import 'package:mobile_flutter/features/shipment/domain/shipment_models.dart';
import 'package:mobile_flutter/features/shipment/domain/shipment_repository.dart';
import 'package:mobile_flutter/features/shipment/domain/media_queue_models.dart';
import 'package:mobile_flutter/features/shipment/presentation/shipment_page.dart';

void main() {
  testWidgets('renders queue snapshot and refreshes via orchestrator',
      (WidgetTester tester) async {
    final orchestrator = _FakeShipmentUploadOrchestrator(
      queueSnapshot: QueueSnapshot(
        pending: <MediaQueueItem>[_item(1, MediaQueueStatus.pending)],
        failed: <MediaQueueItem>[
          _item(2, MediaQueueStatus.failed),
          _item(3, MediaQueueStatus.failed),
        ],
        uploaded: <MediaQueueItem>[_item(4, MediaQueueStatus.uploaded)],
        deadLetter: <MediaQueueItem>[_item(5, MediaQueueStatus.deadLetter)],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          shipmentUploadOrchestratorProvider
              .overrideWith((Ref ref) async => orchestrator),
        ],
        child: const MaterialApp(home: ShipmentPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Queue Snapshot'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('Uploaded'), findsOneWidget);
    expect(find.text('Dead Letter'), findsOneWidget);
    expect(orchestrator.getQueueSnapshotCallCount, greaterThanOrEqualTo(1));

    final beforeRefresh = orchestrator.getQueueSnapshotCallCount;
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(orchestrator.getQueueSnapshotCallCount, greaterThan(beforeRefresh));
  });

  testWidgets('shows tracking-required message when tracking number is empty',
      (WidgetTester tester) async {
    final orchestrator = _FakeShipmentUploadOrchestrator();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          shipmentUploadOrchestratorProvider
              .overrideWith((Ref ref) async => orchestrator),
        ],
        child: const MaterialApp(home: ShipmentPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Tracking No'),
      '',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Upload Delivery'));
    await tester.pumpAndSettle();

    expect(find.text('Tracking number is required.'), findsOneWidget);
  });

  testWidgets('shows image-required message when no image is selected',
      (WidgetTester tester) async {
    final orchestrator = _FakeShipmentUploadOrchestrator();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          shipmentUploadOrchestratorProvider
              .overrideWith((Ref ref) async => orchestrator),
        ],
        child: const MaterialApp(home: ShipmentPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Upload Delivery'));
    await tester.pumpAndSettle();

    expect(find.text('Please pick an image first.'), findsOneWidget);
  });

  testWidgets('retry failed action uses orchestrator and reports summary',
      (WidgetTester tester) async {
    final orchestrator = _FakeShipmentUploadOrchestrator(
      retryResult: const RetryBatchResult(
        processed: 3,
        uploaded: 2,
        failed: 1,
        deadLetter: 0,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          shipmentUploadOrchestratorProvider
              .overrideWith((Ref ref) async => orchestrator),
        ],
        child: const MaterialApp(home: ShipmentPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Retry Failed'));
    await tester.pumpAndSettle();

    expect(orchestrator.retryCallCount, 1);
    expect(
      find.text('Retry processed=3, uploaded=2, failed=1, deadLetter=0'),
      findsOneWidget,
    );
  });
}

MediaQueueItem _item(int id, MediaQueueStatus status) {
  final now = DateTime.utc(2026, 3, 2, 3, 0, id);
  return MediaQueueItem(
    id: id,
    trackingNo: '907563299214',
    filePath: 'app_media/907563299214/image_$id.jpg',
    fileName: 'image_$id.jpg',
    mediaType: MediaType.deliveryPhoto,
    status: status,
    retryCount: status == MediaQueueStatus.failed ? 1 : 0,
    lastErrorCode: status == MediaQueueStatus.failed ? 'LEGACY_TIMEOUT' : null,
    createdAt: now,
    updatedAt: now,
    metadata: const <String, String>{
      'latitude': '25.03',
      'longitude': '121.56'
    },
  );
}

class _FakeMediaLocalRepository implements MediaLocalRepository {
  _FakeMediaLocalRepository({
    List<MediaQueueItem>? pending,
    List<MediaQueueItem>? failed,
    List<MediaQueueItem>? uploaded,
    List<MediaQueueItem>? deadLetter,
  }) {
    _itemsByStatus[MediaQueueStatus.pending] = pending ?? <MediaQueueItem>[];
    _itemsByStatus[MediaQueueStatus.failed] = failed ?? <MediaQueueItem>[];
    _itemsByStatus[MediaQueueStatus.uploaded] = uploaded ?? <MediaQueueItem>[];
    _itemsByStatus[MediaQueueStatus.deadLetter] =
        deadLetter ?? <MediaQueueItem>[];
  }

  final Map<MediaQueueStatus, List<MediaQueueItem>> _itemsByStatus =
      <MediaQueueStatus, List<MediaQueueItem>>{};
  int listByStatusCallCount = 0;

  @override
  Future<void> init() async {}

  @override
  Future<MediaQueueItem> enqueue(MediaQueueDraft draft) async {
    final created = MediaQueueItem(
      id: 9000,
      trackingNo: draft.trackingNo,
      filePath: draft.filePath,
      fileName: draft.fileName,
      mediaType: draft.mediaType,
      status: MediaQueueStatus.pending,
      retryCount: 0,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      metadata: draft.metadata,
    );
    _itemsByStatus[MediaQueueStatus.pending] = <MediaQueueItem>[created];
    return created;
  }

  @override
  Future<MediaQueueItem?> getById(int id) async => null;

  @override
  Future<List<MediaQueueItem>> listByStatus(
    MediaQueueStatus status, {
    int limit = 50,
  }) async {
    listByStatusCallCount++;
    final values = _itemsByStatus[status] ?? <MediaQueueItem>[];
    return values.take(limit).toList(growable: false);
  }

  @override
  Future<void> markUploaded(int id) async {}

  @override
  Future<void> markFailed(int id, {String? errorCode}) async {}

  @override
  Future<void> markDeadLetter(int id, {String? errorCode}) async {}

  @override
  Future<int> cleanupUploadedOlderThan(DateTime threshold) async => 0;

  @override
  Future<void> close() async {}
}

class _NoopShipmentRepository implements ShipmentRepository {
  @override
  Future<void> submitDelivery({
    required String trackingNo,
    required String imageBase64,
    required String imageFileName,
    required String latitude,
    required String longitude,
    String? signatureBase64,
    required String idempotencyKey,
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
    required String idempotencyKey,
  }) async {}

  @override
  Future<ShipmentDetail> fetchShipment(String trackingNo) async {
    return ShipmentDetail(trackingNo: trackingNo, status: 'delivered');
  }
}

class _FakeShipmentUploadOrchestrator extends ShipmentUploadOrchestrator {
  _FakeShipmentUploadOrchestrator({
    QueueSnapshot? queueSnapshot,
    RetryBatchResult? retryResult,
  })  : _queueSnapshot = queueSnapshot ?? QueueSnapshot.empty(),
        _retryResult = retryResult ??
            const RetryBatchResult(
              processed: 0,
              uploaded: 0,
              failed: 0,
              deadLetter: 0,
            ),
        super(
          shipmentRepository: _NoopShipmentRepository(),
          mediaLocalRepository: _FakeMediaLocalRepository(),
        );

  final QueueSnapshot _queueSnapshot;
  final RetryBatchResult _retryResult;
  int retryCallCount = 0;
  int startupMaintenanceCallCount = 0;
  int getQueueSnapshotCallCount = 0;

  @override
  Future<QueueSnapshot> getQueueSnapshot() async {
    getQueueSnapshotCallCount++;
    return _queueSnapshot;
  }

  @override
  Future<void> runStartupMaintenance({
    Duration uploadedRetention = defaultUploadedRetention,
    int maxRetryCount = defaultMaxRetryCount,
  }) async {
    startupMaintenanceCallCount++;
  }

  @override
  Future<RetryBatchResult> retryFailedUploads({
    int maxRetryCount = defaultMaxRetryCount,
    int limit = 20,
  }) async {
    retryCallCount++;
    return _retryResult;
  }
}
