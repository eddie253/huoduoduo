import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:mobile_flutter/features/scanner/presentation/scanner_page.dart';

void main() {
  testWidgets('shows scan type in app bar title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ScannerPage(
          scanType: 'qr',
          scannerViewBuilder: _buildNoopScanner,
        ),
      ),
    );

    expect(find.text(scannerTitleFor('qr')), findsOneWidget);
  });

  testWidgets('close button pops scanner page', (WidgetTester tester) async {
    final observer = _CountingNavigatorObserver();
    await _openScannerPage(
      tester,
      observer: observer,
      pageBuilder: () =>
          const ScannerPage(scannerViewBuilder: _buildNoopScanner),
    );

    await tester.tap(find.byKey(scannerCloseButtonKey));
    await tester.pumpAndSettle();

    expect(observer.popCount, 1);
  });

  testWidgets('hint text is visible and unchanged',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ScannerPage(
          scanType: 'qr',
          scannerViewBuilder: _buildNoopScanner,
        ),
      ),
    );

    expect(find.text(scannerHintText), findsOneWidget);
    expect(find.byKey(scannerToolRowKey), findsOneWidget);
    expect(find.byKey(scannerFlashButtonKey), findsOneWidget);
    expect(find.byKey(scannerKeypadButtonKey), findsOneWidget);
    expect(find.byKey(scannerSettingButtonKey), findsOneWidget);
  });

  testWidgets('ignores empty scan value and stays on page',
      (WidgetTester tester) async {
    await _openScannerPage(
      tester,
      pageBuilder: () => ScannerPage(
        scannerViewBuilder: (
          MobileScannerController controller,
          ValueChanged<String> onDetectedValue,
        ) {
          return Center(
            child: FilledButton(
              onPressed: () => onDetectedValue('   '),
              child: const Text('Emit Empty'),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('Emit Empty'));
    await tester.pumpAndSettle();

    expect(find.byType(ScannerPage), findsOneWidget);
  });

  testWidgets('completes scan and pops only once', (WidgetTester tester) async {
    final observer = _CountingNavigatorObserver();
    final resultFuture = await _openScannerPage(
      tester,
      observer: observer,
      pageBuilder: () => ScannerPage(
        scannerViewBuilder: (
          MobileScannerController controller,
          ValueChanged<String> onDetectedValue,
        ) {
          return Center(
            child: FilledButton(
              onPressed: () {
                onDetectedValue('CODE-123');
                onDetectedValue('CODE-456');
              },
              child: const Text('Emit Twice'),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('Emit Twice'));
    await tester.pumpAndSettle();

    final result = await resultFuture;
    expect(result, 'CODE-123');
    expect(observer.popCount, 1);
  });

  test('barcode format filter supports 1D/2D modes', () {
    expect(
      isBarcodeAllowedForMode(
        format: BarcodeFormat.qrCode,
        mode: ScannerCodeMode.twoDimensional,
      ),
      isTrue,
    );
    expect(
      isBarcodeAllowedForMode(
        format: BarcodeFormat.code128,
        mode: ScannerCodeMode.twoDimensional,
      ),
      isFalse,
    );
    expect(
      isBarcodeAllowedForMode(
        format: BarcodeFormat.code128,
        mode: ScannerCodeMode.oneDimensional,
      ),
      isTrue,
    );
  });

  test('firstNonEmptyBarcodeValueForMode returns match for selected mode', () {
    const capture = BarcodeCapture(
      barcodes: <Barcode>[
        Barcode(format: BarcodeFormat.qrCode, rawValue: 'QR-001'),
        Barcode(format: BarcodeFormat.code128, rawValue: 'BAR-001'),
      ],
    );

    expect(
      firstNonEmptyBarcodeValueForMode(
        capture,
        ScannerCodeMode.twoDimensional,
      ),
      'QR-001',
    );
    expect(
      firstNonEmptyBarcodeValueForMode(
        capture,
        ScannerCodeMode.oneDimensional,
      ),
      'BAR-001',
    );
  });
}

Widget _buildNoopScanner(
  MobileScannerController controller,
  ValueChanged<String> onDetectedValue,
) {
  return const SizedBox.expand();
}

Future<Future<Object?>> _openScannerPage(
  WidgetTester tester, {
  _CountingNavigatorObserver? observer,
  required ScannerPage Function() pageBuilder,
}) async {
  late Future<Object?> resultFuture;
  await tester.pumpWidget(
    MaterialApp(
      navigatorObservers: <NavigatorObserver>[
        if (observer != null) observer,
      ],
      home: Builder(
        builder: (BuildContext context) {
          return FilledButton(
            onPressed: () {
              resultFuture = Navigator.of(context).push<Object?>(
                MaterialPageRoute<Object?>(
                  builder: (BuildContext context) => pageBuilder(),
                ),
              );
            },
            child: const Text('Open Scanner'),
          );
        },
      ),
    ),
  );

  await tester.tap(find.text('Open Scanner'));
  await tester.pumpAndSettle();
  return resultFuture;
}

class _CountingNavigatorObserver extends NavigatorObserver {
  int popCount = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount++;
    super.didPop(route, previousRoute);
  }
}
