import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:meta/meta.dart';

import '../../domain/scan_models.dart';
import 'symbology_mapper.dart';

@immutable
class MappedScanData {
  const MappedScanData({
    required this.value,
    required this.symbology,
    required this.rawMeta,
  });

  final String value;
  final ScanSymbology symbology;
  final Map<String, Object?> rawMeta;
}

abstract interface class ScanEngineAdapter {
  MappedScanData? mapEngineCode(Object engineCode);
}

class ZxingEngineAdapter implements ScanEngineAdapter {
  const ZxingEngineAdapter({
    this.mapper = const SymbologyMapper(),
  });

  final SymbologyMapper mapper;

  @override
  MappedScanData? mapEngineCode(Object engineCode) {
    if (engineCode is! Code) {
      return null;
    }
    final String value = (engineCode.text ?? '').trim();
    if (!engineCode.isValid || value.isEmpty) {
      return null;
    }

    final int? format = engineCode.format;
    final ScanSymbology symbology = mapper.fromZxingFormat(format);
    return MappedScanData(
      value: value,
      symbology: symbology,
      rawMeta: <String, Object?>{
        'format': format,
        'durationMs': engineCode.duration,
        'isInverted': engineCode.isInverted,
        'isMirrored': engineCode.isMirrored,
      },
    );
  }
}
