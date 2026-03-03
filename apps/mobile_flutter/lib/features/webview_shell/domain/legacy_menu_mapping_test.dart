import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_flutter/features/webview_shell/domain/legacy_menu_mapping.dart';
import 'package:mobile_flutter/features/webview_shell/domain/shell_navigation_state.dart';

void main() {
  test('LEGACY_MENU_RESERVATION_WEB_ROUTE uses expected reservation paths', () {
    final mapping = buildLegacyMenuMapping();
    final reservation = mapping[ShellSection.reservation]!;
    final webPaths = reservation
        .where((tile) => tile.actionType == LegacyMenuActionType.openWeb)
        .map((tile) => tile.webPath)
        .toList(growable: false);

    expect(webPaths, contains('rvt/ge.aspx'));
    expect(webPaths, contains('rvt/ge_c.aspx'));
    expect(webPaths, contains('rvt/bh.aspx'));
    expect(webPaths, contains('rvt/bh_c.aspx'));
    expect(webPaths, contains('rvt/df_area.aspx'));
    expect(webPaths, contains('inq/strg.aspx'));
    expect(webPaths, contains('inq/dep.aspx'));
  });

  test('arrival section includes upload error entry route action', () {
    final mapping = buildLegacyMenuMapping();
    final arrival = mapping[ShellSection.signature]!;

    final hasUploadErrorEntry = arrival.any(
      (tile) => tile.actionType == LegacyMenuActionType.openArrivalUploadErrors,
    );
    expect(hasUploadErrorEntry, isTrue);
  });

  test('wallet section includes proxy menu action', () {
    final mapping = buildLegacyMenuMapping();
    final wallet = mapping[ShellSection.wallet]!;

    final hasProxyMenu = wallet.any(
      (tile) => tile.actionType == LegacyMenuActionType.openProxyMenu,
    );
    expect(hasProxyMenu, isTrue);
  });
}
