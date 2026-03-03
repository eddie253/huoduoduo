import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_flutter/features/arrival_upload_errors/presentation/arrival_upload_errors_page.dart';
import 'package:mobile_flutter/features/shipment/application/shipment_upload_orchestrator.dart';
import 'package:mobile_flutter/features/shipment/data/local/media_local_provider.dart';
import 'package:mobile_flutter/features/shipment/data/local/media_local_repository.dart';
import 'package:mobile_flutter/features/shipment/data/shipment_repository.dart';
import 'package:mobile_flutter/features/shipment/domain/media_queue_models.dart';

void main() {
  testWidgets(
      'LEGACY_MENU_ARRIVAL_UPLOAD_ERROR_ENTRY list includes failed/dead_letter',
      (tester) async {
    final fakeRepo = _FakeMediaLocalRepository()
      ..seed(
        failed: <MediaQueueItem>[
          _item(1, MediaQueueStatus.failed),
        ],
        deadLetter: <MediaQueueItem>[
          _item(2, MediaQueueStatus.deadLetter),
        ],
      );

    final orchestrator = _FakeOrchestrator();
    final container = ProviderContainer(
      overrides: <Override>[
        mediaLocalRepositoryProvider.overrideWith((ref) async => fakeRepo),
        shipmentUploadOrchestratorProvider.overrideWith(
          (ref) async => orchestrator,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ArrivalUploadErrorsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ArrivalUploadErrorsPage.listKey), findsOneWidget);
    expect(find.textContaining('status=failed'), findsOneWidget);
    expect(find.textContaining('status=dead_letter'), findsOneWidget);
  });

  testWidgets('UPLOAD_ERROR_SINGLE_RETRY_SUCCESS retries selected row',
      (tester) async {
    final fakeRepo = _FakeMediaLocalRepository()
      ..seed(
        failed: <MediaQueueItem>[_item(10, MediaQueueStatus.failed)],
      );
    final orchestrator = _FakeOrchestrator();

    final container = ProviderContainer(
      overrides: <Override>[
        mediaLocalRepositoryProvider.overrideWith((ref) async => fakeRepo),
        shipmentUploadOrchestratorProvider.overrideWith(
          (ref) async => orchestrator,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ArrivalUploadErrorsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('arrivalUploadErrors.retry.10')));
    await tester.pumpAndSettle();

    expect(orchestrator.retriedIds, <int>[10]);
    expect(find.textContaining('Retry #10: uploaded'), findsOneWidget);
  });

  testWidgets('UPLOAD_ERROR_SINGLE_RETRY_FAILURE shows error message',
      (tester) async {
    final fakeRepo = _FakeMediaLocalRepository()
      ..seed(
        failed: <MediaQueueItem>[_item(11, MediaQueueStatus.failed)],
      );
    final orchestrator = _FakeOrchestrator()..failIds = <int>{11};

    final container = ProviderContainer(
      overrides: <Override>[
        mediaLocalRepositoryProvider.overrideWith((ref) async => fakeRepo),
        shipmentUploadOrchestratorProvider.overrideWith(
          (ref) async => orchestrator,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ArrivalUploadErrorsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('arrivalUploadErrors.retry.11')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Retry failed:'), findsOneWidget);
  });
}

MediaQueueItem _item(int id, MediaQueueStatus status) {
  final now = DateTime.utc(2026, 3, 3, 10, 0, id);
  return MediaQueueItem(
    id: id,
    trackingNo: 'TN$id',
    filePath: '/tmp/$id.jpg',
    fileName: '$id.jpg',
    mediaType: MediaType.deliveryPhoto,
    status: status,
    retryCount: 1,
    lastErrorCode: 'LEGACY_TIMEOUT',
    createdAt: now,
    updatedAt: now,
    metadata: const <String, String>{'latitude': '25', 'longitude': '121'},
  );
}

class _FakeOrchestrator extends ShipmentUploadOrchestrator {
  _FakeOrchestrator()
      : super(
          shipmentRepository: _NoopShipmentRepository(),
          mediaLocalRepository: _NoopMediaLocalRepository(),
        );

  final List<int> retriedIds = <int>[];
  Set<int> failIds = <int>{};

  @override
  Future<ShipmentUploadResult> retryFailedUploadById(
    int queueId, {
    int maxRetryCount = defaultMaxRetryCount,
  }) async {
    retriedIds.add(queueId);
    if (failIds.contains(queueId)) {
      throw Exception('forced retry failure');
    }
    return ShipmentUploadResult(
      queueId: queueId,
      status: MediaQueueStatus.uploaded,
    );
  }
}

class _FakeMediaLocalRepository implements MediaLocalRepository {
  final Map<MediaQueueStatus, List<MediaQueueItem>> _byStatus =
      <MediaQueueStatus, List<MediaQueueItem>>{};

  void seed({
    List<MediaQueueItem> failed = const <MediaQueueItem>[],
    List<MediaQueueItem> deadLetter = const <MediaQueueItem>[],
  }) {
    _byStatus[MediaQueueStatus.failed] = failed;
    _byStatus[MediaQueueStatus.deadLetter] = deadLetter;
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> close() async {}

  @override
  Future<int> cleanupUploadedOlderThan(DateTime threshold) async => 0;

  @override
  Future<MediaQueueItem> enqueue(MediaQueueDraft draft) async {
    throw UnimplementedError();
  }

  @override
  Future<MediaQueueItem?> getById(int id) async => null;

  @override
  Future<List<MediaQueueItem>> listByStatus(
    MediaQueueStatus status, {
    int limit = 50,
  }) async {
    return List<MediaQueueItem>.from(
        _byStatus[status] ?? const <MediaQueueItem>[]);
  }

  @override
  Future<void> markDeadLetter(int id, {String? errorCode}) async {}

  @override
  Future<void> markFailed(int id, {String? errorCode}) async {}

  @override
  Future<void> markUploaded(int id) async {}
}

class _NoopShipmentRepository implements ShipmentRepository {
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

class _NoopMediaLocalRepository implements MediaLocalRepository {
  @override
  Future<void> close() async {}

  @override
  Future<int> cleanupUploadedOlderThan(DateTime threshold) async => 0;

  @override
  Future<MediaQueueItem> enqueue(MediaQueueDraft draft) async {
    throw UnimplementedError();
  }

  @override
  Future<MediaQueueItem?> getById(int id) async => null;

  @override
  Future<void> init() async {}

  @override
  Future<List<MediaQueueItem>> listByStatus(
    MediaQueueStatus status, {
    int limit = 50,
  }) async =>
      <MediaQueueItem>[];

  @override
  Future<void> markDeadLetter(int id, {String? errorCode}) async {}

  @override
  Future<void> markFailed(int id, {String? errorCode}) async {}

  @override
  Future<void> markUploaded(int id) async {}
}
