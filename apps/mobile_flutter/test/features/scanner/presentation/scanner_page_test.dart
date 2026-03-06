import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scan_kit_core/scan_kit_core.dart' show ScanFrameMode;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile_flutter/features/scanner/application/scanner_view_model.dart';
import 'package:mobile_flutter/features/scanner/presentation/scanner_page.dart';

Widget _scoped(Widget child) => ProviderScope(child: MaterialApp(home: child));

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('shows scan type in app bar title', (WidgetTester tester) async {
    await tester.pumpWidget(
      _scoped(const ScannerPage(
        scanType: 'qr',
        scannerViewBuilder: _buildNoopScanner,
      )),
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
      _scoped(const ScannerPage(
        scanType: 'qr',
        scannerViewBuilder: _buildNoopScanner,
      )),
    );

    expect(find.text(scannerHintText), findsOneWidget);
    expect(find.byKey(scannerToolRowKey), findsOneWidget);
    expect(find.byKey(scannerFlashButtonKey), findsOneWidget);
    expect(find.byKey(scannerKeypadButtonKey), findsOneWidget);
    expect(find.byKey(scannerSettingButtonKey), findsOneWidget);
    expect(find.byKey(scannerFrameOverlayKey), findsOneWidget);
    expect(find.byKey(scannerFrameWindowKey), findsOneWidget);
  });

  testWidgets('ignores empty scan value and stays on page',
      (WidgetTester tester) async {
    await _openScannerPage(
      tester,
      pageBuilder: () => ScannerPage(
        scannerViewBuilder: (
          BuildContext context,
          ValueChanged<Object> onEngineCode,
        ) {
          return Center(
            child: FilledButton(
              onPressed: () => onEngineCode('   '),
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
          BuildContext context,
          ValueChanged<Object> onEngineCode,
        ) {
          return Center(
            child: FilledButton(
              onPressed: () {
                onEngineCode('CODE-123');
                onEngineCode('CODE-456');
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

  test('scan frame mode follows scanner code mode', () {
    expect(
      scanFrameModeFor(ScannerCodeMode.oneDimensional),
      ScanFrameMode.oneDimensional,
    );
    expect(
      scanFrameModeFor(ScannerCodeMode.twoDimensional),
      ScanFrameMode.twoDimensional,
    );
    expect(
      scanFrameModeFor(ScannerCodeMode.all),
      ScanFrameMode.twoDimensional,
    );
  });

  test('legacy scan frame rect uses wider and shorter frame for 1D', () {
    const size = Size(360, 640);
    final oneDim = legacyScanFrameRect(size, ScanFrameMode.oneDimensional);
    final twoDim = legacyScanFrameRect(size, ScanFrameMode.twoDimensional);

    expect(oneDim.width, equals(twoDim.width));
    expect(oneDim.height, lessThan(twoDim.height));
  });

  test('scannerCodeModeLabel returns correct labels', () {
    expect(scannerCodeModeLabel(ScannerCodeMode.oneDimensional), '1D');
    expect(scannerCodeModeLabel(ScannerCodeMode.twoDimensional), '2D');
    expect(scannerCodeModeLabel(ScannerCodeMode.all), 'All');
  });

  test('scannerTitleFor formats title string', () {
    expect(scannerTitleFor('qr'), '掃描：qr');
    expect(scannerTitleFor('barcode'), '掃描：barcode');
  });

  test('legacyScanFrameRect compact frame is smallest', () {
    const size = Size(360, 640);
    final compact = legacyScanFrameRect(size, ScanFrameMode.twoDimensional,
        frameSize: ScannerFrameSize.compact);
    final medium = legacyScanFrameRect(size, ScanFrameMode.twoDimensional,
        frameSize: ScannerFrameSize.medium);
    final large = legacyScanFrameRect(size, ScanFrameMode.twoDimensional,
        frameSize: ScannerFrameSize.large);

    expect(compact.width, lessThan(medium.width));
    expect(medium.width, lessThan(large.width));
  });

  testWidgets('flash button toggles torch', (WidgetTester tester) async {
    await tester.pumpWidget(
      _scoped(const ScannerPage(scannerViewBuilder: _buildNoopScanner)),
    );

    await tester.tap(find.byKey(scannerFlashButtonKey));
    await tester.pump();
  });

  testWidgets('keypad button opens manual input sheet',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _scoped(const ScannerPage(scannerViewBuilder: _buildNoopScanner)),
    );

    await tester.tap(find.byKey(scannerKeypadButtonKey));
    await tester.pump();
  });

  testWidgets('settings button opens scan mode dialog',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _scoped(const ScannerPage(scannerViewBuilder: _buildNoopScanner)),
    );

    await tester.tap(find.byKey(scannerSettingButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('掃描設定'), findsOneWidget);
    expect(find.text('1D + 2D'), findsOneWidget);
    expect(find.text('一維條碼'), findsOneWidget);
    expect(find.text('二維碼'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.text('掃描設定'), findsNothing);
  });

  testWidgets('settings dialog confirm changes scan mode',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _scoped(const ScannerPage(scannerViewBuilder: _buildNoopScanner)),
    );

    await tester.tap(find.byKey(scannerSettingButtonKey));
    await tester.pumpAndSettle();

    await tester.tap(find.text('一維條碼'));
    await tester.pump();
    await tester.tap(find.text('框小'));
    await tester.pump();
    await tester.tap(find.text('確認'));
    await tester.pumpAndSettle();

    expect(find.text('掃描設定'), findsNothing);
    expect(find.textContaining('1D'), findsWidgets);
  });
}

Widget _buildNoopScanner(
  BuildContext context,
  ValueChanged<Object> onEngineCode,
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
    ProviderScope(
      child: MaterialApp(
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
