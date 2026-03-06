import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_flutter/features/webview_shell/application/map_navigation_preflight_service.dart';
import 'package:mobile_flutter/features/webview_shell/application/webview_shell_navigation_helper.dart';

void main() {
  final helper = WebviewShellNavigationHelper(
    allowedHosts: <String>{'old.huoduoduo.com.tw'},
  );

  test('allowlist host check is case-insensitive', () {
    expect(helper.isAllowedHost('OLD.HUODUODUO.COM.TW'), isTrue);
    expect(helper.isAllowedHost('evil.example.com'), isFalse);
  });

  test('normalizeAllowedHttpsUri allows only https and allowlisted host', () {
    expect(
      helper.normalizeAllowedHttpsUri(
        Uri.parse('https://old.huoduoduo.com.tw/app/rvt/ge.aspx'),
      ),
      isNotNull,
    );
    expect(
      helper.normalizeAllowedHttpsUri(
        Uri.parse('http://old.huoduoduo.com.tw/app/rvt/ge.aspx'),
      ),
      isNull,
    );
    expect(
      helper.normalizeAllowedHttpsUri(
        Uri.parse('https://evil.example.com/page'),
      ),
      isNull,
    );
  });

  test('classifies external launch routing and map preflight requirement', () {
    final telDecision = helper.classifyExternalUri(Uri.parse('tel:0223456789'));
    expect(telDecision.shouldLaunchExternally, isTrue);
    expect(telDecision.requiresMapPreflight, isFalse);

    final mapDecision = helper.classifyExternalUri(
      Uri.parse('https://www.google.com/maps/dir/?api=1'),
    );
    expect(mapDecision.shouldLaunchExternally, isTrue);
    expect(mapDecision.requiresMapPreflight, isTrue);

    final blockedDecision = helper.classifyExternalUri(
      Uri.parse('https://evil.example.com/path'),
    );
    expect(blockedDecision.shouldLaunchExternally, isFalse);
  });

  test('resolves preflight error with fallback message', () {
    const withMessage = MapNavigationPreflightResult.block(
      reason: MapNavigationBlockReason.googleAccountMissing,
      message: 'Google account missing.',
    );
    const withoutMessage = MapNavigationPreflightResult.block(
      reason: MapNavigationBlockReason.googleAccountUnknown,
      message: '',
    );

    expect(
        helper.resolvePreflightError(withMessage), 'Google account missing.');
    expect(
      helper.resolvePreflightError(withoutMessage),
      WebviewShellNavigationHelper.fallbackPreflightMessage,
    );
  });
}
