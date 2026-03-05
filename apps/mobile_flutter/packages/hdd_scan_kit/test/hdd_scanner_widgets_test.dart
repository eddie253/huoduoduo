import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hdd_scan_kit/hdd_scan_kit.dart';
import 'package:hdd_scan_kit/src/infrastructure/flutter_zxing/zxing_engine_adapter.dart';

void main() {
  testWidgets('toolbar triggers all actions', (WidgetTester tester) async {
    int torchTap = 0;
    int keypadTap = 0;
    int settingTap = 0;
    const Key flashKey = Key('flash');
    const Key keypadKey = Key('keypad');
    const Key settingKey = Key('setting');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HddScannerToolbar(
            torchOn: false,
            onToggleTorch: () => torchTap++,
            onManualInput: () => keypadTap++,
            onOpenSettings: () => settingTap++,
            flashButtonKey: flashKey,
            keypadButtonKey: keypadKey,
            settingButtonKey: settingKey,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(flashKey));
    await tester.tap(find.byKey(keypadKey));
    await tester.tap(find.byKey(settingKey));

    expect(torchTap, 1);
    expect(keypadTap, 1);
    expect(settingTap, 1);
  });

  testWidgets('frame window switches between 1D and 2D',
      (WidgetTester tester) async {
    const Key oneDimWindowKey = Key('one_dim_window');
    const Key twoDimWindowKey = Key('two_dim_window');

    final controller = ScanSessionController(
      engineAdapter: _PassthroughEngineAdapter(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HddScannerView(
            controller: controller,
            request: const ScanRequest(
              scanType: 'barcode',
              mode: ScanMode.oneDimensional,
              allowedSymbologies: <ScanSymbology>{ScanSymbology.code128},
            ),
            windowKey: oneDimWindowKey,
            engineViewBuilder: (_, __) => const SizedBox.expand(),
          ),
        ),
      ),
    );

    final Size oneDimSize = tester.getSize(find.byKey(oneDimWindowKey));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HddScannerView(
            controller: controller,
            request: const ScanRequest(
              scanType: 'qr',
              mode: ScanMode.twoDimensional,
              allowedSymbologies: <ScanSymbology>{ScanSymbology.qrCode},
            ),
            windowKey: twoDimWindowKey,
            engineViewBuilder: (_, __) => const SizedBox.expand(),
          ),
        ),
      ),
    );

    final Size twoDimSize = tester.getSize(find.byKey(twoDimWindowKey));
    expect(oneDimSize.width, twoDimSize.width);
    expect(oneDimSize.height, lessThan(twoDimSize.height));
  });

  testWidgets('scan success completes pop only once',
      (WidgetTester tester) async {
    final observer = _CountingNavigatorObserver();
    final controller = ScanSessionController(
      engineAdapter: _PassthroughEngineAdapter(),
    );

    late Future<Object?> routeResult;
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: <NavigatorObserver>[observer],
        home: Builder(
          builder: (BuildContext context) {
            return FilledButton(
              onPressed: () {
                routeResult = Navigator.of(context).push<Object?>(
                  MaterialPageRoute<Object?>(
                    builder: (_) =>
                        _ScannerCompletionHarness(controller: controller),
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Emit Twice'));
    await tester.pumpAndSettle();

    expect(await routeResult, 'CODE-001');
    expect(observer.popCount, 1);
  });
}

class _ScannerCompletionHarness extends StatefulWidget {
  const _ScannerCompletionHarness({required this.controller});

  final ScanSessionController controller;

  @override
  State<_ScannerCompletionHarness> createState() =>
      _ScannerCompletionHarnessState();
}

class _ScannerCompletionHarnessState extends State<_ScannerCompletionHarness> {
  late final StreamSubscription<ScanEvent> _subscription;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    widget.controller.start(
      const ScanRequest(
        scanType: 'default',
        mode: ScanMode.all,
        allowedSymbologies: legacyEquivalentSymbologies,
      ),
    );
    _subscription = widget.controller.events.listen((ScanEvent event) {
      if (_completed || event is! ScanSuccessEvent) {
        return;
      }
      _completed = true;
      Navigator.of(context).pop(event.result.value);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HddScannerView(
        controller: widget.controller,
        request: const ScanRequest(
          scanType: 'default',
          mode: ScanMode.all,
          allowedSymbologies: legacyEquivalentSymbologies,
        ),
        engineViewBuilder: (_, ValueChanged<Object> emit) {
          return Center(
            child: FilledButton(
              onPressed: () {
                emit('CODE-001');
                emit('CODE-002');
              },
              child: const Text('Emit Twice'),
            ),
          );
        },
      ),
    );
  }
}

class _PassthroughEngineAdapter implements ScanEngineAdapter {
  @override
  MappedScanData? mapEngineCode(Object engineCode) {
    if (engineCode is! String || engineCode.trim().isEmpty) {
      return null;
    }
    return MappedScanData(
      value: engineCode.trim(),
      symbology: ScanSymbology.code128,
      rawMeta: const <String, Object?>{},
    );
  }
}

class _CountingNavigatorObserver extends NavigatorObserver {
  int popCount = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount++;
    super.didPop(route, previousRoute);
  }
}
