import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile_flutter/features/shipment/data/local/media_local_provider.dart';
import 'package:mobile_flutter/features/shipment/domain/media_queue_models.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('mediaLocalRepositoryProvider returns initialized repository', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final repository = await container.read(mediaLocalRepositoryProvider.future);
    final before = await repository.listByStatus(MediaQueueStatus.pending);

    await repository.enqueue(
      const MediaQueueDraft(
        trackingNo: '907563299214',
        filePath: 'app_media/907563299214/provider_test.jpg',
        fileName: 'provider_test.jpg',
        mediaType: MediaType.deliveryPhoto,
        metadata: <String, String>{
          'source': 'provider-test',
          'latitude': '25.03',
        },
      ),
    );

    final pending = await repository.listByStatus(MediaQueueStatus.pending);
    expect(pending.length, greaterThanOrEqualTo(before.length + 1));
    expect(
      pending.any((item) => item.fileName == 'provider_test.jpg'),
      isTrue,
    );
  });
}
