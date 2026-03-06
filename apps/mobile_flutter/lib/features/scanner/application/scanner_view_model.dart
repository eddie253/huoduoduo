import 'package:flutter/foundation.dart';
import 'package:scan_kit_core/scan_kit_core.dart';

enum ScannerCodeMode {
  all,
  oneDimensional,
  twoDimensional,
}

enum ScannerFrameSize {
  compact,
  medium,
  large,
}

class ScannerViewModel extends ChangeNotifier {
  ScannerViewModel({required String scanType})
      : _scanType = scanType,
        _scanMode = defaultScanMode(scanType),
        _frameSize = ScannerFrameSize.medium;

  final String _scanType;
  ScannerCodeMode _scanMode;
  ScannerFrameSize _frameSize;
  bool _torchOn = false;
  bool _isCompleted = false;

  ScannerCodeMode get scanMode => _scanMode;
  ScannerFrameSize get frameSize => _frameSize;
  bool get torchOn => _torchOn;
  bool get isCompleted => _isCompleted;

  ScanRequest buildRequest() {
    final bool is1D = _scanMode == ScannerCodeMode.oneDimensional;
    return ScanRequest(
      scanType: _scanType,
      mode: _toScanMode(_scanMode),
      allowedSymbologies: allowedSymbologiesFor(_scanType, _scanMode),
      dedupWindowMs: is1D ? 1500 : 800,
      scanDelayMs: is1D ? 80 : 50,
      scanDelaySuccessMs: is1D ? 200 : 100,
      minLengthBySymbology: is1D
          ? const <ScanSymbology, int>{
              ScanSymbology.code128: 10,
              ScanSymbology.code39: 4,
            }
          : const <ScanSymbology, int>{},
      sessionId: '${_scanType}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  String? tryComplete(String value) {
    if (_isCompleted) {
      return null;
    }
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    _isCompleted = true;
    return trimmed;
  }

  void setTorchOn(bool on) {
    _torchOn = on;
    notifyListeners();
  }

  void applySettings(ScannerCodeMode mode, ScannerFrameSize size) {
    _scanMode = mode;
    _frameSize = size;
    _isCompleted = false;
    notifyListeners();
  }

  static ScannerCodeMode defaultScanMode(String scanType) {
    final String normalized = scanType.trim().toLowerCase();
    if (normalized.contains('qr')) {
      return ScannerCodeMode.twoDimensional;
    }
    if (normalized.contains('1d') || normalized.contains('barcode')) {
      return ScannerCodeMode.oneDimensional;
    }
    return ScannerCodeMode.all;
  }

  static Set<ScanSymbology> allowedSymbologiesFor(
    String scanType,
    ScannerCodeMode mode,
  ) {
    final String normalized = scanType.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'default') {
      return legacyEquivalentSymbologies;
    }
    if (mode == ScannerCodeMode.twoDimensional) {
      return <ScanSymbology>{
        ScanSymbology.qrCode,
        ScanSymbology.pdf417,
        ScanSymbology.dataMatrix,
        ScanSymbology.aztec,
      };
    }
    if (mode == ScannerCodeMode.oneDimensional) {
      return <ScanSymbology>{
        ScanSymbology.codabar,
        ScanSymbology.code39,
        ScanSymbology.code93,
        ScanSymbology.code128,
        ScanSymbology.itf,
        ScanSymbology.ean13,
        ScanSymbology.ean8,
        ScanSymbology.upca,
        ScanSymbology.upce,
      };
    }
    return legacyEquivalentSymbologies;
  }
}

ScanMode _toScanMode(ScannerCodeMode mode) {
  switch (mode) {
    case ScannerCodeMode.oneDimensional:
      return ScanMode.oneDimensional;
    case ScannerCodeMode.twoDimensional:
      return ScanMode.twoDimensional;
    case ScannerCodeMode.all:
      return ScanMode.all;
  }
}
