import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/features/auth/domain/auth_models.dart';
import 'package:mobile_flutter/features/webview_shell/presentation/webview_shell_page.dart';

const List<String> _kPlatformChannels = [
  'com.pichillilorenzo/flutter_inappwebview_0',
  'com.pichillilorenzo/flutter_inappwebview_manager',
  'com.pichillilorenzo/flutter_cookie_manager',
  'com.pichillilorenzo/flutter_chromeSafariBrowser_0',
];

WebviewBootstrap _testBootstrap() => const WebviewBootstrap(
      baseUrl: 'https://app.elf.com.tw/cn/entrust.aspx?IDCompany=S1',
      registerUrl: 'https://old.huoduoduo.com.tw/register/register.aspx',
      resetPasswordUrl:
          'https://old.huoduoduo.com.tw/register/register_resetpwd.aspx',
      cookies: [],
    );

void _installChannelMocks() {
  for (final name in _kPlatformChannels) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannel(name), (_) async => null);
  }
}

void _removeChannelMocks() {
  for (final name in _kPlatformChannels) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannel(name), null);
  }
}

void Function(FlutterErrorDetails)? _installErrorSuppressor() {
  final original = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exception.toString();
    if (details.exception is MissingPluginException ||
        msg.contains('PlatformView') ||
        msg.contains('InAppWebView') ||
        msg.contains('CookieManager')) {
      return;
    }
    original?.call(details);
  };
  return original;
}

void main() {
  group('WebViewShellPage – widget smoke tests', () {
    setUp(_installChannelMocks);
    tearDown(_removeChannelMocks);

    testWidgets('scaffold and bottom bar are present in initial render',
        (WidgetTester tester) async {
      final restoreError = _installErrorSuppressor();
      addTearDown(() => FlutterError.onError = restoreError);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WebViewShellPage(bootstrap: _testBootstrap()),
          ),
        ),
      );
      await tester.pump(Duration.zero);

      expect(find.byKey(const Key('webview.shell.scaffold')), findsOneWidget);
      expect(find.byKey(const Key('webview.bottomBar')), findsOneWidget);
    });

    testWidgets('bottom bar shows four tab labels',
        (WidgetTester tester) async {
      final restoreError = _installErrorSuppressor();
      addTearDown(() => FlutterError.onError = restoreError);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WebViewShellPage(bootstrap: _testBootstrap()),
          ),
        ),
      );
      await tester.pump(Duration.zero);

      final bar = find.byKey(const Key('webview.bottomBar'));
      expect(bar, findsOneWidget);
      expect(
          find.descendant(of: bar, matching: find.text('預約')), findsOneWidget);
      expect(
          find.descendant(of: bar, matching: find.text('接單')), findsOneWidget);
      expect(
          find.descendant(of: bar, matching: find.text('簽收')), findsOneWidget);
      expect(
          find.descendant(of: bar, matching: find.text('錢包')), findsOneWidget);
    });

    testWidgets('back button is transparent (opacity 0) when not in webview',
        (WidgetTester tester) async {
      final restoreError = _installErrorSuppressor();
      addTearDown(() => FlutterError.onError = restoreError);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WebViewShellPage(bootstrap: _testBootstrap()),
          ),
        ),
      );
      await tester.pump(Duration.zero);

      final opacityWidget = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.byKey(const Key('webview.top.backButton')),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacityWidget.opacity, 0.0);
    });

    testWidgets('settings button is visible when not in webview',
        (WidgetTester tester) async {
      final restoreError = _installErrorSuppressor();
      addTearDown(() => FlutterError.onError = restoreError);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WebViewShellPage(bootstrap: _testBootstrap()),
          ),
        ),
      );
      await tester.pump(Duration.zero);

      expect(
          find.byKey(const Key('webview.top.settingsButton')), findsOneWidget);
    });
  });
}
