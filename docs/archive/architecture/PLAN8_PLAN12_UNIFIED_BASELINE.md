# PLAN8-PLAN12 收斂總表（Unified Execution Baseline）

## 1. 目的
本文件整併 PLAN8~PLAN12 決策，並同步 PLAN15/PLAN16 之後的最新落地狀態，作為單一執行基準。

## 2. 收斂結論
1. BFF 主線與 UAT 核心鏈路維持可用，公開 API 契約維持 `/v1` 且未破壞。
2. Flutter Android 維持可建置、可測試、可覆蓋率驗證狀態。
3. Coverage gate 已可重現且穩定（BFF 汙染已排除、Flutter `>=50` 已達成）。
4. parity 文件已從「追蹤」收斂到「可簽核（含 WAIVE）」。
5. PLAN16 已完成：底部分頁返回一致性 + 設定入口 + 6 色主題與暗黑模式。

## 3. PLAN8-PLAN12 里程碑狀態

### PLAN8：遺漏清單收斂 + 真機路線
狀態：`完成（iOS Mac 真機另列跨波次 gate）`

### PLAN9：Wave 3 收斂 + Wave 4 基礎
狀態：`完成`

### PLAN10：Wave 4 核心能力完工
狀態：`完成（Android 主線）`

### PLAN11：登入會面 1:1 對齊 + UI 現代化
狀態：`完成`

### PLAN12：Monorepo 測試與覆蓋率標準化
狀態：`完成`

### PLAN15（補充）
狀態：`完成（P9-P14 遺漏項收斂）`
1. 參考：`docs/plans/PLAN15.md`

### PLAN16（補充）
狀態：`完成（UI/Navigation/Theme 收斂）`
1. 參考：`docs/plans/PLAN16.md`

## 4. 當前品質閘（Current Gates）
1. BFF：`npm run bff:verify`、`npm run bff:test:coverage`
2. Coverage：`npm run coverage:verify`
3. Flutter：`npm run mobile:analyze`、`npm run mobile:test`、`npm run mobile:build:apk:debug`
4. iOS：`npm run mobile:build:ios:nocodesign`（Mac gate）

## 5. 覆蓋率政策（已落地）

### BFF (Jest v8)
1. lines >= 60
2. statements >= 60
3. functions >= 60
4. branches >= 75

### Flutter (LCOV)
1. baseline gate: line >= 50
2. target ratchet: line >= 80

## 6. 核心文件索引（Single Source of Truth）
1. `docs/architecture/WAVE3_WAVE4_FOUNDATION_EVIDENCE.md`
2. `docs/architecture/LOGIN_SESSION_PARITY_CHECKLIST.md`
3. `docs/architecture/NATIVE_UI_PARITY_MAPPING.md`
4. `docs/architecture/WAVE4_NATIVE_PARITY_MATRIX.md`
5. `docs/architecture/COVERAGE_POLICY.md`
6. `docs/plans/PLAN15.md`
7. `docs/plans/PLAN16.md`
8. `contracts/openapi/huoduoduo-v1.openapi.yaml`
9. `contracts/bridge/js-bridge-v1.md`
10. `contracts/legacy/error-code-mapping-v1.md`

## 7. 仍未完成（只保留真實未完成）

### 必做待辦
1. iOS Mac 階段：`npm run mobile:build:ios:nocodesign` + iOS 實機 smoke 證據。
2. iOS parity checklist 補齊最終簽核結果（PASS/WAIVE）。
3. Flutter 覆蓋率由 `58.07%` 持續 ratchet 到 `80%` 目標。

### 風險
1. iOS signing/憑證流程的不可預期延遲。
2. 原生能力在不同機型（掃碼、簽名、外跳）行為差異。

## 8. 建議下一步（執行順序）
1. 完成 Mac iOS compile + smoke 證據。
2. 完成 iOS parity checklist 最終簽核。
3. 持續以高風險模組優先補測，逐波上調 Flutter coverage。

## 9. 固定政策
1. `maphwo.MapsActivity` 固定為 `out_of_scope`，不列入 parity blocker。
2. 若需暫時降 coverage 門檻，必須有 owner、到期日、風險簽核。
