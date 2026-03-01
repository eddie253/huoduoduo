import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_flutter/app/app.dart';

void main() {
  testWidgets('app renders login entry route', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DidiApp()));
    await tester.pumpAndSettle();

    expect(find.text('Didi Login'), findsOneWidget);
  });
}
