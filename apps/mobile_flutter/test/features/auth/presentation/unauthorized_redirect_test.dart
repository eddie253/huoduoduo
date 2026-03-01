import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_flutter/app/app.dart';
import 'package:mobile_flutter/app/router.dart';

void main() {
  testWidgets('redirects to login when /webview has no bootstrap payload',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DidiApp()));
    await tester.pumpAndSettle();

    appRouter.go('/webview');
    await tester.pumpAndSettle();

    expect(find.text('貨多多物流'), findsOneWidget);

    appRouter.go('/login');
    await tester.pumpAndSettle();
  });
}
