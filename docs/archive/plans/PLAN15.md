# PLAN15：P9-P14 遺漏項收斂（只含未完成）

## Summary

1. 本計畫只收斂 P9~P14 的未完成項，已完成內容不重複列入。
2. 目前真實缺口（2026-03-02）：
   1. Flutter coverage 為 44.91%（631/1405），未達 `>=50`。
   2. `npm run coverage:verify` 失敗；BFF coverage 受 `apps/bff_gateway/src/coverage/**` 汙染造成閘門誤失敗。
   3. parity 文件仍有大量 `in_progress/deferred`，`LOGIN_SESSION_PARITY_CHECKLIST` 的 metadata 與 Final Verdict 未填。
   4. iOS Mac gate 的實機 smoke 證據未閉環。

## Scope (Unfinished Only)

1. PL13 補測與 coverage 拉升到 `>=50`。
2. P12 coverage pipeline 穩定化（排除非產品碼 coverage 汙染）。
3. P14 parity 簽核閉環（文件從「可追蹤」提升到「可簽核」）。
4. iOS Mac gate 證據補齊。
5. 證據文件同步更新為實測結果。

## Out of Scope

1. 不新增 BFF `/v1` 路由。
2. 不修改 SOAP 契約。
3. 不把 `maphwo.MapsActivity` 納入本波（維持 `out_of_scope`）。
4. 不做大型 UI 重構與新功能擴 scope。

## Public API / Interface Changes

1. 對外 API：無變更。
2. 內部介面（允許最小改動以提升可測性）：
   1. `BridgeActionExecutor` 引入可替換 launcher port（便於測 map/dial/contract/openfile 分支）。
   2. `WebviewSessionCleanupService` 引入可替換 storage/cookie port（便於測 cleanup 成功/失敗分支）。
3. coverage 設定變更（CI 與本機一致）：
   1. BFF coverage 收集明確排除 `**/coverage/**`（避免 generated report 反灌統計）。

## Implementation Plan

### M15-A：Coverage Gate Determinism（P12 殘項）

1. 修改 `apps/bff_gateway/package.json` Jest 設定：
   1. `collectCoverageFrom` 加入 `!**/coverage/**`。
   2. `coveragePathIgnorePatterns` 加入 `/coverage/`。
2. 目標：`npm run bff:test:coverage` 在乾淨與非乾淨工作目錄都穩定通過門檻。
3. 驗收：BFF coverage 不再計入 `apps/bff_gateway/src/coverage/**`。

### M15-B：Flutter 高風險補測（PL13 核心）

1. 新增/擴充測試檔：
   1. `apps/mobile_flutter/test/features/shipment/presentation/shipment_page_test.dart`
   2. `apps/mobile_flutter/test/features/webview_shell/application/bridge_action_executor_test.dart`
   3. `apps/mobile_flutter/test/features/webview_shell/application/webview_session_cleanup_service_test.dart`
   4. `apps/mobile_flutter/test/features/shipment/data/local/media_local_provider_test.dart`
2. 既有測試維持並必要擴充：
   1. `auth_controller_test.dart`
   2. `js_bridge_service_test.dart`
   3. `shipment_upload_orchestrator_test.dart`
3. 覆蓋重點（按目前低覆蓋熱點）：
   1. `webview_shell_page` 關聯流程的可測分支。
   2. `shipment_page` 表單/狀態面板/錯誤顯示分支。
   3. `bridge_action_executor` 所有 action 分支與錯誤路徑。
   4. `webview_session_cleanup_service` cleanup 全路徑。
4. 目標：Flutter line coverage `>=50`（建議達到 `>=52` 留緩衝）。

### M15-C：Parity 文件簽核閉環（P14 殘項）

1. 更新 `docs/architecture/LOGIN_SESSION_PARITY_CHECKLIST.md`：
   1. 補齊 metadata（Date/Env/App build/BFF commit/Tester）。
   2. 補齊 Final Verdict（pass rate/blocker/waive/go-no-go）。
2. 更新 `docs/architecture/NATIVE_UI_PARITY_MAPPING.md`：
   1. 目前 `in_progress` 項逐條收斂為 `done` 或 `deferred(含 owner + target wave)`。
   2. `maphwo.MapsActivity` 維持 `out_of_scope`。
3. 更新 `docs/architecture/WAVE4_NATIVE_PARITY_MATRIX.md`：
   1. deferred 項補 owner/risk/target wave（對齊其 Acceptance 規定）。

### M15-D：iOS Mac Gate 證據補齊

1. 在 Mac 環境執行：
   1. `npm run mobile:build:ios:nocodesign`
   2. 依 checklist 跑一輪 iOS smoke（最少 login/session/logout/unauthorized/mapgoogle flow）。
2. 將結果回填至：
   1. `LOGIN_SESSION_PARITY_CHECKLIST.md`
   2. `WAVE3_WAVE4_FOUNDATION_EVIDENCE.md`

### M15-E：證據與基線同步

1. 更新 `docs/architecture/WAVE3_WAVE4_FOUNDATION_EVIDENCE.md`：
   1. `Updated at`、`Commit baseline`、最新 command 實測結果。
   2. 替換舊 coverage 數字為新實測值（含 before/after）。
   3. 新增明確 `PLAN15` 區段（補齊 PL13 收尾）。
2. 更新 `docs/architecture/PLAN8_PLAN12_UNIFIED_BASELINE.md`：
   1. 在「必做待辦」移除已關閉項，只保留仍未完成項。
   2. 補連結至 `docs/plans/PLAN15.md`。

### M15-F：最終 Gate

1. 必須全部綠燈：

   1. [X] npm run bff:verify
   2. [X] npm run bff:test:coverage
   3. [X] npm run mobile:analyze
   4. [X] npm run mobile:test
   5. [X] npm run mobile:build:apk:debug
   6. [X] npm run mobile:test:coverage
   7. [X] `npm run mobile:coverage:check`（`>=50`）
   8. [X] `npm run coverage:verify`
   9. [X] `npm run coverage:html`（產生測試覆蓋率 HTML 報表）
2. 任一失敗即不得標記 PLAN15 完成。

## Test Cases and Scenarios

1. Auth：
   1. login success/failure message mapping
   2. logout cleanup with/without refresh token
   3. secure storage error handling
2. WebView shell：
   1. allowlist block + runtime error branches
   2. APPEvent map/dial/close/contract branches
   3. session cleanup success/failure branches
3. Shipment：
   1. enqueue -> upload success
   2. fail -> retry increment
   3. retry exceed -> dead_letter
   4. startup maintenance conversion
   5. sensitive metadata reject
4. Parity：
   1. checklist 10 項完整填證據
   2. Screen ID 對照可追溯到 mapping 狀態

## Deliverables

1. `docs/plans/PLAN15.md`（本計畫文件，僅未完成項）。
2. 更新後 architecture 證據文件與 parity 文件。
3. 綠燈 gate 截圖/日誌摘要（遮罩敏感資訊）。

## Assumptions and Defaults

1. 採「最小改動」策略：允許少量可測性重構，不做大改。
2. `maphwo` 持續 `out_of_scope`，不作 blocker。
3. 覆蓋率門檻維持：BFF `60/75/60/60`、Flutter `>=50`。
4. 所有帳密/token/個資一律遮罩，不進版控。
