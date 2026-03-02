import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_flutter/features/shipment/domain/media_queue_models.dart';

void main() {
  test('MediaType.fromValue resolves known and unknown values', () {
    expect(MediaType.fromValue('delivery_photo'), MediaType.deliveryPhoto);
    expect(MediaType.fromValue('exception_photo'), MediaType.exceptionPhoto);
    expect(MediaType.fromValue('signature'), MediaType.signature);
    expect(MediaType.fromValue('unknown'), MediaType.deliveryPhoto);
  });

  test('MediaQueueStatus.fromValue resolves known and unknown values', () {
    expect(MediaQueueStatus.fromValue('pending'), MediaQueueStatus.pending);
    expect(MediaQueueStatus.fromValue('uploaded'), MediaQueueStatus.uploaded);
    expect(MediaQueueStatus.fromValue('failed'), MediaQueueStatus.failed);
    expect(
      MediaQueueStatus.fromValue('dead_letter'),
      MediaQueueStatus.deadLetter,
    );
    expect(MediaQueueStatus.fromValue('not-found'), MediaQueueStatus.pending);
  });

  test('MediaQueueItem.copyWith overrides selected fields', () {
    final now = DateTime.utc(2026, 3, 2, 1, 0, 0);
    final original = MediaQueueItem(
      id: 1,
      trackingNo: '907563299214',
      filePath: '/tmp/a.jpg',
      fileName: 'a.jpg',
      mediaType: MediaType.deliveryPhoto,
      status: MediaQueueStatus.pending,
      retryCount: 0,
      lastErrorCode: null,
      createdAt: now,
      updatedAt: now,
      metadata: const <String, String>{'source': 'unit-test'},
    );

    final copied = original.copyWith(
      status: MediaQueueStatus.failed,
      retryCount: 1,
      lastErrorCode: 'LEGACY_TIMEOUT',
    );

    expect(copied.id, original.id);
    expect(copied.status, MediaQueueStatus.failed);
    expect(copied.retryCount, 1);
    expect(copied.lastErrorCode, 'LEGACY_TIMEOUT');
    expect(copied.metadata['source'], 'unit-test');
  });
}
