import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shipment_upload_orchestrator.dart';

class QueueSnapshotNotifier extends AsyncNotifier<QueueSnapshot> {
  @override
  Future<QueueSnapshot> build() async {
    final orchestrator =
        await ref.watch(shipmentUploadOrchestratorProvider.future);
    return orchestrator.getQueueSnapshot();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final queueSnapshotNotifierProvider =
    AsyncNotifierProvider<QueueSnapshotNotifier, QueueSnapshot>(
  QueueSnapshotNotifier.new,
);
