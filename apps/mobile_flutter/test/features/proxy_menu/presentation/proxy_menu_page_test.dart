import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:mobile_flutter/features/proxy_menu/presentation/proxy_menu_page.dart';

void main() {
  testWidgets('LEGACY_MENU_CURRENCY_PROXY_ENTRY returns selected web path',
      (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  await context.push('/proxy-menu');
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/proxy-menu',
          builder: (context, state) => const ProxyMenuPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(ProxyMenuPage), findsOneWidget);
    expect(find.byKey(ProxyMenuPage.mateButtonKey), findsOneWidget);
    expect(find.byKey(ProxyMenuPage.kpiButtonKey), findsOneWidget);
  });
}
