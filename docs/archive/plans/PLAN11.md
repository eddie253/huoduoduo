# PLAN11：登入會面 1:1 行為對齊 + 現代化 UI（不改契約）

Doc ID: HDD-DOCS-ARCHIVE-PLANS-PLAN11
Version: v1.0
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: Archived
CN/EN Pair Link: N/A






## 1. 摘要

1. 目標：把 Flutter 登入流程做到「行為比照舊版 1:1」，同時把 UI 現代化。
2. 原則：`行為不變、視覺可升級`。
3. 範圍：只做登入會面與相關 session 行為，不擴到新 API 或 legacy 契約修改。

## 2. 目前基線（輸入）

1. BFF `/v1/auth/*`、`/v1/bootstrap/webview` 已可用。
2. WebView cookie 注入流程已存在（`Account/Identify/Kind`）。
3. Flutter 目前可 build/test/analyze。
4. 主要缺口：登入頁 UI 還偏基礎，缺完整 1:1 驗收對照與證據。

## 3. 目標與邊界

### 3.1 必達目標

1. 登入相關行為對齊舊版（成功/失敗/續期/登出/回到前景/重啟恢復）。
2. UI 現代化但不改動登入語意與流程。
3. 建立可重跑的 parity checklist 與驗收證據。

### 3.2 非目標

1. 不新增 BFF 路由。
2. 不更改 SOAP 介面。
3. 不在本輪導入新身份體系（OIDC 等）。

## 4. 公開 API / 介面 / 型別變更

1. 對外 API：不變（維持 `/v1` 與 OpenAPI 現況）。
2. App 內部：可新增 ViewModel/UI state，但不更動 `LoginRequest/LoginResponse` 契約。
3. Session 清理規則維持現況：logout 清 token + cookie + web storage + cache。

## 5. 1:1 行為對照清單（定版）

1. `LOGIN_SUCCESS`：帳密正確後進入 webview 主入口。
2. `LOGIN_FAILURE_INVALID_CREDENTIAL`：顯示與舊版同語意錯誤，不暴露內部例外。
3. `SESSION_COOKIE_SET`：`Account/Identify/Kind` 三個 cookie 必存在。
4. `APP_RESTART_SESSION_RESTORE`：token/cookie 未過期時重啟可直接回可用狀態。
5. `FOREGROUND_BACKGROUND_PRESERVE`：前後景切換不強制重登。
6. `REFRESH_ROTATION`：refresh 成功後舊 token 重放失敗。
7. `LOGOUT_HARD_CLEAR`：登出後必須重新登入，不能殘留 web session。
8. `UNAUTHORIZED_REDIRECT`：401 或缺 token 時回登入。
9. `NON_ALLOWLIST_BLOCK`：非白名單導頁直接阻擋。
10. `NO_SENSITIVE_LOCAL_STORAGE`：不得把 token/password 寫入 SQLite。

## 6. UI 現代化規範（不改行為）

1. 表單：卡片式容器、清楚 label、密碼顯示切換、loading 狀態。
2. 錯誤提示：統一 toast/snackbar 風格，文字對應錯誤碼語意。
3. 互動：按鈕 disabled/loading、鍵盤 focus 流程與 submit 鍵。
4. 視覺一致：沿用現有主色系，避免破壞整體導覽樣式。

## 7. 實作步驟（檔案級）

## M11-A（0.5 天）：行為對照與驗收框架

1. 新增驗收文件：`docs/architecture/LOGIN_SESSION_PARITY_CHECKLIST.md`。
2. 每個 1:1 項目定義：前置條件、步驟、預期結果、證據欄位。

## M11-B（1 天）：登入頁 UI 現代化

1. 調整 `apps/mobile_flutter/lib/features/auth/presentation/login_page.dart`。
2. 引入：
1. password reveal toggle
2. submit loading/disabled
3. 輸入驗證（空值/格式）
4. 保持 `authController.login` 呼叫參數與流程不變。

## M11-C（0.5 天）：錯誤碼顯示與文案一致化

1. 調整 `apps/mobile_flutter/lib/features/auth/application/auth_controller.dart`。
2. 將常見錯誤碼映射成固定文案（例如 `LEGACY_TIMEOUT`, `LEGACY_BUSINESS_ERROR`）。
3. 避免把內部 stack/exception 原樣顯示給使用者。

## M11-D（0.5 天）：Session 流程回歸補強

1. 補測試於：
1. `apps/mobile_flutter/test/features/auth/`（新增）
2. `apps/mobile_flutter/test/features/webview_shell/`（必要回歸）
2. 覆蓋：
1. login 成功/失敗
2. logout 清理流程
3. unauthorized 回登入路徑

## M11-E（0.5 天）：文件與證據收斂

1. 更新 `docs/architecture/WAVE3_WAVE4_FOUNDATION_EVIDENCE.md` 新增 PLAN11 區段。
2. 記錄 Android 實機 smoke 證據（遮罩帳密/token）。
3. iOS 保持 Mac gate：只補操作說明與待驗項。

## 8. 測試案例與驗收情境

### 8.1 自動化

1. `flutter analyze` 綠燈。
2. `flutter test` 綠燈（含 auth + session 新測試）。
3. `flutter build apk --debug` 綠燈。
4. `npm run bff:verify` 維持綠燈（防止後端回歸）。

### 8.2 手動 smoke（Android）

1. 正確帳密登入 -> webview。
2. 錯誤帳密 -> 正確錯誤文案。
3. 前後景切換 -> session 持續。
4. logout -> 再進 app 需重登。
5. 非白名單導頁 -> blocked。

### 8.3 iOS Gate（Mac）

1. `flutter build ios --no-codesign`。
2. 同一份 1:1 checklist 跑一輪。

## 9. 工期與完成定義

1. 工期：`3 ~ 4` 個工作天。
2. 完成定義：
1. 1:1 checklist 全部 `PASS` 或有明確 `WAIVE`。
2. `0 blocker`。
3. UI 現代化完成且不改行為契約。

## 10. 明確假設與預設

1. 不改 BFF/legacy SOAP 契約。
2. 既有 token/cookie 策略維持不變。
3. 本輪以 Android 先驗，iOS 在 Mac 補驗。
4. `.env`/憑證仍維持本機與 CI secret，不進版控。

## Governance Waiver

- Reason: historical document retained for traceability under archive_waiver policy.
- Owner: Architecture Lead
- Original Date: N/A
- Retention: long-term archive retention.
- Reactivation Trigger: audit or historical trace request.

