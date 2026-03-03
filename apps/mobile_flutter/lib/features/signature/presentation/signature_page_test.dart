import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signature/signature.dart';

import 'package:mobile_flutter/features/signature/presentation/signature_page.dart';

void main() {
  testWidgets('shows prompt when trying to save an empty signature',
      (WidgetTester tester) async {
    final controller = _FakeSignatureController(isEmpty: true);
    await _openSignaturePage(
      tester,
      pageBuilder: () => SignaturePage(controller: controller),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Please sign first.'), findsOneWidget);
    expect(find.byType(SignaturePage), findsOneWidget);
  });

  testWidgets('returns signature payload when save succeeds',
      (WidgetTester tester) async {
    final controller = _FakeSignatureController(
      isEmpty: false,
      toPngBytesImpl: () async => Uint8List.fromList(<int>[1, 2, 3, 4]),
    );
    final writes = <String>[];
    final resultFuture = await _openSignaturePage(
      tester,
      pageBuilder: () => SignaturePage(
        controller: controller,
        now: () => DateTime.fromMillisecondsSinceEpoch(1773000000000),
        writeBytes: (File file, List<int> bytes) async {
          writes.add(file.path);
          expect(bytes, isNotEmpty);
        },
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final payload = await resultFuture as Map<String, dynamic>;
    expect(payload['mimeType'], 'image/png');
    expect(payload['fileName'], 'signature_1773000000000.png');
    expect(
        (payload['filePath'] as String).contains(payload['fileName']), isTrue);
    expect(writes.single.endsWith('signature_1773000000000.png'), isTrue);
  });

  testWidgets('shows error when signature save fails',
      (WidgetTester tester) async {
    final controller = _FakeSignatureController(
      isEmpty: false,
      toPngBytesImpl: () async => Uint8List.fromList(<int>[9, 9, 9]),
    );
    await _openSignaturePage(
      tester,
      pageBuilder: () => SignaturePage(
        controller: controller,
        writeBytes: (File file, List<int> bytes) {
          throw const FileSystemException('disk full');
        },
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Failed to save signature:'), findsOneWidget);
    expect(find.byType(SignaturePage), findsOneWidget);
  });

  testWidgets('toggles saving state while save is in progress',
      (WidgetTester tester) async {
    final completer = Completer<Uint8List?>();
    final controller = _FakeSignatureController(
      isEmpty: false,
      toPngBytesImpl: () => completer.future,
    );
    await _openSignaturePage(
      tester,
      pageBuilder: () => SignaturePage(
        controller: controller,
        writeBytes: (File file, List<int> bytes) {
          throw const FileSystemException('write failed');
        },
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final savingButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save'),
    );
    expect(savingButton.onPressed, isNull);

    completer.complete(Uint8List.fromList(<int>[1, 2, 3]));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    final savedButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save'),
    );
    expect(savedButton.onPressed, isNotNull);
  });
}

Future<Future<Object?>> _openSignaturePage(
  WidgetTester tester, {
  required SignaturePage Function() pageBuilder,
}) async {
  late Future<Object?> resultFuture;
  await tester.pumpWidget(
    MaterialApp(
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
            child: const Text('Open Signature'),
          );
        },
      ),
    ),
  );

  await tester.tap(find.text('Open Signature'));
  await tester.pumpAndSettle();
  return resultFuture;
}

class _FakeSignatureController extends SignatureController {
  _FakeSignatureController({
    required bool isEmpty,
    this.toPngBytesImpl,
  })  : _isEmpty = isEmpty,
        super(
          penStrokeWidth: 2,
          penColor: Colors.black,
          exportBackgroundColor: Colors.white,
        );

  bool _isEmpty;
  final Future<Uint8List?> Function()? toPngBytesImpl;

  @override
  bool get isEmpty => _isEmpty;

  @override
  Future<Uint8List?> toPngBytes({int? height, int? width}) async {
    final impl = toPngBytesImpl;
    if (impl != null) {
      return impl();
    }
    return Uint8List.fromList(<int>[1, 2, 3]);
  }

  @override
  void clear() {
    _isEmpty = true;
  }
}
