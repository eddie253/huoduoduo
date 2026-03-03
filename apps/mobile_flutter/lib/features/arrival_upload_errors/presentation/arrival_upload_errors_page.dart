import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shipment/application/shipment_upload_orchestrator.dart';
import '../../shipment/data/local/media_local_provider.dart';
import '../../shipment/domain/media_queue_models.dart';

class ArrivalUploadErrorsPage extends ConsumerStatefulWidget {
  const ArrivalUploadErrorsPage({super.key});

  static const Key listKey = Key('arrivalUploadErrors.list');

  @override
  ConsumerState<ArrivalUploadErrorsPage> createState() =>
      _ArrivalUploadErrorsPageState();
}

class _ArrivalUploadErrorsPageState
    extends ConsumerState<ArrivalUploadErrorsPage> {
  late Future<List<MediaQueueItem>> _itemsFuture;
  final Set<int> _retryingIds = <int>{};

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadItems();
  }

  Future<List<MediaQueueItem>> _loadItems() async {
    final repository = await ref.read(mediaLocalRepositoryProvider.future);
    final failed = await repository.listByStatus(MediaQueueStatus.failed);
    final deadLetter =
        await repository.listByStatus(MediaQueueStatus.deadLetter);

    final all = <MediaQueueItem>[...failed, ...deadLetter];
    all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all;
  }

  void _refresh() {
    setState(() {
      _itemsFuture = _loadItems();
    });
  }

  Future<void> _retrySingle(MediaQueueItem item) async {
    if (_retryingIds.contains(item.id)) {
      return;
    }

    setState(() {
      _retryingIds.add(item.id);
    });

    try {
      final orchestrator =
          await ref.read(shipmentUploadOrchestratorProvider.future);
      final result = await orchestrator.retryFailedUploadById(item.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Retry #${item.id}: ${result.status.value}${result.errorCode == null ? '' : ' (${result.errorCode})'}',
          ),
        ),
      );
      _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Retry failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _retryingIds.remove(item.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('簽收上傳錯誤'),
        actions: <Widget>[
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<MediaQueueItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Load failed: ${snapshot.error}'));
          }

          final items = snapshot.data ?? const <MediaQueueItem>[];
          if (items.isEmpty) {
            return const Center(child: Text('No upload errors.'));
          }

          return ListView.separated(
            key: ArrivalUploadErrorsPage.listKey,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final item = items[index];
              final retrying = _retryingIds.contains(item.id);
              return Card(
                child: ListTile(
                  title: Text(item.trackingNo),
                  subtitle: Text(
                    'status=${item.status.value} retry=${item.retryCount} error=${item.lastErrorCode ?? 'N/A'}\nupdated=${item.updatedAt.toLocal()}',
                  ),
                  isThreeLine: true,
                  trailing: FilledButton.tonal(
                    key: Key('arrivalUploadErrors.retry.${item.id}'),
                    onPressed: retrying ? null : () => _retrySingle(item),
                    child: Text(retrying ? 'Retrying...' : 'Retry'),
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: items.length,
          );
        },
      ),
    );
  }
}
