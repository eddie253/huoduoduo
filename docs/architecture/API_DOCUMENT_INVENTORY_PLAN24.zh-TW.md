# PLAN24 API 文件盤點（中文版）

Doc ID: `HDD-PLAN24-API-INVENTORY`
Version: `v1.4`
Owner: `Architecture Lead`
Last Updated: 2026-03-05
Review Status: In Review
CN/EN Pair Link: docs/architecture/API_DOCUMENT_INVENTORY_PLAN24.en.md






1. CN: `docs/architecture/API_DOCUMENT_INVENTORY_PLAN24.zh-TW.md`
2. EN: `docs/architecture/API_DOCUMENT_INVENTORY_PLAN24.en.md`

日期：2026-03-03（Asia/Taipei）

## 1. 盤點範圍
1. API 規格與契約文件（OpenAPI、REST<->SOAP mapping、錯誤碼 mapping、驗證清單）。
2. 舊 APK API 來源（`app/src/main/java/network/*.java`）與現行 mapping 的核對。
3. 文件治理需求（中英文雙語、版本/owner/更新歷程/審核軌跡）。

## 2. 現有 API 文件清單

| 文件 | 路徑 | 語言 | 用途 | 治理狀態 |
|---|---|---|---|---|
| OpenAPI 規格 | `contracts/openapi/huoduoduo-v1.openapi.yaml` | English（機器契約） | REST source of truth | 已加治理 metadata + 長度規格（`0.2.5`） |
| OpenAPI 導讀（中文） | `docs/architecture/API_SPEC_OPENAPI_PLAN24.zh-TW.md` | 中文 | 給審核者閱讀的契約摘要 | 新增 |
| OpenAPI 導讀（英文） | `docs/architecture/API_SPEC_OPENAPI_PLAN24.en.md` | 英文 | 英文對照版本 | 新增 |
| Legacy SOAP 對照 | `contracts/legacy/soap-mapping-v1.md` | 英文相容版 | 基準映射入口 | 已補治理標頭 |
| Legacy SOAP 對照（CN/EN） | `contracts/legacy/soap-mapping-v1.zh-TW.md` / `.en.md` | 中英雙語 | 正式審核版本 | 新增 |
| 錯誤碼對照（CN/EN） | `contracts/legacy/error-code-mapping-v1.zh-TW.md` / `.en.md` | 中英雙語 | 錯誤碼與超限策略 | 新增 |
| 合約驗證清單（CN/EN） | `docs/architecture/CONTRACT_VERIFICATION_CHECKLIST.zh-TW.md` / `.en.md` | 中英雙語 | CI 與驗證 gate | 新增 |
| 舊 APP API 規格（CN/EN） | `docs/architecture/LEGACY_APP_API_SPEC_FINAL.zh-TW.md` / `.en.md` | 中英雙語 | 舊 APK API 成品規格 | 已有 |
| 舊 API 42 狀態矩陣（CN/EN） | `docs/architecture/LEGACY_API_42_STATUS_MATRIX_20260303.zh-TW.md` / `.en.md` | 中英雙語 | 42 method 治理狀態 | 已更新欄位規則 |

## 3. 治理檢查結果
1. 文件標頭欄位：`Doc ID/Version/Owner/Last Updated/Review Status/CN-EN Pair Link` 已納入核心文件。
2. 雙語覆蓋：P0 核心 API 文件已具備 CN/EN 對照。
3. 欄位長度治理：OpenAPI 已加入 `maxLength/maxItems` 基線。
4. 42 method 狀態治理：全部都有狀態與責任欄位，不留 `unknown`。

## 4. 舊 API 核對結論
1. 舊 Android `network` 模組共有 42 個 SOAP methods。
2. 所有 SOAP 皆呼叫 `https://old.huoduoduo.com.tw/Inquiry/didiservice.asmx`。
3. P0 階段將 42 支方法全數分流到 `implemented/waived/deferred`，並補上 `reason/owner/target milestone`。

## 5. P1 補充狀態
1. `Auth/Bootstrap/Push` 已完成 request/response 契約 enforcement。
2. 超限策略已依 P0 規則落地（關鍵欄位 reject、訊息欄位 truncate）。

## 6. P2 補充狀態
1. Shipment API 已完成回傳欄位契約 enforcement。
2. delivery/exception request 已加上長度驗證，超長回 `400`。

## 7. P3 補充狀態
1. Reservation API 已完成回傳欄位契約 enforcement 與 `maxItems` 驗證。
2. reservation create/delete request 已加上長度驗證，超長回 `400`。

## 8. P0 交付建議
1. 主管審閱以中文文件為主，英文做對照與跨團隊同步。
2. 任一文件變更時，中英版需同版次同步更新。
3. P1 開工前，先依 `CONTRACT_VERIFICATION_CHECKLIST` 再跑一次 gate 並附 log。

