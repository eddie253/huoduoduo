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
    final context = await _pumpContext(tester);

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

  testWidgets('supports legacy methods pre_page and openImage',
      (WidgetTester tester) async {
    final executor = _FakeBridgeActionExecutor();
    final service = JsBridgeService(actionExecutor: executor);
    final context = await _pumpContext(tester);

    final prePageResult = await service.handle(
      <dynamic>[_payload('pre_page')],
      context,
    );
    expect(prePageResult['ok'], isTrue);
    expect(prePageResult['action'], 'legacy_pre_page_closed');

    final openImageResult = await service.handle(
      <dynamic>[
        _payload(
          'openImage',
          params: <String, dynamic>{
            'url': 'https://old.huoduoduo.com.tw/register/image.jpg',
          },
        )
      ],
      context,
    );
    expect(openImageResult['ok'], isTrue);
    expect(openImageResult['action'], 'legacy_image_opened');
  });

  testWidgets('returns BRIDGE_INVALID_PAYLOAD for empty args',
      (WidgetTester tester) async {
    final service =
        JsBridgeService(actionExecutor: _FakeBridgeActionExecutor());
    final context = await _pumpContext(tester);

    final result = await service.handle(<dynamic>[], context);
    expect(result['ok'], isFalse);
    expect(
      (result['error'] as Map<String, dynamic>)['code'],
      'BRIDGE_INVALID_PAYLOAD',
    );
  });

  testWidgets('returns BRIDGE_UNSUPPORTED_METHOD for unknown method',
      (WidgetTester tester) async {
    final service =
        JsBridgeService(actionExecutor: _FakeBridgeActionExecutor());
    final context = await _pumpContext(tester);

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
    final service =
        JsBridgeService(actionExecutor: _FakeBridgeActionExecutor());
    final context = await _pumpContext(tester);

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
    final context = await _pumpContext(tester);

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

  testWidgets('redirect validates page and supports external URL',
      (WidgetTester tester) async {
    final service =
        JsBridgeService(actionExecutor: _FakeBridgeActionExecutor());
    final context = await _pumpContext(tester);

    final emptyPage = await service.handle(
      <dynamic>[
        _payload('redirect', params: <String, dynamic>{'page': '   '})
      ],
      context,
    );
    expect(emptyPage['ok'], isFalse);
    expect((emptyPage['error'] as Map<String, dynamic>)['code'],
        'BRIDGE_INVALID_PAYLOAD');

    final external = await service.handle(
      <dynamic>[
        _payload(
          'redirect',
          params: <String, dynamic>{
            'page': 'https://app.elf.com.tw/cn/entrust.aspx?IDCompany=S1',
          },
        )
      ],
      context,
    );
    expect(external['ok'], isTrue);
    expect(external['action'], 'redirect_external_opened');
  });

  testWidgets('returns runtime error when openfile launch returns false',
      (WidgetTester tester) async {
    final executor = _FakeBridgeActionExecutor()..launchResult = false;
    final service = JsBridgeService(actionExecutor: executor);
    final context = await _pumpContext(tester);

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
    expect((result['error'] as Map<String, dynamic>)['code'],
        'BRIDGE_RUNTIME_ERROR');
  });

  testWidgets('returns scanner and signature cancelled results',
      (WidgetTester tester) async {
    final executor = _FakeBridgeActionExecutor()
      ..scannerResult = null
      ..signatureResult = null;
    final service = JsBridgeService(actionExecutor: executor);
    final context = await _pumpContext(tester);

    final scannerResult = await service.handle(
      <dynamic>[
        _payload('open_IMG_Scanner', params: <String, dynamic>{'type': 'qr'}),
      ],
      context,
    );
    expect(scannerResult['ok'], isTrue);
    expect(scannerResult['action'], 'scanner_cancelled');

    final signResult = await service.handle(
      <dynamic>[_payload('cfs_sign')],
      context,
    );
    expect(signResult['ok'], isTrue);
    expect(signResult['action'], 'signature_cancelled');
  });

  testWidgets('APPEvent map and dial validate parameters',
      (WidgetTester tester) async {
    final executor = _FakeBridgeActionExecutor();
    final service = JsBridgeService(actionExecutor: executor);
    final context = await _pumpContext(tester);

    final invalidDial = await service.handle(
      <dynamic>[
        _payload(
          'APPEvent',
          params: <String, dynamic>{'kind': 'dial', 'result': '12'},
        )
      ],
      context,
    );
    expect(invalidDial['ok'], isFalse);
    expect((invalidDial['error'] as Map<String, dynamic>)['code'],
        'BRIDGE_INVALID_PAYLOAD');

    final validDial = await service.handle(
      <dynamic>[
        _payload(
          'APPEvent',
          params: <String, dynamic>{
            'kind': 'dial',
            'result': '(02) 1234-5678',
          },
        )
      ],
      context,
    );
    expect(validDial['ok'], isTrue);
    expect(validDial['action'], 'dial_opened');

    final mapWithUrl = await service.handle(
      <dynamic>[
        _payload(
          'APPEvent',
          params: <String, dynamic>{
            'kind': 'map',
            'result':
                'https://maps.google.com/maps?f=d&saddr=25.03,121.56&daddr=25.04,121.57',
          },
        )
      ],
      context,
    );
    expect(mapWithUrl['ok'], isTrue);
    expect(mapWithUrl['action'], 'map_opened');
  });

  testWidgets('APPEvent close and contract branches are covered',
      (WidgetTester tester) async {
    final executor = _FakeBridgeActionExecutor()..closeResult = false;
    final service = JsBridgeService(actionExecutor: executor);
    final context = await _pumpContext(tester);

    final closeResult = await service.handle(
      <dynamic>[
        _payload(
          'APPEvent',
          params: <String, dynamic>{'kind': 'close', 'result': ''},
        )
      ],
      context,
    );
    expect(closeResult['ok'], isTrue);
    expect(closeResult['action'], 'page_close_ignored');

    final contractResult = await service.handle(
      <dynamic>[
        _payload(
          'APPEvent',
          params: <String, dynamic>{
            'kind': 'contract',
            'result':
                'https://old.huoduoduo.com.tw/register/register_resetpwd.aspx',
          },
        )
      ],
      context,
    );
    expect(contractResult['ok'], isTrue);
    expect(contractResult['action'], 'contract_opened');
  });
}

Future<BuildContext> _pumpContext(WidgetTester tester) async {
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
  return context;
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
  bool launchResult = true;
  bool closeResult = true;
  ScannerResult? scannerResult = const ScannerResult(
    value: 'CODE-123',
    scanType: 'default',
  );
  SignatureResult? signatureResult = const SignatureResult(
    filePath: '/tmp/signature.png',
    fileName: 'signature.png',
    mimeType: 'image/png',
  );

  @override
  Future<bool> launchExternal(Uri uri) async {
    if (throwOnLaunch) {
      throw StateError('executor launch error');
    }
    openedUrls.add(uri);
    return launchResult;
  }

  @override
  Future<bool> closePage(BuildContext context) async {
    return closeResult;
  }

  @override
  Future<ScannerResult?> openScanner(
    BuildContext context, {
    required String scanType,
  }) async {
    lastScannerType = scanType;
    if (scannerResult == null) {
      return null;
    }
    return ScannerResult(
      value: scannerResult!.value,
      scanType: scanType,
    );
  }

  @override
  Future<SignatureResult?> openSignature(BuildContext context) async {
    return signatureResult;
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
