import 'dart:async';

import '../domain/scan_models.dart';
import '../infrastructure/flutter_zxing/dedup_filter.dart';
import '../infrastructure/flutter_zxing/zxing_engine_adapter.dart';
import 'scan_event.dart';

typedef TorchToggleHandler = Future<bool> Function();
typedef Clock = DateTime Function();

class ScanSessionController {
  ScanSessionController({
    ScanEngineAdapter? engineAdapter,
    Clock? clock,
  })  : _engineAdapter = engineAdapter ?? const ZxingEngineAdapter(),
        _clock = clock ?? DateTime.now;

  final ScanEngineAdapter _engineAdapter;
  final Clock _clock;
  final StreamController<ScanEvent> _events =
      StreamController<ScanEvent>.broadcast();

  ScanRequest? _activeRequest;
  DedupFilter _dedupFilter = DedupFilter(windowMs: 800);
  TorchToggleHandler? _torchToggleHandler;
  bool _running = false;

  Stream<ScanEvent> get events => _events.stream;
  bool get isRunning => _running;
  ScanRequest? get activeRequest => _activeRequest;

  void bindTorchToggleHandler(TorchToggleHandler handler) {
    _torchToggleHandler = handler;
  }

  void start(ScanRequest request) {
    _activeRequest = request;
    _dedupFilter = DedupFilter(windowMs: request.dedupWindowMs);
    _running = true;
    _emit(ScanStartedEvent(request: request, timestamp: _clock()));
  }

  void stop() {
    if (!_running) {
      return;
    }
    _running = false;
    _emit(ScanStoppedEvent(timestamp: _clock()));
  }

  Future<bool> toggleTorch() async {
    final handler = _torchToggleHandler;
    if (handler == null) {
      return false;
    }
    return handler();
  }

  bool submitManualInput(String value) {
    if (!_running) {
      return false;
    }
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    return _tryEmitResult(
      value: trimmed,
      symbology: ScanSymbology.unknown,
      source: ScanSource.manual,
      rawMeta: const <String, Object?>{},
    );
  }

  bool consumeEngineCode(Object engineCode) {
    if (!_running) {
      return false;
    }
    if (engineCode is String) {
      final String value = engineCode.trim();
      if (value.isEmpty) {
        return false;
      }
      return _tryEmitResult(
        value: value,
        symbology: ScanSymbology.code128,
        source: ScanSource.camera,
        rawMeta: const <String, Object?>{'adapter': 'passthrough'},
      );
    }

    final MappedScanData? mapped = _engineAdapter.mapEngineCode(engineCode);
    if (mapped == null) {
      _emit(
        ScanFailureEvent(
          failure: const ScanFailure(
            code: 'engine_invalid',
            message: 'Scan engine returned invalid payload.',
            recoverable: true,
          ),
          timestamp: _clock(),
        ),
      );
      return false;
    }

    return _tryEmitResult(
      value: mapped.value,
      symbology: mapped.symbology,
      source: ScanSource.camera,
      rawMeta: mapped.rawMeta,
    );
  }

  bool _tryEmitResult({
    required String value,
    required ScanSymbology symbology,
    required ScanSource source,
    required Map<String, Object?> rawMeta,
  }) {
    final request = _activeRequest;
    if (request == null) {
      return false;
    }
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    if (!_isAllowedByMode(symbology, request.mode)) {
      return false;
    }
    if (request.allowedSymbologies.isNotEmpty &&
        !request.allowedSymbologies.contains(symbology)) {
      return false;
    }

    final DateTime now = _clock();
    if (!_dedupFilter.shouldEmit(trimmed, now)) {
      return false;
    }

    _emit(
      ScanSuccessEvent(
        result: ScanResult(
          value: trimmed,
          symbology: symbology,
          timestamp: now,
          source: source,
          rawMeta: rawMeta,
        ),
        timestamp: now,
      ),
    );
    return true;
  }

  bool _isAllowedByMode(ScanSymbology symbology, ScanMode mode) {
    if (mode == ScanMode.all) {
      return true;
    }
    const Set<ScanSymbology> twoDimensional = <ScanSymbology>{
      ScanSymbology.qrCode,
      ScanSymbology.pdf417,
      ScanSymbology.dataMatrix,
      ScanSymbology.aztec,
    };
    if (symbology == ScanSymbology.unknown) {
      return true;
    }
    if (mode == ScanMode.twoDimensional) {
      return twoDimensional.contains(symbology);
    }
    return !twoDimensional.contains(symbology);
  }

  void _emit(ScanEvent event) {
    if (_events.isClosed) {
      return;
    }
    _events.add(event);
  }

  void dispose() {
    _running = false;
    _activeRequest = null;
    _events.close();
  }
}
