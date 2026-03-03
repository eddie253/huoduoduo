import 'package:flutter/material.dart';

import 'shell_navigation_state.dart';

enum LegacyMenuActionType {
  openWeb,
  openScanner,
  openShipment,
  openSignature,
  openSettings,
  openMaps,
  openArrivalUploadErrors,
  openProxyMenu,
  logout,
  placeholder,
}

class LegacyMenuTileMapping {
  const LegacyMenuTileMapping._({
    required this.label,
    required this.icon,
    required this.actionType,
    this.webPath,
    this.scanType,
    this.enabled = true,
  });

  const LegacyMenuTileMapping.web({
    required String label,
    required IconData icon,
    required String webPath,
  }) : this._(
          label: label,
          icon: icon,
          actionType: LegacyMenuActionType.openWeb,
          webPath: webPath,
        );

  const LegacyMenuTileMapping.scanner({
    required String label,
    required IconData icon,
    required String scanType,
  }) : this._(
          label: label,
          icon: icon,
          actionType: LegacyMenuActionType.openScanner,
          scanType: scanType,
        );

  const LegacyMenuTileMapping.action({
    required String label,
    required IconData icon,
    required LegacyMenuActionType actionType,
  }) : this._(
          label: label,
          icon: icon,
          actionType: actionType,
        );

  const LegacyMenuTileMapping.placeholder()
      : this._(
          label: '保留',
          icon: Icons.local_shipping_outlined,
          actionType: LegacyMenuActionType.placeholder,
          enabled: false,
        );

  final String label;
  final IconData icon;
  final LegacyMenuActionType actionType;
  final String? webPath;
  final String? scanType;
  final bool enabled;
}

Uri legacyAppUri(String path) {
  return Uri.https('old.huoduoduo.com.tw', '/app/$path');
}

Map<ShellSection, List<LegacyMenuTileMapping>> buildLegacyMenuMapping() {
  return <ShellSection, List<LegacyMenuTileMapping>>{
    ShellSection.reservation: <LegacyMenuTileMapping>[
      const LegacyMenuTileMapping.web(
        label: '預約貨件',
        icon: Icons.event_available_rounded,
        webPath: 'rvt/ge.aspx',
      ),
      const LegacyMenuTileMapping.web(
        label: '取消預約',
        icon: Icons.event_busy_rounded,
        webPath: 'rvt/ge_c.aspx',
      ),
      const LegacyMenuTileMapping.web(
        label: '已到倉庫',
        icon: Icons.warehouse_rounded,
        webPath: 'inq/strg.aspx',
      ),
      const LegacyMenuTileMapping.web(
        label: '大貨預約',
        icon: Icons.local_shipping_rounded,
        webPath: 'rvt/bh.aspx',
      ),
      const LegacyMenuTileMapping.web(
        label: '大貨取消預約',
        icon: Icons.inventory_2_rounded,
        webPath: 'rvt/bh_c.aspx',
      ),
      const LegacyMenuTileMapping.web(
        label: '預約縣市設定',
        icon: Icons.location_city_rounded,
        webPath: 'rvt/df_area.aspx',
      ),
      const LegacyMenuTileMapping.web(
        label: '押金明細',
        icon: Icons.savings_rounded,
        webPath: 'inq/dep.aspx',
      ),
      const LegacyMenuTileMapping.placeholder(),
    ],
    ShellSection.order: <LegacyMenuTileMapping>[
      const LegacyMenuTileMapping.scanner(
        label: '接單',
        icon: Icons.qr_code_scanner_rounded,
        scanType: '接單',
      ),
      const LegacyMenuTileMapping.scanner(
        label: '接單取消',
        icon: Icons.assignment_late_rounded,
        scanType: '接單取消',
      ),
      const LegacyMenuTileMapping.web(
        label: '接單明細',
        icon: Icons.description_rounded,
        webPath: 'inq/dtl.aspx',
      ),
      const LegacyMenuTileMapping.action(
        label: '測試GPS',
        icon: Icons.route_rounded,
        actionType: LegacyMenuActionType.openMaps,
      ),
      const LegacyMenuTileMapping.placeholder(),
      const LegacyMenuTileMapping.placeholder(),
      const LegacyMenuTileMapping.placeholder(),
      const LegacyMenuTileMapping.placeholder(),
    ],
    ShellSection.signature: <LegacyMenuTileMapping>[
      const LegacyMenuTileMapping.scanner(
        label: '單筆簽收',
        icon: Icons.fact_check_rounded,
        scanType: '單筆簽收',
      ),
      const LegacyMenuTileMapping.scanner(
        label: '多筆簽收',
        icon: Icons.assignment_rounded,
        scanType: '多筆簽收',
      ),
      const LegacyMenuTileMapping.action(
        label: '一鍵上傳',
        icon: Icons.cloud_upload_rounded,
        actionType: LegacyMenuActionType.openShipment,
      ),
      const LegacyMenuTileMapping.scanner(
        label: '取消送達',
        icon: Icons.local_shipping_outlined,
        scanType: '取消送達',
      ),
      const LegacyMenuTileMapping.scanner(
        label: '送達異常',
        icon: Icons.playlist_remove_rounded,
        scanType: '送達異常',
      ),
      const LegacyMenuTileMapping.scanner(
        label: '多筆送達異常',
        icon: Icons.cancel_schedule_send_rounded,
        scanType: '多筆送達異常',
      ),
      const LegacyMenuTileMapping.web(
        label: '送達明細',
        icon: Icons.list_alt_rounded,
        webPath: 'inq/arv.aspx',
      ),
      const LegacyMenuTileMapping.action(
        label: '簽收上傳錯誤',
        icon: Icons.cloud_sync_rounded,
        actionType: LegacyMenuActionType.openArrivalUploadErrors,
      ),
    ],
    ShellSection.wallet: <LegacyMenuTileMapping>[
      const LegacyMenuTileMapping.web(
        label: '提現',
        icon: Icons.payments_rounded,
        webPath: 'currency/wda.aspx',
      ),
      const LegacyMenuTileMapping.web(
        label: '帳號管理',
        icon: Icons.badge_rounded,
        webPath: 'currency/bifm.aspx',
      ),
      const LegacyMenuTileMapping.web(
        label: '銀行帳號',
        icon: Icons.credit_card_rounded,
        webPath: 'currency/bank.aspx',
      ),
      const LegacyMenuTileMapping.web(
        label: '帳戶日明細',
        icon: Icons.stacked_bar_chart_rounded,
        webPath: 'currency/day_cy.aspx',
      ),
      const LegacyMenuTileMapping.web(
        label: '帳戶月明細',
        icon: Icons.bar_chart_rounded,
        webPath: 'currency/month_cy.aspx',
      ),
      const LegacyMenuTileMapping.action(
        label: '代理',
        icon: Icons.groups_rounded,
        actionType: LegacyMenuActionType.openProxyMenu,
      ),
      const LegacyMenuTileMapping.action(
        label: '設定',
        icon: Icons.settings_rounded,
        actionType: LegacyMenuActionType.openSettings,
      ),
      const LegacyMenuTileMapping.action(
        label: '登出',
        icon: Icons.logout_rounded,
        actionType: LegacyMenuActionType.logout,
      ),
    ],
  };
}
