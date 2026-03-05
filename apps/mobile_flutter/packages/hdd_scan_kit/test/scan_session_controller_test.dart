import 'package:flutter_test/flutter_test.dart';
import 'package:hdd_scan_kit/src/application/scan_event.dart';
import 'package:hdd_scan_kit/src/application/scan_session_controller.dart';
import 'package:hdd_scan_kit/src/domain/scan_models.dart';
import 'package:hdd_scan_kit/src/infrastructure/flutter_zxing/zxing_engine_adapter.dart';

void main() {
  test('filters by mode and allowed symbology', () async {
    final controller = ScanSessionController(
      engineAdapter: const _FakeEngineAdapter(
        MappedScanData(
          value: 'QR-001',
          symbology: ScanSymbology.qrCode,
          rawMeta: <String, Object?>{},
        ),
      ),
    );
    final List<ScanEvent> events = <ScanEvent>[];
    final sub = controller.events.listen(events.add);

    controller.start(
      const ScanRequest(
        scanType: 'default',
        mode: ScanMode.oneDimensional,
        allowedSymbologies: <ScanSymbology>{ScanSymbology.code128},
      ),
    );
    controller.consumeEngineCode(Object());
    await Future<void>.delayed(Duration.zero);

    expect(events.whereType<ScanSuccessEvent>(), isEmpty);
    await sub.cancel();
    controller.dispose();
  });

  test('dedup window suppresses repeated value inside 800ms', () async {
    DateTime clock = DateTime(2026, 1, 1, 0, 0, 0);
    final controller = ScanSessionController(
      clock: () => clock,
      engineAdapter: const _FakeEngineAdapter(
        MappedScanData(
          value: 'DUP-001',
          symbology: ScanSymbology.code128,
          rawMeta: <String, Object?>{},
        ),
      ),
    );
    final List<ScanSuccessEvent> events = <ScanSuccessEvent>[];
    final sub = controller.events.listen((ScanEvent event) {
      if (event is ScanSuccessEvent) {
        events.add(event);
      }
    });

    controller.start(
      const ScanRequest(
        scanType: 'default',
        allowedSymbologies: <ScanSymbology>{ScanSymbology.code128},
        dedupWindowMs: 800,
      ),
    );

    controller.consumeEngineCode(Object());
    clock = clock.add(const Duration(milliseconds: 300));
    controller.consumeEngineCode(Object());
    clock = clock.add(const Duration(milliseconds: 900));
    controller.consumeEngineCode(Object());
    await Future<void>.delayed(Duration.zero);

    expect(events.length, 2);
    await sub.cancel();
    controller.dispose();
  });

  test('manual input ignores blank and emits for valid input', () async {
    final controller = ScanSessionController();
    final List<ScanSuccessEvent> events = <ScanSuccessEvent>[];
    final sub = controller.events.listen((ScanEvent event) {
      if (event is ScanSuccessEvent) {
        events.add(event);
      }
    });

    controller.start(
      const ScanRequest(
        scanType: 'manual',
        mode: ScanMode.all,
        allowedSymbologies: <ScanSymbology>{ScanSymbology.unknown},
      ),
    );

    expect(controller.submitManualInput('   '), isFalse);
    expect(controller.submitManualInput('  ABC-001  '), isTrue);
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(1));
    expect(events.single.result.value, 'ABC-001');
    expect(events.single.result.source, ScanSource.manual);

    await sub.cancel();
    controller.dispose();
  });
}

class _FakeEngineAdapter implements ScanEngineAdapter {
  const _FakeEngineAdapter(this.data);

  final MappedScanData? data;

  @override
  MappedScanData? mapEngineCode(Object engineCode) => data;
}
