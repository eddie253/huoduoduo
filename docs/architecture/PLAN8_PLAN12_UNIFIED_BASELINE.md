# PLAN8-PLAN12 收斂總表（Unified Execution Baseline）

## 1. 目的
本文件整併 PLAN8、PLAN9、PLAN10、PLAN11、PLAN12 的決策與落地狀態，作為目前唯一執行基準。

## 2. 收斂結論（先看這裡）
1. BFF 主線與 UAT 核心鏈路已可用，公開 API 契約維持 `/v1` 且未破壞。
2. Flutter Android 已達可開發、可建置、可測試狀態；登入會面已完成 1:1 行為導向對齊與 UI 現代化。
3. iOS 採 `code-first on Windows + compile/smoke on Mac`，策略不變。
4. Monorepo 測試與 coverage gate 已制度化，CI 有可執行的覆蓋率閘門與可視化報告。

## 3. PLAN8-PLAN12 里程碑狀態

### PLAN8：遺漏清單收斂 + 真機路線
狀態：`大致完成（iOS 真機仍待 Mac）`
1. Android 先行、iOS 後接的順序已落實。
2. BFF 驗證鏈 (`bff:verify`) 已可運作。
3. 真機路線已建立，但 iOS 真機驗收仍需 Mac 環境補齊。

### PLAN9：Wave 3 收斂 + Wave 4 基礎
狀態：`完成`
1. 契約可驗證與風險控制框架已建立。
2. WebView/session/cache policy 已有實作與文件基線。
3. SQLite media queue 基礎與測試骨架已接入。

### PLAN10：Wave 4 核心能力完工
狀態：`主線完成（以 Android 為主）`
1. Bridge deferred 方法與核心原生能力路徑已從 placeholder 轉為可執行。
2. Shipment queue 流程（enqueue/retry/dead-letter）已可驗證。
3. iOS 仍是 Mac gate（Windows 不做最終簽章/真機）。

### PLAN11：登入會面 1:1 對齊 + UI 現代化
狀態：`完成`
1. 登入行為不改契約，UI 已升級（保留既有品牌資產）。
2. auth/login/webview 相關測試已補強。
3. parity checklist 與 evidence 文件已建立並可迭代。

### PLAN12：Monorepo 測試與覆蓋率標準化
狀態：`完成（baseline gate）`
1. 測試策略定版：colocated tests 為主，root `tests/` 僅放跨服務測試。
2. BFF 使用 Jest `coverageProvider: v8`。
3. Flutter 使用 `flutter test --coverage` + line threshold 檢查。
4. CI 已接 coverage artifact 與 summary job。
5. 視覺化報告可用，支援 Top20/All 與 PDF 輸出。

## 4. 當前品質閘（Current Gates）
1. BFF：`npm run bff:verify`。
2. Coverage：`npm run coverage:verify`。
3. Flutter：`flutter analyze`、`flutter test`、`flutter build apk --debug`。
4. iOS：`flutter build ios --no-codesign`（Mac gate）。

## 5. 覆蓋率政策（已落地）

### BFF (Jest v8)
1. lines >= 60
2. statements >= 60
3. functions >= 60
4. branches >= 75

### Flutter (LCOV)
1. baseline gate: line >= 50
2. target ratchet: line >= 80

說明：目前採可執行 baseline gate，後續以 wave 逐步上調，不允許無理由降門檻。

## 6. 核心文件索引（Single Source of Truth）
1. `docs/architecture/WAVE3_WAVE4_FOUNDATION_EVIDENCE.md`
2. `docs/architecture/LOGIN_SESSION_PARITY_CHECKLIST.md`
3. `docs/architecture/TESTING_STRATEGY_MONOREPO.md`
4. `docs/architecture/COVERAGE_POLICY.md`
5. `contracts/openapi/huoduoduo-v1.openapi.yaml`
6. `contracts/bridge/js-bridge-v1.md`
7. `contracts/legacy/error-code-mapping-v1.md`

## 7. 待辦與風險（只保留真正未完成）

### 必做待辦
1. iOS Mac 階段：`build ios --no-codesign` + 實機 smoke 證據。
2. Android/iOS parity checklist 補齊最終簽核結果（PASS/WAIVE）。
3. Flutter 覆蓋率從 50 逐步拉升至 80 目標。

### 風險
1. iOS signing/憑證流程的不可預期延遲。
2. 原生能力在不同機型（掃碼、簽名、外跳）行為差異。
3. 覆蓋率提升過程中，若沒有分批策略會影響交付節奏。

## 8. 建議下一步（執行順序）
1. 先完成 Mac iOS compile + smoke 證據。
2. 以高風險模組優先補測（auth、webview shell、shipment queue），上調 Flutter coverage 到 50+。
3. 完成 parity matrix 最終簽核，進入下一波 release gate。

## 9. PLAN14 補充
1. 已新增 `POST_LOGIN_NATIVE_UI_INVENTORY` 與 `NATIVE_UI_PARITY_MAPPING` 作為登入後原生 UI 盤點基準。
2. `maphwo.MapsActivity` 自 PLAN14 起固定為 `out_of_scope`，不列入 parity blocker。
3. Flutter coverage baseline gate 已由 `40` 上調至 `50`，並在 CI 同步生效。
