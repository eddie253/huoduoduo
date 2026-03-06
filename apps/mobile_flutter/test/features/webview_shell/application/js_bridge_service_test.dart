import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_flutter/features/webview_shell/application/bridge_action_executor.dart';
import 'package:mobile_flutter/features/webview_shell/application/js_bridge_service.dart';
import 'package:mobile_flutter/core/navigation/map_navigation_preflight_port.dart';
import 'package:mobile_flutter/features/webview_shell/domain/bridge_action_models.dart';

void main() {
  test('accepts all 8 bridge methods with executable behavior', () async {
    final uiPort = _FakeBridgeUiPort();
    final service = _createService(uiPort: uiPort);

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
      final result = await service.handle(<dynamic>[payload], uiPort);
      expect(result['ok'], isTrue);
    }

    expect(uiPort.lastRedirectPage, '/shipment');
    expect(uiPort.lastScannerType, 'qr');
    expect(uiPort.dialogShown, isTrue);
    expect(uiPort.openedUrls.length, greaterThanOrEqualTo(2));
  });

  test('supports legacy methods pre_page and openImage', () async {
    final uiPort = _FakeBridgeUiPort();
    final service = _createService(uiPort: uiPort);

    final prePageResult = await service.handle(
      <dynamic>[_payload('pre_page')],
      uiPort,
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
      uiPort,
    );
    expect(openImageResult['ok'], isTrue);
    expect(openImageResult['action'], 'legacy_image_opened');
  });

  test('returns BRIDGE_INVALID_PAYLOAD for empty args', () async {
    final uiPort = _FakeBridgeUiPort();
    final service = _createService(uiPort: uiPort);

    final result = await service.handle(<dynamic>[], uiPort);
    expect(result['ok'], isFalse);
    expect(
      (result['error'] as Map<String, dynamic>)['code'],
      'BRIDGE_INVALID_PAYLOAD',
    );
  });

  test('returns BRIDGE_UNSUPPORTED_METHOD for unknown method', () async {
    final uiPort = _FakeBridgeUiPort();
    final service = _createService(uiPort: uiPort);

    final result = await service.handle(
      <dynamic>[_payload('unknown_method')],
      uiPort,
    );

    expect(result['ok'], isFalse);
    expect(
      (result['error'] as Map<String, dynamic>)['code'],
      'BRIDGE_UNSUPPORTED_METHOD',
    );
  });

  test('returns BRIDGE_PERMISSION_DENIED for non-allowlisted openfile',
      () async {
    final uiPort = _FakeBridgeUiPort();
    final service = _createService(uiPort: uiPort);

    final result = await service.handle(
      <dynamic>[
        _payload(
          'openfile',
          params: <String, dynamic>{'url': 'http://evil.example.com/file'},
        )
      ],
      uiPort,
    );

    expect(result['ok'], isFalse);
    expect(
      (result['error'] as Map<String, dynamic>)['code'],
      'BRIDGE_PERMISSION_DENIED',
    );
  });

  test('returns BRIDGE_RUNTIME_ERROR when launcher throws', () async {
    final uiPort = _FakeBridgeUiPort()..throwOnLaunch = true;
    final service = _createService(uiPort: uiPort);

    final result = await service.handle(
      <dynamic>[
        _payload(
          'openfile',
          params: <String, dynamic>{'url': 'https://old.huoduoduo.com.tw/file'},
        )
      ],
      uiPort,
    );

    expect(result['ok'], isFalse);
    expect(
      (result['error'] as Map<String, dynamic>)['code'],
      'BRIDGE_RUNTIME_ERROR',
    );
  });

  test('redirect validates page and supports external URL', () async {
    final uiPort = _FakeBridgeUiPort();
    final service = _createService(uiPort: uiPort);

    final emptyPage = await service.handle(
      <dynamic>[
        _payload('redirect', params: <String, dynamic>{'page': '   '})
      ],
      uiPort,
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
      uiPort,
    );
    expect(external['ok'], isTrue);
    expect(external['action'], 'redirect_external_opened');
  });

  test('returns runtime error when openfile launch returns false', () async {
    final uiPort = _FakeBridgeUiPort()..launchResult = false;
    final service = _createService(uiPort: uiPort);

    final result = await service.handle(
      <dynamic>[
        _payload(
          'openfile',
          params: <String, dynamic>{'url': 'https://old.huoduoduo.com.tw/file'},
        )
      ],
      uiPort,
    );
    expect(result['ok'], isFalse);
    expect((result['error'] as Map<String, dynamic>)['code'],
        'BRIDGE_RUNTIME_ERROR');
  });

  test('returns scanner and signature cancelled results', () async {
    final uiPort = _FakeBridgeUiPort()
      ..scannerResult = null
      ..signatureResult = null;
    final service = _createService(uiPort: uiPort);

    final scannerResult = await service.handle(
      <dynamic>[
        _payload('open_IMG_Scanner', params: <String, dynamic>{'type': 'qr'}),
      ],
      uiPort,
    );
    expect(scannerResult['ok'], isTrue);
    expect(scannerResult['action'], 'scanner_cancelled');

    final signResult = await service.handle(
      <dynamic>[_payload('cfs_sign')],
      uiPort,
    );
    expect(signResult['ok'], isTrue);
    expect(signResult['action'], 'signature_cancelled');
  });

  test('APPEvent map and dial validate parameters', () async {
    final uiPort = _FakeBridgeUiPort();
    final service = _createService(uiPort: uiPort);

    final invalidDial = await service.handle(
      <dynamic>[
        _payload(
          'APPEvent',
          params: <String, dynamic>{'kind': 'dial', 'result': '12'},
        )
      ],
      uiPort,
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
      uiPort,
    );
    expect(validDial['ok'], isTrue);
    expect(validDial['action'], 'dial_opened');

    final mapWithCoordinate = await service.handle(
      <dynamic>[
        _payload(
          'APPEvent',
          params: <String, dynamic>{
            'kind': 'map',
            'result': '25.03,121.56',
          },
        )
      ],
      uiPort,
    );
    expect(mapWithCoordinate['ok'], isTrue);
    expect(mapWithCoordinate['action'], 'map_opened');
    final coordinateUrl = uiPort.openedUrls.last;
    expect(coordinateUrl.path, '/maps/dir/');
    expect(coordinateUrl.queryParameters['destination'], '25.03,121.56');
    expect(coordinateUrl.queryParameters['travelmode'], 'driving');
    expect(coordinateUrl.queryParameters['dir_action'], 'navigate');

    final legacyMapWithJson = await service.handle(
      <dynamic>[
        _payload(
          'APPEvent',
          params: <String, dynamic>{
            'kind': 'GM\u5c0e\u822a',
            'result':
                '{"adr":"\u53f0\u5317\u5e02\u4fe1\u7fa9\u5340\u677e\u58fd\u8def20\u865f","latlng":"25.0330,121.5654"}',
          },
        )
      ],
      uiPort,
    );
    expect(legacyMapWithJson['ok'], isTrue);
    expect(legacyMapWithJson['action'], 'map_opened');
    final legacyMapUrl = uiPort.openedUrls.last;
    expect(legacyMapUrl.path, '/maps/dir/');
    expect(legacyMapUrl.queryParameters['origin'], '25.0330,121.5654');
    expect(
      legacyMapUrl.queryParameters['destination'],
      '\u53f0\u5317\u5e02\u4fe1\u7fa9\u5340\u677e\u58fd\u8def20\u865f',
    );

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
      uiPort,
    );
    expect(mapWithUrl['ok'], isTrue);
    expect(mapWithUrl['action'], 'map_opened');

    final mapWithAddressOnly = await service.handle(
      <dynamic>[
        _payload(
          'APPEvent',
          params: <String, dynamic>{
            'kind': '\u5c0e\u822a',
            'result':
                '\u65b0\u5317\u5e02\u6c38\u548c\u5340\u7af9\u6797\u8def70\u865f',
          },
        )
      ],
      uiPort,
    );
    expect(mapWithAddressOnly['ok'], isTrue);
    expect(mapWithAddressOnly['action'], 'map_opened');
    final mapAddressUrl = uiPort.openedUrls.last;
    expect(
      mapAddressUrl.queryParameters['destination'],
      '\u65b0\u5317\u5e02\u6c38\u548c\u5340\u7af9\u6797\u8def70\u865f',
    );

    final mapWithLegacyMapString = await service.handle(
      <dynamic>[
        _payload(
          'APPEvent',
          params: <String, dynamic>{
            'kind': 'map',
            'result':
                '{adr=\u53f0\u7063220\u65b0\u5317\u5e02\u677f\u6a4b\u5340,\u4e2d\u5c71\u8def\u4e00\u6bb5161\u865f,zip=220 }',
          },
        ),
      ],
      uiPort,
    );
    expect(mapWithLegacyMapString['ok'], isTrue);
    expect(mapWithLegacyMapString['action'], 'map_opened');
    final legacyMapStringUrl = uiPort.openedUrls.last;
    expect(legacyMapStringUrl.path, '/maps/dir/');
    expect(
      legacyMapStringUrl.queryParameters['destination'],
      '\u65b0\u5317\u5e02\u677f\u6a4b\u5340,\u4e2d\u5c71\u8def\u4e00\u6bb5161\u865f',
    );
  });

  test('APPEvent close and contract branches are covered', () async {
    final uiPort = _FakeBridgeUiPort()..closeResult = false;
    final service = _createService(uiPort: uiPort);

    final closeResult = await service.handle(
      <dynamic>[
        _payload(
          'APPEvent',
          params: <String, dynamic>{'kind': 'close', 'result': ''},
        )
      ],
      uiPort,
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
      uiPort,
    );
    expect(contractResult['ok'], isTrue);
    expect(contractResult['action'], 'contract_opened');
  });

  test('APPEvent map returns permission denied when preflight blocks',
      () async {
    final uiPort = _FakeBridgeUiPort();
    final service = _createService(
      uiPort: uiPort,
      preflight: const _FakeMapNavigationPreflightPort(
        result: MapNavigationPreflightResult.block(
          reason: MapNavigationBlockReason.googleAccountMissing,
          message: 'Google account is not signed in on this device.',
        ),
      ),
    );

    final result = await service.handle(
      <dynamic>[
        _payload(
          'APPEvent',
          params: <String, dynamic>{
            'kind': 'map',
            'result': '25.03,121.56',
          },
        ),
      ],
      uiPort,
    );

    expect(result['ok'], isFalse);
    expect((result['error'] as Map<String, dynamic>)['code'],
        'BRIDGE_PERMISSION_DENIED');
  });

  test(
      'APPEvent map preflight denied uses fallback message when message is empty',
      () async {
    final uiPort = _FakeBridgeUiPort();
    final service = _createService(
      uiPort: uiPort,
      preflight: const _FakeMapNavigationPreflightPort(
        result: MapNavigationPreflightResult.block(
          reason: MapNavigationBlockReason.googleAccountUnknown,
          message: '',
        ),
      ),
    );

    final result = await service.handle(
      <dynamic>[
        _payload(
          'APPEvent',
          params: <String, dynamic>{
            'kind': 'map',
            'result': '25.03,121.56',
          },
        ),
      ],
      uiPort,
    );

    expect(result['ok'], isFalse);
    expect(
      (result['error'] as Map<String, dynamic>)['code'],
      'BRIDGE_PERMISSION_DENIED',
    );
    expect(
      (result['error'] as Map<String, dynamic>)['message'],
      'Navigation preflight failed.',
    );
  });

  test('APPEvent map returns runtime error when launcher fails', () async {
    final uiPort = _FakeBridgeUiPort()..launchResult = false;
    final service = _createService(
      uiPort: uiPort,
      preflight: const _FakeMapNavigationPreflightPort(),
    );

    final result = await service.handle(
      <dynamic>[
        _payload(
          'APPEvent',
          params: <String, dynamic>{
            'kind': 'map',
            'result': '25.03,121.56',
          },
        ),
      ],
      uiPort,
    );

    expect(result['ok'], isFalse);
    expect(
      (result['error'] as Map<String, dynamic>)['code'],
      'BRIDGE_RUNTIME_ERROR',
    );
    expect(
      (result['error'] as Map<String, dynamic>)['message'],
      'Failed to open map application',
    );
  });

  test('APPEvent map falls back to web URL when deep link launch fails',
      () async {
    final uiPort = _FakeBridgeUiPort()..launchResults = <bool>[false, true];
    final service = _createService(
      uiPort: uiPort,
      preflight: const _FakeMapNavigationPreflightPort(),
    );

    final result = await service.handle(
      <dynamic>[
        _payload(
          'APPEvent',
          params: <String, dynamic>{
            'kind': 'map',
            'result': 'google.navigation:q=25.03,121.56',
          },
        ),
      ],
      uiPort,
    );

    expect(result['ok'], isTrue);
    expect(result['action'], 'map_opened');
    expect(uiPort.openedUrls, hasLength(2));
    expect(uiPort.openedUrls.first.scheme, 'google.navigation');
    expect(uiPort.openedUrls.last.scheme, 'https');
    expect(uiPort.openedUrls.last.host, 'www.google.com');
  });

  test('APPEvent map invalid payload returns consistent error', () async {
    final uiPort = _FakeBridgeUiPort();
    final service = _createService(uiPort: uiPort);

    final result = await service.handle(
      <dynamic>[
        _payload(
          'APPEvent',
          params: <String, dynamic>{
            'kind': 'map',
            'result': '',
          },
        ),
      ],
      uiPort,
    );

    expect(result['ok'], isFalse);
    expect(
      (result['error'] as Map<String, dynamic>)['code'],
      'BRIDGE_INVALID_PAYLOAD',
    );
    expect(
      (result['error'] as Map<String, dynamic>)['message'],
      'APPEvent map requires valid coordinates or map URL',
    );
  });
}

JsBridgeService _createService({
  required _FakeBridgeUiPort uiPort,
  MapNavigationPreflightPort preflight =
      const _FakeMapNavigationPreflightPort(),
}) {
  return JsBridgeService(
    mapNavigationPreflight: preflight,
  );
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

class _FakeBridgeUiPort implements BridgeUiPort {
  final List<Uri> openedUrls = <Uri>[];
  String? lastScannerType;
  String? lastRedirectPage;
  bool dialogShown = false;
  bool throwOnLaunch = false;
  bool launchResult = true;
  List<bool> launchResults = <bool>[];
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
      throw StateError('launcher error');
    }
    openedUrls.add(uri);
    if (launchResults.isNotEmpty) {
      return launchResults.removeAt(0);
    }
    return launchResult;
  }

  @override
  Future<bool> closePage() async => closeResult;

  @override
  Future<ScannerResult?> openScanner(String scanType) async {
    lastScannerType = scanType;
    if (scannerResult == null) {
      return null;
    }
    return ScannerResult(value: scannerResult!.value, scanType: scanType);
  }

  @override
  Future<SignatureResult?> openSignature() async => signatureResult;

  @override
  Future<void> redirect(String page) async {
    lastRedirectPage = page;
  }

  @override
  Future<void> showExitDialog(String message) async {
    dialogShown = true;
  }
}

class _FakeMapNavigationPreflightPort implements MapNavigationPreflightPort {
  const _FakeMapNavigationPreflightPort({
    this.result = const MapNavigationPreflightResult.allow(),
  });

  final MapNavigationPreflightResult result;

  @override
  Future<MapNavigationPreflightResult> ensureReady() async {
    return result;
  }
}
