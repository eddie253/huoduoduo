import 'package:meta/meta.dart';

enum ScanMode {
  oneDimensional,
  twoDimensional,
  all,
}

enum ScanSymbology {
  codabar,
  code39,
  code93,
  code128,
  itf,
  qrCode,
  ean13,
  ean8,
  upca,
  upce,
  pdf417,
  dataMatrix,
  aztec,
  unknown,
}

enum ScanSource {
  camera,
  manual,
}

const Set<ScanSymbology> legacyEquivalentSymbologies = <ScanSymbology>{
  ScanSymbology.codabar,
  ScanSymbology.code39,
  ScanSymbology.code93,
  ScanSymbology.code128,
  ScanSymbology.itf,
  ScanSymbology.qrCode,
};

@immutable
class ScanRequest {
  const ScanRequest({
    required this.scanType,
    this.mode = ScanMode.all,
    this.allowedSymbologies = legacyEquivalentSymbologies,
    this.dedupWindowMs = 800,
    this.scanDelayMs = 80,
    this.scanDelaySuccessMs = 200,
    this.minLengthBySymbology = const <ScanSymbology, int>{},
    this.sessionId = '',
  });

  final String scanType;
  final ScanMode mode;
  final Set<ScanSymbology> allowedSymbologies;
  final int dedupWindowMs;
  final int scanDelayMs;
  final int scanDelaySuccessMs;
  final Map<ScanSymbology, int> minLengthBySymbology;
  final String sessionId;
}

@immutable
class ScanResult {
  const ScanResult({
    required this.value,
    required this.symbology,
    required this.timestamp,
    required this.source,
    this.rawMeta = const <String, Object?>{},
  });

  final String value;
  final ScanSymbology symbology;
  final DateTime timestamp;
  final ScanSource source;
  final Map<String, Object?> rawMeta;
}

@immutable
class ScanFailure {
  const ScanFailure({
    required this.code,
    required this.message,
    required this.recoverable,
  });

  final String code;
  final String message;
  final bool recoverable;
}
