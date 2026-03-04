# PLAN16：底部分頁返回一致性 + 頂部設定入口 + 6 色主題與暗黑模式

Doc ID: HDD-DOCS-PLANS-PLAN16
Version: v1.0
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: Draft
CN/EN Pair Link: N/A






## Summary

1. 對齊舊 APP 分頁返回行為：Web 內容返回優先 `goBack`，無歷史時回到原分頁主頁。
2. 新增頂部右側設定入口：Root 狀態顯示設定，Web 狀態維持刷新。
3. 新增原生設定頁：4x2 版面，第一張 1x2 大卡提供 6 色切換 + 暗黑模式，其餘空白保留。
4. 主題切換全 App 即時生效且持久化（SharedPreferences）。

## Scope

1. Flutter shell 導覽狀態重構（`ShellNavigationState`）。
2. `/settings` 路由與設定頁 UI。
3. 主題系統（preset + dark mode）與持久化。
4. Login/WebViewShell/Shipment/Notifications/Scanner/Signature 主色接入 theme token。

## Public API / Interface Changes

1. 新增路由：`/settings`。
2. `WebViewShellPage` 新增測試 key：`webview.top.settingsButton`。
3. 新增動作型別：`_MenuActionType.openSettings`。
4. 新增主題介面：
   1. `AppThemePreset`
   2. `AppThemePrefs`
   3. `ThemePreferenceStore`
   4. `AppThemeController`
5. 新增持久化鍵值：
   1. `ui_theme_preset`
   2. `ui_theme_dark_mode`

## Theme 規格

1. 色票 6 款（預設：Legacy Orange）：
   1. `#FC5000` Legacy Orange
   2. `#1E88E5` Azure Blue
   3. `#2E7D32` Emerald Green
   4. `#D32F2F` Ruby Red
   5. `#00897B` Teal Green
   6. `#F9A825` Amber Gold
2. 暗黑模式：手動開關（非跟隨系統）。
3. 生效範圍：全 App 即時生效 + 重啟保留。

## Final Gate

1. [X] `flutter analyze`
2. [X] `flutter test`
3. [X] `npm run mobile:test:coverage`
4. [X] `npm run mobile:coverage:check`

## Notes

1. 入口策略：頂部右上角與錢包「設定」卡片共用同一設定頁。
2. 目前保留 `maphwo.MapsActivity` 為 `out_of_scope`（沿用既有政策）。

