import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/location/location_service.dart';
import '../../../core/location/location_service_provider.dart';
import '../../../core/network/network_status_provider.dart';
import '../application/queue_snapshot_provider.dart';
import '../application/shipment_confirmation_provider.dart';
import '../application/shipment_upload_orchestrator.dart';
import '../domain/media_queue_models.dart';

class ShipmentPage extends ConsumerStatefulWidget {
  const ShipmentPage({super.key});

  @override
  ConsumerState<ShipmentPage> createState() => _ShipmentPageState();
}

class _ShipmentPageState extends ConsumerState<ShipmentPage> {
  final _trackingNoController = TextEditingController(text: '907563299214');
  final _reasonCodeController = TextEditingController(text: 'EXCEPTION');
  final _reasonMessageController = TextEditingController();

  LocationResult? _locationResult;
  bool _fetchingGps = false;

  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedImagePath;
  String? _selectedImageName;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      final orchestrator =
          await ref.read(shipmentUploadOrchestratorProvider.future);
      await orchestrator.runStartupMaintenance();
      if (mounted) {
        ref.read(queueSnapshotNotifierProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _trackingNoController.dispose();
    _reasonCodeController.dispose();
    _reasonMessageController.dispose();
    super.dispose();
  }

  Future<void> _fetchGps() async {
    if (_fetchingGps) return;
    setState(() => _fetchingGps = true);
    try {
      final svc = ref.read(locationServiceProvider);
      final result = await svc.getCurrentLocation();
      if (mounted) {
        setState(() => _locationResult = result);
      }
    } on LocationPermissionDeniedException catch (e) {
      _showMessage('定位失敗：${e.message}');
    } catch (e) {
      _showMessage('定位失敗：$e');
    } finally {
      if (mounted) setState(() => _fetchingGps = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _selectedImagePath = picked.path;
      _selectedImageName = picked.name;
    });
  }

  Future<void> _uploadDelivery() async {
    await _withBusy(() async {
      final imagePath = _selectedImagePath;
      final imageName = _selectedImageName;
      if (!_validateInputs(imagePath, imageName)) {
        return;
      }

      final orchestrator =
          await ref.read(shipmentUploadOrchestratorProvider.future);
      final loc = _locationResult;
      if (loc == null) {
        _showMessage('請先取得 GPS 定位。');
        return;
      }
      final result = await orchestrator.uploadDelivery(
        trackingNo: _trackingNoController.text.trim(),
        filePath: imagePath!,
        fileName: imageName!,
        latitude: loc.latitudeString,
        longitude: loc.longitudeString,
        metadata: <String, String>{
          'accuracyMeters': loc.accuracyMeters.toStringAsFixed(1),
        },
      );

      _showUploadResult(result);
      ref.read(queueSnapshotNotifierProvider.notifier).refresh();
    });
  }

  Future<void> _uploadException() async {
    await _withBusy(() async {
      final imagePath = _selectedImagePath;
      final imageName = _selectedImageName;
      if (!_validateInputs(imagePath, imageName)) {
        return;
      }

      final orchestrator =
          await ref.read(shipmentUploadOrchestratorProvider.future);
      final loc = _locationResult;
      if (loc == null) {
        _showMessage('請先取得 GPS 定位。');
        return;
      }
      final result = await orchestrator.uploadException(
        trackingNo: _trackingNoController.text.trim(),
        filePath: imagePath!,
        fileName: imageName!,
        reasonCode: _reasonCodeController.text.trim(),
        reasonMessage: _reasonMessageController.text.trim(),
        latitude: loc.latitudeString,
        longitude: loc.longitudeString,
        metadata: <String, String>{
          'accuracyMeters': loc.accuracyMeters.toStringAsFixed(1),
        },
      );

      _showUploadResult(result);
      ref.read(queueSnapshotNotifierProvider.notifier).refresh();
    });
  }

  Future<void> _retryFailed() async {
    await _withBusy(() async {
      final orchestrator =
          await ref.read(shipmentUploadOrchestratorProvider.future);
      final result = await orchestrator.retryFailedUploads();
      _showMessage(
        'Retry processed=${result.processed}, uploaded=${result.uploaded}, failed=${result.failed}, deadLetter=${result.deadLetter}',
      );
      ref.read(queueSnapshotNotifierProvider.notifier).refresh();
    });
  }

  Future<void> _withBusy(Future<void> Function() job) async {
    if (_isBusy) {
      return;
    }

    setState(() {
      _isBusy = true;
    });

    try {
      await job();
    } catch (error) {
      _showMessage('Shipment operation failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  bool _validateInputs(String? imagePath, String? imageName) {
    if (_trackingNoController.text.trim().isEmpty) {
      _showMessage('Tracking number is required.');
      return false;
    }

    if (imagePath == null || imagePath.isEmpty || imageName == null) {
      _showMessage('Please pick an image first.');
      return false;
    }

    if (!File(imagePath).existsSync()) {
      _showMessage('Selected image file does not exist.');
      return false;
    }

    return true;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showUploadResult(ShipmentUploadResult result) {
    final isOnline = ref.read(networkStatusProvider).valueOrNull ?? true;

    final String text;
    final Color bg;

    if (result.queueId == -1) {
      text = '⏳ 該追蹤號正在上傳中，請勿重複提交。';
      bg = Colors.grey.shade700;
    } else if (result.status == MediaQueueStatus.uploaded) {
      text = '✔ 已成功上傳至後端。';
      bg = Colors.green.shade700;
    } else if (result.status == MediaQueueStatus.pending && !isOnline) {
      text = '📶 網路斷線，已離線暂存。恢復連線後會自動重傳。';
      bg = Colors.orange.shade800;
    } else if (result.status == MediaQueueStatus.failed) {
      text = '✖ 上傳失敗 (${result.errorCode ?? 'UNKNOWN'})，請前往錯誤列表重試。';
      bg = Colors.red.shade700;
    } else {
      text = '☑ 已加入上傳佇列。';
      bg = Colors.blue.shade700;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(color: Colors.white)),
        backgroundColor: bg,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipment Upload Queue'),
        actions: <Widget>[
          IconButton(
            onPressed: _isBusy
                ? null
                : () =>
                    ref.read(queueSnapshotNotifierProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _trackingNoController,
              decoration: const InputDecoration(labelText: 'Tracking No'),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (_isBusy || _fetchingGps) ? null : _fetchGps,
                    icon: _fetchingGps
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: const Text('取得 GPS 定位'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _locationResult == null
                        ? '尚未定位'
                        : '${_locationResult!.latitudeString}, ${_locationResult!.longitudeString}\n精度 ${_locationResult!.accuracyMeters.toStringAsFixed(0)} m${_locationResult!.isBelowAccuracyThreshold ? '' : ' ⚠️'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonCodeController,
              decoration: const InputDecoration(labelText: 'Exception Code'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonMessageController,
              decoration: const InputDecoration(labelText: 'Exception Message'),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isBusy ? null : _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pick Image'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isBusy ? null : _retryFailed,
                    icon: const Icon(Icons.replay),
                    label: const Text('Retry Failed'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _selectedImageName == null
                  ? 'No image selected'
                  : 'Selected: $_selectedImageName',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isBusy ? null : _uploadDelivery,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Upload Delivery'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isBusy ? null : _uploadException,
                    icon: const Icon(Icons.warning),
                    label: const Text('Upload Exception'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildConfirmationBanner(),
            const SizedBox(height: 24),
            const Text(
              'Queue Snapshot',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ref.watch(queueSnapshotNotifierProvider).when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Text('Failed to load queue: $e'),
                  data: (queue) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _statusChip(
                          'Pending', queue.pending.length, colors.primary),
                      _statusChip(
                          'Failed', queue.failed.length, colors.tertiary),
                      _statusChip(
                          'Uploaded', queue.uploaded.length, colors.secondary),
                      _statusChip(
                          'Dead Letter', queue.deadLetter.length, colors.error),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationBanner() {
    final confirmations = ref.watch(shipmentConfirmationProvider);
    if (confirmations.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Server Confirmed',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        ...confirmations.entries.map(
          (e) => Card(
            color: colors.secondaryContainer,
            child: ListTile(
              leading: Icon(Icons.check_circle, color: colors.secondary),
              title: Text(e.key),
              subtitle: Text('status=${e.value.status}'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => ref
                    .read(shipmentConfirmationProvider.notifier)
                    .clear(e.key),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Chip(
        avatar: CircleAvatar(
          backgroundColor: color,
          child: Text(
            '$count',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        label: Text(label),
      ),
    );
  }
}
