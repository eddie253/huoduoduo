import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/features/auth/presentation/login_page.dart';

void main() {
  testWidgets('shows required field validation messages',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginPage()),
      ),
    );

    await tester.tap(find.text('登入'));
    await tester.pumpAndSettle();

    expect(find.text('請輸入帳號'), findsOneWidget);
    expect(find.text('請輸入密碼'), findsOneWidget);
  });

  testWidgets('toggles password visibility', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginPage()),
      ),
    );

    EditableText passwordEditable() =>
        tester.widgetList<EditableText>(find.byType(EditableText)).last;

    expect(passwordEditable().obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(passwordEditable().obscureText, isFalse);

    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();

    expect(passwordEditable().obscureText, isTrue);
  });
}
