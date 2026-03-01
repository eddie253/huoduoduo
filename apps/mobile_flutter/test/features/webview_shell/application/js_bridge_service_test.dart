import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/features/webview_shell/application/js_bridge_service.dart';

void main() {
  testWidgets('accepts all 8 bridge methods', (WidgetTester tester) async {
    final service = JsBridgeService();
    late BuildContext context;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext buildContext) {
            context = buildContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final methods = <String>[
      'error',
      'RefreshEnable',
      'redirect',
      'openfile',
      'open_IMG_Scanner',
      'openMsgExit',
      'cfs_sign',
      'APPEvent',
    ];

    for (final method in methods) {
      final result = await service.handle(
        <dynamic>[
          <String, dynamic>{
            'id': 'm-1',
            'version': '1.0',
            'method': method,
            'params': <String, dynamic>{
              'msg': 'x',
              'page': '/home',
              'kind': 'map'
            },
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        ],
        context,
      );

      if (method == 'openfile') {
        expect(result['ok'], isFalse);
        expect((result['error'] as Map<String, dynamic>)['code'],
            'BRIDGE_PERMISSION_DENIED');
      } else {
        expect(result['ok'], isTrue);
      }
    }
  });

  testWidgets('returns BRIDGE_INVALID_PAYLOAD for empty args',
      (WidgetTester tester) async {
    final service = JsBridgeService();
    late BuildContext context;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext buildContext) {
            context = buildContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final result = await service.handle(<dynamic>[], context);
    expect(result['ok'], isFalse);
    expect((result['error'] as Map<String, dynamic>)['code'],
        'BRIDGE_INVALID_PAYLOAD');
  });

  testWidgets('returns BRIDGE_UNSUPPORTED_METHOD for unknown method',
      (WidgetTester tester) async {
    final service = JsBridgeService();
    late BuildContext context;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext buildContext) {
            context = buildContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final result = await service.handle(
      <dynamic>[
        <String, dynamic>{
          'id': 'm-1',
          'version': '1.0',
          'method': 'unknown_method',
          'params': <String, dynamic>{},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      ],
      context,
    );

    expect(result['ok'], isFalse);
    expect((result['error'] as Map<String, dynamic>)['code'],
        'BRIDGE_UNSUPPORTED_METHOD');
  });

  testWidgets('returns BRIDGE_RUNTIME_ERROR on runtime exception',
      (WidgetTester tester) async {
    final service = JsBridgeService();
    late BuildContext context;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext buildContext) {
            context = buildContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final result = await service.handle(
      <dynamic>[
        <String, dynamic>{
          'id': 'm-1',
          'version': '1.0',
          'method': 'openMsgExit',
          'params': <String, dynamic>{'msg': const _ThrowOnToString()},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      ],
      context,
    );

    expect(result['ok'], isFalse);
    expect((result['error'] as Map<String, dynamic>)['code'],
        'BRIDGE_RUNTIME_ERROR');
  });
}

class _ThrowOnToString {
  const _ThrowOnToString();

  @override
  String toString() {
    throw StateError('runtime test');
  }
}
