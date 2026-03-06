import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mobile_flutter/features/maps/presentation/maps_page.dart';
import 'package:mobile_flutter/core/navigation/map_navigation_preflight_port.dart';

void main() {
  testWidgets('shows validation message when coordinate format is invalid',
      (WidgetTester tester) async {
    final launcher = _FakeLauncherPort();
    await tester.pumpWidget(
      MaterialApp(
        home: MapsPage(
          mapPreflight: const _FakeMapPreflightPort(),
          launchExternal: launcher.call,
        ),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, 'Latitude'), 'abc');
    await tester.tap(find.widgetWithText(FilledButton, 'Open Map'));
    await tester.pumpAndSettle();

    expect(find.text('Latitude/longitude format is invalid.'), findsOneWidget);
    expect(launcher.uris, isEmpty);
  });

  testWidgets('blocks map launch when preflight is not allowed',
      (WidgetTester tester) async {
    final launcher = _FakeLauncherPort();
    await tester.pumpWidget(
      MaterialApp(
        home: MapsPage(
          mapPreflight: const _FakeMapPreflightPort(
            result: MapNavigationPreflightResult.block(
              reason: MapNavigationBlockReason.googleAccountMissing,
              message: 'Google account is required.',
            ),
          ),
          launchExternal: launcher.call,
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Open Map'));
    await tester.pumpAndSettle();

    expect(find.text('Google account is required.'), findsOneWidget);
    expect(launcher.uris, isEmpty);
  });

  testWidgets('shows error when map external launch fails',
      (WidgetTester tester) async {
    final launcher = _FakeLauncherPort(result: false);
    await tester.pumpWidget(
      MaterialApp(
        home: MapsPage(
          mapPreflight: const _FakeMapPreflightPort(),
          launchExternal: launcher.call,
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Open Map'));
    await tester.pumpAndSettle();

    expect(find.text('Failed to open map application.'), findsOneWidget);
    expect(launcher.uris, hasLength(1));
    expect(launcher.uris.single.path, '/maps/dir/');
  });

  testWidgets('validates phone number before dialing',
      (WidgetTester tester) async {
    final launcher = _FakeLauncherPort();
    await tester.pumpWidget(
      MaterialApp(
        home: MapsPage(
          mapPreflight: const _FakeMapPreflightPort(),
          launchExternal: launcher.call,
        ),
      ),
    );

    await tester.enterText(
        find.widgetWithText(TextField, 'Phone Number'), '12');
    await tester.tap(find.widgetWithText(FilledButton, 'Dial Phone'));
    await tester.pumpAndSettle();

    expect(find.text('Phone number is invalid.'), findsOneWidget);
    expect(launcher.uris, isEmpty);
  });

  testWidgets('shows error when dialer launch fails',
      (WidgetTester tester) async {
    final launcher = _FakeLauncherPort(result: false);
    await tester.pumpWidget(
      MaterialApp(
        home: MapsPage(
          mapPreflight: const _FakeMapPreflightPort(),
          launchExternal: launcher.call,
        ),
      ),
    );

    await tester.enterText(
        find.widgetWithText(TextField, 'Phone Number'), '(02) 1234-5678');
    await tester.tap(find.widgetWithText(FilledButton, 'Dial Phone'));
    await tester.pumpAndSettle();

    expect(find.text('Failed to open dialer.'), findsOneWidget);
    expect(launcher.uris, hasLength(1));
    expect(launcher.uris.single.scheme, 'tel');
    expect(launcher.uris.single.path, '0212345678');
  });
}

class _FakeMapPreflightPort implements MapNavigationPreflightPort {
  const _FakeMapPreflightPort({
    this.result = const MapNavigationPreflightResult.allow(),
  });

  final MapNavigationPreflightResult result;

  @override
  Future<MapNavigationPreflightResult> ensureReady() async {
    return result;
  }
}

class _FakeLauncherPort {
  _FakeLauncherPort({this.result = true});

  final bool result;
  final List<Uri> uris = <Uri>[];
  final List<LaunchMode> modes = <LaunchMode>[];

  Future<bool> call(Uri uri, LaunchMode mode) async {
    uris.add(uri);
    modes.add(mode);
    return result;
  }
}
