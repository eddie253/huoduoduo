import 'package:scan_kit_core/scan_kit_core.dart';

class ScanAuditEntry {
  const ScanAuditEntry({
    this.id,
    required this.scannedAt,
    required this.rawValue,
    required this.symbology,
    required this.source,
    this.durationMs,
    this.sessionId = '',
  });

  final int? id;
  final DateTime scannedAt;
  final String rawValue;
  final String symbology;
  final String source;
  final int? durationMs;
  final String sessionId;

  int get length => rawValue.length;

  factory ScanAuditEntry.fromResult(ScanResult result) {
    final durationMs = result.rawMeta['durationMs'];
    return ScanAuditEntry(
      scannedAt: result.timestamp,
      rawValue: result.value,
      symbology: result.symbology.name,
      source: result.source.name,
      durationMs: durationMs is int ? durationMs : null,
      sessionId: '',
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'scanned_at': scannedAt.toIso8601String(),
        'raw_value': rawValue,
        'length': length,
        'symbology': symbology,
        'source': source,
        'duration_ms': durationMs,
        'session_id': sessionId,
      };

  factory ScanAuditEntry.fromMap(Map<String, Object?> map) => ScanAuditEntry(
        id: map['id'] as int?,
        scannedAt: DateTime.parse(map['scanned_at'] as String),
        rawValue: map['raw_value'] as String,
        symbology: map['symbology'] as String,
        source: map['source'] as String,
        durationMs: map['duration_ms'] as int?,
        sessionId: (map['session_id'] as String?) ?? '',
      );
}
