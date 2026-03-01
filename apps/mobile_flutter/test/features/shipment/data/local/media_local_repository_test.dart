import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile_flutter/features/shipment/data/local/media_local_repository.dart';
import 'package:mobile_flutter/features/shipment/data/local/media_local_schema.dart';
import 'package:mobile_flutter/features/shipment/domain/media_queue_models.dart';

void main() {
  sqfliteFfiInit();

  late Directory tempDir;
  late MediaLocalDatabase mediaLocalDatabase;
  late SqfliteMediaLocalRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('media-local-test-');
    mediaLocalDatabase = MediaLocalDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: p.join(tempDir.path, 'media_local_test.db'),
    );
    repository = SqfliteMediaLocalRepository(mediaLocalDatabase);
    await repository.init();
  });

  tearDown(() async {
    await repository.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('creates table and index during initialization', () async {
    final db = await mediaLocalDatabase.open();
    final tableResult = await db.rawQuery(
      '''
SELECT name
FROM sqlite_master
WHERE type='table' AND name=?
''',
      <Object?>[MediaLocalSchema.tableName],
    );
    final indexResult = await db.rawQuery(
      '''
SELECT name
FROM sqlite_master
WHERE type='index' AND name='idx_media_upload_queue_status_created'
''',
    );

    expect(tableResult, isNotEmpty);
    expect(indexResult, isNotEmpty);
  });

  test('enqueue and update status transitions', () async {
    final item = await repository.enqueue(
      const MediaQueueDraft(
        trackingNo: '907563299214',
        filePath: 'app_media/907563299214/signature_1.jpg',
        fileName: 'signature_1.jpg',
        mediaType: MediaType.signature,
        metadata: <String, String>{
          'source': 'signature_pad',
          'platform': 'android',
        },
      ),
    );

    final pendingItems =
        await repository.listByStatus(MediaQueueStatus.pending);
    expect(pendingItems.length, 1);
    expect(pendingItems.first.id, item.id);

    await repository.markFailed(item.id, errorCode: 'LEGACY_TIMEOUT');
    final failedItems = await repository.listByStatus(MediaQueueStatus.failed);
    expect(failedItems.length, 1);
    expect(failedItems.first.retryCount, 1);
    expect(failedItems.first.lastErrorCode, 'LEGACY_TIMEOUT');

    await repository.markUploaded(item.id);
    final uploadedItems =
        await repository.listByStatus(MediaQueueStatus.uploaded);
    expect(uploadedItems.length, 1);
    expect(uploadedItems.first.lastErrorCode, isNull);
  });

  test('rejects sensitive metadata keys', () async {
    await expectLater(
      repository.enqueue(
        const MediaQueueDraft(
          trackingNo: '907563299214',
          filePath: 'app_media/907563299214/delivery_1.jpg',
          fileName: 'delivery_1.jpg',
          mediaType: MediaType.deliveryPhoto,
          metadata: <String, String>{
            'access_token': 'do-not-store-here',
          },
        ),
      ),
      throwsA(
        isA<ArgumentError>().having(
          (ArgumentError error) => error.message,
          'message',
          contains('FORBIDDEN_LOCAL_FIELD'),
        ),
      ),
    );
  });
}
