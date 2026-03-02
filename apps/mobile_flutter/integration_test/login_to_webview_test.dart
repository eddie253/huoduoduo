import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_flutter/app/app.dart';

const String _uatAccount =
    String.fromEnvironment('UAT_ACCOUNT', defaultValue: '');
const String _uatPassword =
    String.fromEnvironment('UAT_PASSWORD', defaultValue: '');
const String _uatTimeoutSecondsRaw =
    String.fromEnvironment('UAT_LOGIN_TIMEOUT_SECONDS', defaultValue: '40');

Future<void> _waitFor(
  WidgetTester tester, {
  required bool Function() predicate,
  required Duration timeout,
  String reason = 'Timed out while waiting for condition.',
}) async {
  final DateTime end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 300));
    if (predicate()) {
      return;
    }
  }
  throw TestFailure(reason);
}

String _readSnackBarMessage(WidgetTester tester) {
  final Finder snackBarFinder = find.byType(SnackBar);
  if (snackBarFinder.evaluate().isEmpty) {
    return '';
  }
  final SnackBar snackBar = tester.widget<SnackBar>(snackBarFinder.first);
  final Widget content = snackBar.content;
  if (content is Text) {
    return content.data ?? '';
  }
  return content.toStringShort();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login reaches WebView shell', (WidgetTester tester) async {
    if (_uatAccount.isEmpty || _uatPassword.isEmpty) {
      fail(
        'Missing UAT credentials. '
        'Provide --dart-define=UAT_ACCOUNT and --dart-define=UAT_PASSWORD.',
      );
    }

    final int timeoutSeconds = int.tryParse(_uatTimeoutSecondsRaw) ?? 40;

    await tester.pumpWidget(const ProviderScope(child: DidiApp()));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final Finder accountField = find.byKey(const Key('login.accountField'));
    final Finder passwordField = find.byKey(const Key('login.passwordField'));
    final Finder submitButton = find.byKey(const Key('login.submitButton'));

    expect(accountField, findsOneWidget);
    expect(passwordField, findsOneWidget);
    expect(submitButton, findsOneWidget);

    await tester.enterText(accountField, _uatAccount);
    await tester.enterText(passwordField, _uatPassword);
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();

    await _waitFor(
      tester,
      timeout: Duration(seconds: timeoutSeconds),
      reason: 'Login flow timed out before reaching WebView shell.',
      predicate: () {
        final bool reachedShell =
            find.byKey(const Key('webview.shell.scaffold')).evaluate().isNotEmpty;
        final bool loginErrorShown = find.byType(SnackBar).evaluate().isNotEmpty;
        return reachedShell || loginErrorShown;
      },
    );

    final String snackBarMessage = _readSnackBarMessage(tester);
    if (snackBarMessage.isNotEmpty) {
      fail('Login failed before WebView navigation: $snackBarMessage');
    }

    expect(find.byKey(const Key('webview.shell.scaffold')), findsOneWidget);
    expect(find.byKey(const Key('webview.top.backButton')), findsOneWidget);
    expect(find.byKey(const Key('webview.bottomBar')), findsOneWidget);
  });
}
