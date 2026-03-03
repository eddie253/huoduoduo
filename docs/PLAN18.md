# PLAN18：Flutter 單元測試補齊與 Coverage 一次提升到 65%

## Summary
1. 目標：以 `Flutter 優先` 方式，把行覆蓋率從目前 `58.00% (953/1643)` 一次拉升到 `>=65%`，並同步把本機與 CI gate 門檻改為 `65`。  
2. 策略：先補低覆蓋且可快速落地的單元測試，再對 `webview_shell` 做最小可測性重構，避免只靠門檻調整。  
3. 限制：不改業務行為、不調降門檻、不延後 gate；本輪不擴到 BFF 補測。  

## Scope
1. 僅處理 `apps/mobile_flutter` 測試與必要可測性重構。  
2. 更新 Flutter coverage gate（`package.json`、`.github/workflows/ci.yml`、coverage policy 文件）。  
3. 產出 `docs/plans/PLAN18.md` 與對應 evidence 更新。  

## Out Of Scope
1. BFF 測試擴充與 BFF coverage 門檻調整。  
2. 新功能開發或 UI 視覺調整。  
3. 任何 `maphwo` legacy native parity 擴 scope。  

## Current Baseline (Exploration Facts)
1. Flutter line coverage：`58.00% (953/1643)`。  
2. 主要低覆蓋檔案：`webview_shell_page.dart 1.75%`、`scanner_page.dart 0%`、`signature_page.dart 1.85%`、`maps_page.dart 1.89%`、`notifications_page.dart 7.14%`、`map_navigation_preflight_service.dart 39.22%`。  
3. 目前 gate：root script 與 CI workflow 都使用 `50`。  

## Public API / Interface / Type Changes
1. 對外 API：無變更。  
2. 內部介面：新增或抽出可測試元件（最小重構，不改行為）。  
3. CI 介面：Flutter coverage gate 由 `50` 調整為 `65`。  

## Implementation Plan

### M18-A：Baseline Freeze 與目標鎖定
1. 固定 baseline 命令與數值：`npm run mobile:test:coverage`、`npm run mobile:coverage:check`。  
2. 產出低覆蓋 Top 清單並寫入 PLAN18 的「Before」區段。  
3. 設定本輪硬目標：`>=65%`，不得以降門檻作為完成條件。  

### M18-B：低覆蓋頁面補測（先拿高性價比行數）
1. 新增 `apps/mobile_flutter/test/features/notifications/presentation/notifications_page_test.dart`。  
2. 新增 `apps/mobile_flutter/test/features/maps/presentation/maps_page_test.dart`，覆蓋座標驗證、preflight block、launcher fail、dial 分支。  
3. 新增 `apps/mobile_flutter/test/features/signature/presentation/signature_page_test.dart`，覆蓋空簽名、存檔成功、存檔失敗、saving 狀態切換。  
4. 新增 `apps/mobile_flutter/test/features/scanner/presentation/scanner_page_test.dart`，覆蓋 close 流程、scanType 顯示、完成只 pop 一次。  

### M18-C：WebView Shell 最小可測性重構
1. 從 `webview_shell_page.dart` 抽出純邏輯 helper（allowlist/external-launch 判定、map launch 前置判斷、錯誤訊息決策）。  
2. 新增對應單元測試檔，覆蓋 host/scheme allow-block、map launch preflight fail、external launch routing。  
3. 保持 `webview_shell_page.dart` 行為不變，只做可測試切分。  

### M18-D：Map Preflight 分支補全
1. 擴充 `map_navigation_preflight_service_test.dart` 覆蓋所有阻擋原因與例外分支。  
2. 必測分支：location service off、permission denied/permanently denied、maps unavailable、google account missing、google account unknown、platform exception。  
3. 目標：`map_navigation_preflight_service.dart` 行覆蓋率提升到 `>=85%`。  

### M18-E：既有高價值測試擴充
1. 擴充 `js_bridge_service_test.dart` 的 map 相關錯誤碼與訊息一致性檢查。  
2. 新增或擴充 router 測試，覆蓋 `/scanner` extra 解析、`/webview` bootstrap 有/無、`/settings` 與 `/maps` route 可達性。  
3. 確保新增測試不依賴真機硬體。  

### M18-F：Coverage Gate 一次上調到 65
1. 更新 root `package.json`：`mobile:coverage:check` 門檻改為 `65`。  
2. 更新 `.github/workflows/ci.yml` 的 Flutter coverage check 參數為 `65`。  
3. 更新 `docs/architecture/COVERAGE_POLICY.md` 的 Flutter baseline gate 文字為 `>=65`。  

### M18-G：文件與證據閉環
1. 新增 `docs/plans/PLAN18.md`（含 before/after、模組補測清單、風險與結論）。  
2. 更新 `docs/architecture/WAVE3_WAVE4_FOUNDATION_EVIDENCE.md` 的 Flutter coverage 區段。  
3. 若有測試策略調整，更新 `docs/architecture/TESTING_STRATEGY_MONOREPO.md` 與 `apps/mobile_flutter/README.md` 對應命令描述。  

## Test Cases And Scenarios
1. Scanner：空值不完成、有效碼只 pop 一次、close 按鈕返回。  
2. Signature：未簽名提示、PNG bytes 為空錯誤、寫檔成功返回 payload、寫檔失敗提示。  
3. Maps：非法經緯度阻擋、preflight fail 提示、launch fail 提示、dial 號碼驗證。  
4. WebView shell helper：allowlist host、external scheme、map 前置檢查失敗時錯誤狀態。  
5. Map preflight service：所有 block reason 與 exception path。  
6. Router：`/webview` bootstrap guard、`/scanner` extra、settings/maps route。  

## Final Gate (PLAN18 Completion Criteria)
1. `flutter analyze`：PASS。  
2. `flutter test`：PASS。  
3. `npm run mobile:test:coverage`：PASS。  
4. `npm run mobile:coverage:check`（65）：PASS。  
5. `npm run coverage:verify`：PASS（不得因 Flutter gate 失敗）。  
6. CI `mobile_flutter` job：PASS（coverage threshold 65）。  

## Assumptions And Defaults
1. 覆蓋率目標：`65%`（已鎖定）。  
2. 範圍：`Flutter 優先`（BFF 不納入 PLAN18 補測範圍）。  
3. 門檻策略：`一次升到 65`（不採分階段）。  
4. 可測性重構：允許「最小重構，不改行為」。  
5. 若最終覆蓋率不足，僅允許補測或增加可測性切分；不允許降門檻。  
