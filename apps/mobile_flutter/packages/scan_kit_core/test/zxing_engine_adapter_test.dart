import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:scan_kit_core/src/domain/scan_models.dart';
import 'package:scan_kit_core/src/infrastructure/flutter_zxing/zxing_engine_adapter.dart';

void main() {
  test('maps zxing code into domain result', () {
    const adapter = ZxingEngineAdapter();
    final code = Code(
      text: '  QR-123  ',
      isValid: true,
      format: Format.qrCode,
      duration: 12,
    );

    final mapped = adapter.mapEngineCode(code);

    expect(mapped, isNotNull);
    expect(mapped!.value, 'QR-123');
    expect(mapped.symbology, ScanSymbology.qrCode);
    expect(mapped.rawMeta['format'], Format.qrCode);
  });

  test('returns null for invalid payload', () {
    const adapter = ZxingEngineAdapter();

    expect(adapter.mapEngineCode(Object()), isNull);
    expect(
      adapter.mapEngineCode(
        Code(text: '', isValid: true, format: Format.code128),
      ),
      isNull,
    );
  });
}

