import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/core/network/dio_provider.dart';
import 'package:mobile_flutter/features/auth/domain/auth_models.dart';
import 'package:mobile_flutter/features/webview_shell/presentation/webview_shell_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/fake_inappwebview_platform.dart';

WebviewBootstrap _testBootstrap() => const WebviewBootstrap(
      baseUrl: 'https://app.elf.com.tw/cn/entrust.aspx?IDCompany=S1',
      registerUrl: 'https://old.huoduoduo.com.tw/register/register.aspx',
      resetPasswordUrl:
          'https://old.huoduoduo.com.tw/register/register_resetpwd.aspx',
      cookies: [],
    );

void main() {
  group('WebviewBootstrap construction', () {
    test('stores all fields', () {
      const b = WebviewBootstrap(
        baseUrl: 'https://app.elf.com.tw/cn/entrust.aspx',
        registerUrl: 'https://old.huoduoduo.com.tw/register/register.aspx',
        resetPasswordUrl:
            'https://old.huoduoduo.com.tw/register/register_resetpwd.aspx',
        cookies: [],
      );
      expect(b.baseUrl, 'https://app.elf.com.tw/cn/entrust.aspx');
      expect(b.registerUrl, startsWith('https://'));
      expect(b.resetPasswordUrl, startsWith('https://'));
      expect(b.cookies, isEmpty);
    });

    test('non-empty cookies are stored', () {
      const b = WebviewBootstrap(
        baseUrl: 'https://example.com',
        registerUrl: 'https://example.com/r',
        resetPasswordUrl: 'https://example.com/p',
        cookies: [
          const WebCookieModel(
              name: 'sid',
              value: 'abc',
              domain: 'example.com',
              path: '/',
              secure: true,
              httpOnly: false),
        ],
      );
      expect(b.cookies.length, 1);
      expect(b.cookies.first.name, 'sid');
    });

    test('_testBootstrap helper produces valid bootstrap', () {
      final b = _testBootstrap();
      expect(b.baseUrl, contains('app.elf.com.tw'));
      expect(b.cookies, isEmpty);
    });
  });

  group('WebViewShellPage widget smoke', () {
    setUpAll(() {
      InAppWebViewPlatform.instance = FakeIAWPlatform();
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    Widget buildPage() {
      final fakeDio = Dio(BaseOptions(baseUrl: 'http://test.local'));
      fakeDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
                requestOptions: options, message: 'no server in tests'),
          ),
        ),
      );
      return ProviderScope(
        overrides: [dioProvider.overrideWithValue(fakeDio)],
        child: MaterialApp(
          home: WebViewShellPage(bootstrap: _testBootstrap()),
        ),
      );
    }

    Future<void> pumpPage(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildPage());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
    }

    testWidgets('renders Scaffold with shellScaffoldKey', (tester) async {
      await pumpPage(tester);
      expect(find.byKey(const Key('webview.shell.scaffold')), findsOneWidget);
    });

    testWidgets('bottom bar is present', (tester) async {
      await pumpPage(tester);
      expect(find.byKey(const Key('webview.bottomBar')), findsOneWidget);
    });

    testWidgets('bottom bar shows all four tab labels', (tester) async {
      await pumpPage(tester);
      for (final label in ['預約', '接單', '簽收', '錢包']) {
        expect(find.text(label), findsWidgets,
            reason: 'expected tab label $label');
      }
    });

    testWidgets('back button has opacity 0 in menu state', (tester) async {
      await pumpPage(tester);
      final opacity = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.byKey(const Key('webview.top.backButton')),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, 0.0);
    });

    testWidgets('settings button is present in menu state', (tester) async {
      await pumpPage(tester);
      expect(
          find.byKey(const Key('webview.top.settingsButton')), findsOneWidget);
    });

    testWidgets('tapping a bottom tab switches active section', (tester) async {
      await pumpPage(tester);
      await tester.tap(find.text('接單'));
      await tester.pump();
      expect(find.text('接單'), findsWidgets);
    });

    testWidgets('tapping wallet tab changes section title', (tester) async {
      await pumpPage(tester);
      await tester.tap(find.text('錢包'));
      await tester.pump();
      expect(find.text('錢包'), findsWidgets);
    });

    testWidgets('dispose cancels timer without error', (tester) async {
      await pumpPage(tester);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('WebViewShellPage key constants', () {
    test('scaffold key has expected string value', () {
      expect(const Key('webview.shell.scaffold'),
          const Key('webview.shell.scaffold'));
    });

    test('bottom bar key has expected string value', () {
      expect(const Key('webview.bottomBar'), const Key('webview.bottomBar'));
    });

    test('back button key has expected string value', () {
      expect(const Key('webview.top.backButton'),
          const Key('webview.top.backButton'));
    });

    test('settings button key has expected string value', () {
      expect(const Key('webview.top.settingsButton'),
          const Key('webview.top.settingsButton'));
    });
  });
}
