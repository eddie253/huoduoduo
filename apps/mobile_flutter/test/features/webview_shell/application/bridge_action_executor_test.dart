import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mobile_flutter/features/webview_shell/application/bridge_action_executor.dart';

void main() {
  test('launchExternal returns false when URI cannot be launched', () async {
    final launcher = _FakeUrlLauncherPort(canLaunchResult: false);
    final executor = PlatformBridgeActionExecutor(
      urlLauncher: launcher,
      navigationPort: _FakeNavigationPort(),
    );

    final result = await executor.launchExternal(Uri.parse('tel:0223456789'));

    expect(result, isFalse);
    expect(launcher.launchedUris, isEmpty);
  });

  test('launchExternal delegates to launcher in external mode', () async {
    final launcher = _FakeUrlLauncherPort(
      canLaunchResult: true,
      launchResult: true,
    );
    final executor = PlatformBridgeActionExecutor(
      urlLauncher: launcher,
      navigationPort: _FakeNavigationPort(),
    );
    final uri = Uri.parse('https://old.huoduoduo.com.tw/register/register.aspx');

    final result = await executor.launchExternal(uri);

    expect(result, isTrue);
    expect(launcher.launchedUris, <Uri>[uri]);
    expect(launcher.lastMode, LaunchMode.externalApplication);
  });

  testWidgets('openScanner converts scanner result with scan type',
      (WidgetTester tester) async {
    final navigator = _FakeNavigationPort(
      responseByLocation: <String, Object?>{
        '/scanner': '  SCN-001  ',
      },
    );
    final executor = PlatformBridgeActionExecutor(
      urlLauncher: _FakeUrlLauncherPort(),
      navigationPort: navigator,
    );
    final context = await _pumpContext(tester);

    final result = await executor.openScanner(context, scanType: 'qr');

    expect(result, isNotNull);
    expect(result!.value, 'SCN-001');
    expect(result.scanType, 'qr');
    expect(navigator.calls.single.location, '/scanner');
    expect(
      navigator.calls.single.extra,
      <String, dynamic>{'scanType': 'qr'},
    );
  });

  testWidgets('openSignature maps payload and ignores incomplete payload',
      (WidgetTester tester) async {
    final navigator = _FakeNavigationPort(
      responseByLocation: <String, Object?>{
        '/signature': <String, dynamic>{
          'filePath': '/tmp/signature.png',
          'fileName': 'signature.png',
          'mimeType': 'image/png',
        },
      },
    );
    final executor = PlatformBridgeActionExecutor(
      urlLauncher: _FakeUrlLauncherPort(),
      navigationPort: navigator,
    );
    final context = await _pumpContext(tester);

    final success = await executor.openSignature(context);
    expect(success, isNotNull);
    expect(success!.filePath, '/tmp/signature.png');
    expect(success.fileName, 'signature.png');
    expect(success.mimeType, 'image/png');

    navigator.responseByLocation['/signature'] = <String, dynamic>{
      'filePath': '/tmp/only-path.png',
    };
    final invalid = await executor.openSignature(context);
    expect(invalid, isNull);
  });

  testWidgets('redirect normalizes route and forwards to navigation port',
      (WidgetTester tester) async {
    final navigator = _FakeNavigationPort();
    final executor = PlatformBridgeActionExecutor(
      urlLauncher: _FakeUrlLauncherPort(),
      navigationPort: navigator,
    );
    final context = await _pumpContext(tester);

    await executor.redirect(context, 'target');
    await executor.redirect(context, '/absolute');
    await executor.redirect(context, '   ');

    expect(
      navigator.calls.map((item) => item.location).toList(),
      <String>['/target', '/absolute'],
    );
  });

  testWidgets('closePage and showExitDialog work with navigator context',
      (WidgetTester tester) async {
    final executor = PlatformBridgeActionExecutor(
      urlLauncher: _FakeUrlLauncherPort(),
      navigationPort: _FakeNavigationPort(),
    );
    final context = await _pumpContext(tester);

    final closed = await executor.closePage(context);
    expect(closed, isFalse);

    final dialogFuture = executor.showExitDialog(context, 'session expired');
    await tester.pumpAndSettle();
    expect(find.text('Message'), findsOneWidget);
    expect(find.text('session expired'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await dialogFuture;
    expect(find.text('session expired'), findsNothing);
  });
}

Future<BuildContext> _pumpContext(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (BuildContext buildContext) {
          context = buildContext;
          return const Scaffold(body: Text('executor test'));
        },
      ),
    ),
  );
  return context;
}

class _FakeUrlLauncherPort implements UrlLauncherPort {
  _FakeUrlLauncherPort({
    this.canLaunchResult = true,
    this.launchResult = true,
  });

  final bool canLaunchResult;
  final bool launchResult;
  final List<Uri> launchedUris = <Uri>[];
  LaunchMode? lastMode;

  @override
  Future<bool> canLaunch(Uri uri) async => canLaunchResult;

  @override
  Future<bool> launch(Uri uri, {required LaunchMode mode}) async {
    launchedUris.add(uri);
    lastMode = mode;
    return launchResult;
  }
}

class _NavigationCall {
  const _NavigationCall({
    required this.location,
    this.extra,
  });

  final String location;
  final Object? extra;
}

class _FakeNavigationPort implements BridgeNavigationPort {
  _FakeNavigationPort({
    Map<String, Object?>? responseByLocation,
  }) : responseByLocation = responseByLocation ?? <String, Object?>{};

  final List<_NavigationCall> calls = <_NavigationCall>[];
  final Map<String, Object?> responseByLocation;

  @override
  Future<T?> push<T>(
    BuildContext context,
    String location, {
    Object? extra,
  }) async {
    calls.add(_NavigationCall(location: location, extra: extra));
    final response = responseByLocation[location];
    if (response == null) {
      return null;
    }
    return response as T;
  }
}
