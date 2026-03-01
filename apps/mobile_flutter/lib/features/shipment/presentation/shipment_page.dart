import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../application/shipment_upload_orchestrator.dart';
import '../data/local/media_local_provider.dart';
import '../domain/media_queue_models.dart';

class ShipmentPage extends ConsumerStatefulWidget {
  const ShipmentPage({super.key});

  @override
  ConsumerState<ShipmentPage> createState() => _ShipmentPageState();
}

class _ShipmentPageState extends ConsumerState<ShipmentPage> {
  final _trackingNoController = TextEditingController(text: '907563299214');
  final _latitudeController = TextEditingController(text: '25.0330');
  final _longitudeController = TextEditingController(text: '121.5654');
  final _reasonCodeController = TextEditingController(text: 'EXCEPTION');
  final _reasonMessageController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedImagePath;
  String? _selectedImageName;
  bool _isBusy = false;
  late Future<_QueueSnapshot> _queueFuture;

  @override
  void initState() {
    super.initState();
    _queueFuture = _loadQueueSnapshot();
    Future<void>.microtask(() async {
      final orchestrator =
          await ref.read(shipmentUploadOrchestratorProvider.future);
      await orchestrator.runStartupMaintenance();
      if (mounted) {
        _refreshQueue();
      }
    });
  }

  @override
  void dispose() {
    _trackingNoController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _reasonCodeController.dispose();
    _reasonMessageController.dispose();
    super.dispose();
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
      final result = await orchestrator.uploadDelivery(
        trackingNo: _trackingNoController.text.trim(),
        filePath: imagePath!,
        fileName: imageName!,
        latitude: _latitudeController.text.trim(),
        longitude: _longitudeController.text.trim(),
      );

      _showMessage(
        'Delivery upload result: ${result.status.value} (queueId=${result.queueId})',
      );
      _refreshQueue();
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
      final result = await orchestrator.uploadException(
        trackingNo: _trackingNoController.text.trim(),
        filePath: imagePath!,
        fileName: imageName!,
        reasonCode: _reasonCodeController.text.trim(),
        reasonMessage: _reasonMessageController.text.trim(),
        latitude: _latitudeController.text.trim(),
        longitude: _longitudeController.text.trim(),
      );

      _showMessage(
        'Exception upload result: ${result.status.value} (queueId=${result.queueId})',
      );
      _refreshQueue();
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
      _refreshQueue();
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

  Future<_QueueSnapshot> _loadQueueSnapshot() async {
    final repository = await ref.read(mediaLocalRepositoryProvider.future);
    final pending = await repository.listByStatus(MediaQueueStatus.pending);
    final failed = await repository.listByStatus(MediaQueueStatus.failed);
    final uploaded = await repository.listByStatus(MediaQueueStatus.uploaded);
    final deadLetter =
        await repository.listByStatus(MediaQueueStatus.deadLetter);

    return _QueueSnapshot(
      pending: pending,
      failed: failed,
      uploaded: uploaded,
      deadLetter: deadLetter,
    );
  }

  void _refreshQueue() {
    setState(() {
      _queueFuture = _loadQueueSnapshot();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipment Upload Queue'),
        actions: <Widget>[
          IconButton(
            onPressed: _isBusy ? null : _refreshQueue,
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
                  child: TextField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(labelText: 'Latitude'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(labelText: 'Longitude'),
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
            const Text(
              'Queue Snapshot',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            FutureBuilder<_QueueSnapshot>(
              future: _queueFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Text('Failed to load queue: ${snapshot.error}');
                }

                final queue = snapshot.data ?? _QueueSnapshot.empty();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _statusChip('Pending', queue.pending.length, Colors.blue),
                    _statusChip('Failed', queue.failed.length, Colors.orange),
                    _statusChip('Uploaded', queue.uploaded.length, Colors.green),
                    _statusChip('Dead Letter', queue.deadLetter.length, Colors.red),
                  ],
                );
              },
            ),
          ],
        ),
      ),
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

class _QueueSnapshot {
  const _QueueSnapshot({
    required this.pending,
    required this.failed,
    required this.uploaded,
    required this.deadLetter,
  });

  final List<MediaQueueItem> pending;
  final List<MediaQueueItem> failed;
  final List<MediaQueueItem> uploaded;
  final List<MediaQueueItem> deadLetter;

  factory _QueueSnapshot.empty() {
    return const _QueueSnapshot(
      pending: <MediaQueueItem>[],
      failed: <MediaQueueItem>[],
      uploaded: <MediaQueueItem>[],
      deadLetter: <MediaQueueItem>[],
    );
  }
}
