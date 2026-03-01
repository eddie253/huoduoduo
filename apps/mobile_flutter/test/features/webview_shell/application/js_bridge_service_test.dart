import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_flutter/features/webview_shell/application/bridge_action_executor.dart';
import 'package:mobile_flutter/features/webview_shell/application/js_bridge_service.dart';
import 'package:mobile_flutter/features/webview_shell/domain/bridge_action_models.dart';

void main() {
  testWidgets('accepts all 8 bridge methods with executable behavior',
      (WidgetTester tester) async {
    final executor = _FakeBridgeActionExecutor();
    final service = JsBridgeService(actionExecutor: executor);
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

    final payloads = <Map<String, dynamic>>[
      _payload('error'),
      _payload('RefreshEnable', params: <String, dynamic>{'enable': 'true'}),
      _payload('redirect', params: <String, dynamic>{'page': '/shipment'}),
      _payload(
        'openfile',
        params: <String, dynamic>{'url': 'https://old.huoduoduo.com.tw/file'},
      ),
      _payload('open_IMG_Scanner', params: <String, dynamic>{'type': 'qr'}),
      _payload('openMsgExit', params: <String, dynamic>{'msg': 'x'}),
      _payload('cfs_sign'),
      _payload(
        'APPEvent',
        params: <String, dynamic>{'kind': 'map', 'result': '25.03,121.56'},
      ),
    ];

    for (final payload in payloads) {
      final result = await service.handle(<dynamic>[payload], context);
      expect(result['ok'], isTrue);
    }

    expect(executor.lastRedirectPage, '/shipment');
    expect(executor.lastScannerType, 'qr');
    expect(executor.dialogShown, isTrue);
    expect(executor.openedUrls.length, greaterThanOrEqualTo(2));
  });

  testWidgets('returns BRIDGE_INVALID_PAYLOAD for empty args',
      (WidgetTester tester) async {
    final service = JsBridgeService(actionExecutor: _FakeBridgeActionExecutor());
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
    expect(
      (result['error'] as Map<String, dynamic>)['code'],
      'BRIDGE_INVALID_PAYLOAD',
    );
  });

  testWidgets('returns BRIDGE_UNSUPPORTED_METHOD for unknown method',
      (WidgetTester tester) async {
    final service = JsBridgeService(actionExecutor: _FakeBridgeActionExecutor());
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
      <dynamic>[_payload('unknown_method')],
      context,
    );

    expect(result['ok'], isFalse);
    expect(
      (result['error'] as Map<String, dynamic>)['code'],
      'BRIDGE_UNSUPPORTED_METHOD',
    );
  });

  testWidgets('returns BRIDGE_PERMISSION_DENIED for non-allowlisted openfile',
      (WidgetTester tester) async {
    final service = JsBridgeService(actionExecutor: _FakeBridgeActionExecutor());
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
        _payload(
          'openfile',
          params: <String, dynamic>{'url': 'http://evil.example.com/file'},
        )
      ],
      context,
    );

    expect(result['ok'], isFalse);
    expect(
      (result['error'] as Map<String, dynamic>)['code'],
      'BRIDGE_PERMISSION_DENIED',
    );
  });

  testWidgets('returns BRIDGE_RUNTIME_ERROR when executor throws',
      (WidgetTester tester) async {
    final executor = _FakeBridgeActionExecutor()..throwOnLaunch = true;
    final service = JsBridgeService(actionExecutor: executor);
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
        _payload(
          'openfile',
          params: <String, dynamic>{'url': 'https://old.huoduoduo.com.tw/file'},
        )
      ],
      context,
    );

    expect(result['ok'], isFalse);
    expect(
      (result['error'] as Map<String, dynamic>)['code'],
      'BRIDGE_RUNTIME_ERROR',
    );
  });
}

Map<String, dynamic> _payload(
  String method, {
  Map<String, dynamic> params = const <String, dynamic>{},
}) {
  return <String, dynamic>{
    'id': 'm-1',
    'version': '1.0',
    'method': method,
    'params': params,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
}

class _FakeBridgeActionExecutor implements BridgeActionExecutor {
  final List<Uri> openedUrls = <Uri>[];
  String? lastScannerType;
  String? lastRedirectPage;
  bool dialogShown = false;
  bool throwOnLaunch = false;

  @override
  Future<bool> launchExternal(Uri uri) async {
    if (throwOnLaunch) {
      throw StateError('executor launch error');
    }
    openedUrls.add(uri);
    return true;
  }

  @override
  Future<bool> closePage(BuildContext context) async {
    return true;
  }

  @override
  Future<ScannerResult?> openScanner(
    BuildContext context, {
    required String scanType,
  }) async {
    lastScannerType = scanType;
    return ScannerResult(value: 'CODE-123', scanType: scanType);
  }

  @override
  Future<SignatureResult?> openSignature(BuildContext context) async {
    return const SignatureResult(
      filePath: '/tmp/signature.png',
      fileName: 'signature.png',
      mimeType: 'image/png',
    );
  }

  @override
  Future<void> redirect(BuildContext context, String page) async {
    lastRedirectPage = page;
  }

  @override
  Future<void> showExitDialog(BuildContext context, String message) async {
    dialogShown = true;
  }
}
