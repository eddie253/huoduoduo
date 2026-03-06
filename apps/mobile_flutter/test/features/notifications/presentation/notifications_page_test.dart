import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_flutter/features/notifications/presentation/notifications_page.dart';

void main() {
  testWidgets('renders notification placeholder card',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NotificationsPage()),
    );

    expect(find.text('Notifications feature placeholder'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
