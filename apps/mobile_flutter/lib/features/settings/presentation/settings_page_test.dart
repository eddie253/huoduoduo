import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:mobile_flutter/features/settings/presentation/settings_page.dart';

void main() {
  testWidgets('SETTINGS_MINIMAL_PARITY shows only app version',
      (WidgetTester tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'mobile_flutter',
      packageName: 'com.example.mobile_flutter',
      version: '1.2.3',
      buildNumber: '45',
      buildSignature: '',
      installerStore: 'play',
    );

    await tester.pumpWidget(
      const MaterialApp(home: SettingsPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('App Version'), findsOneWidget);
    expect(find.byKey(SettingsPage.versionTextKey), findsOneWidget);
    expect(find.text('1.2.3+45'), findsOneWidget);

    // Legacy-minimal settings page should not include theme controls.
    expect(find.byType(Switch), findsNothing);
    expect(find.byIcon(Icons.palette_outlined), findsNothing);
  });
}
