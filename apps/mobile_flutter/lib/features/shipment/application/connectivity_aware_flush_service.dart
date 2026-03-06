import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'shipment_upload_orchestrator.dart';

class ConnectivityAwareFlushService {
  ConnectivityAwareFlushService({
    required ShipmentUploadOrchestrator orchestrator,
    Stream<List<ConnectivityResult>>? connectivityStream,
    bool initiallyOnline = true,
  })  : _orchestrator = orchestrator,
        _stream = connectivityStream ?? Connectivity().onConnectivityChanged,
        _wasOnline = initiallyOnline;

  final ShipmentUploadOrchestrator _orchestrator;
  final Stream<List<ConnectivityResult>> _stream;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _wasOnline;

  void Function()? onRetry;

  void start() {
    _sub?.cancel();
    _sub = _stream.listen(_onConnectivityChanged);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final isOnline = results.any((r) => r != ConnectivityResult.none);
    if (isOnline && !_wasOnline) {
      onRetry?.call();
      await _orchestrator.retryFailedUploads();
    }
    _wasOnline = isOnline;
  }
}
