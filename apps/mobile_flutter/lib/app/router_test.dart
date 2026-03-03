import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_flutter/app/app.dart';
import 'package:mobile_flutter/app/router.dart';
import 'package:mobile_flutter/features/arrival_upload_errors/presentation/arrival_upload_errors_page.dart';
import 'package:mobile_flutter/features/auth/domain/auth_models.dart';
import 'package:mobile_flutter/features/maps/presentation/maps_page.dart';
import 'package:mobile_flutter/features/proxy_menu/presentation/proxy_menu_page.dart';
import 'package:mobile_flutter/features/settings/presentation/settings_page.dart';

void main() {
  test('resolveWebviewBootstrap handles with/without payload', () {
    const bootstrap = WebviewBootstrap(
      baseUrl: 'https://old.huoduoduo.com.tw/app/rvt/ge.aspx',
      registerUrl: 'https://old.huoduoduo.com.tw/register/register.aspx',
      resetPasswordUrl:
          'https://old.huoduoduo.com.tw/register/register_resetpwd.aspx',
      cookies: <WebCookieModel>[],
    );

    expect(resolveWebviewBootstrap(null), isNull);
    expect(resolveWebviewBootstrap(<String, dynamic>{'x': 1}), isNull);
    expect(resolveWebviewBootstrap(bootstrap), same(bootstrap));
  });

  test('resolveScannerType parses /scanner extra payload', () {
    expect(resolveScannerType(null), 'default');
    expect(resolveScannerType(const <String, dynamic>{}), 'default');
    expect(
      resolveScannerType(const <String, dynamic>{'scanType': 'barcode'}),
      'barcode',
    );
    expect(
      resolveScannerType(const <String, dynamic>{'scanType': 123}),
      '123',
    );
  });

  testWidgets('settings/maps/new legacy routes are reachable',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DidiApp()));
    await tester.pumpAndSettle();

    appRouter.go('/settings');
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);

    appRouter.go('/maps');
    await tester.pumpAndSettle();
    expect(find.byType(MapsPage), findsOneWidget);

    appRouter.go('/arrival-upload-errors');
    await tester.pumpAndSettle();
    expect(find.byType(ArrivalUploadErrorsPage), findsOneWidget);

    appRouter.go('/proxy-menu');
    await tester.pumpAndSettle();
    expect(find.byType(ProxyMenuPage), findsOneWidget);

    appRouter.go('/login');
    await tester.pumpAndSettle();
  });
}
