# API 規格導讀（OpenAPI 基線）

Doc ID: `HDD-OPENAPI-GUIDE`
Version: `v1.3`
Owner: `BFF Lead`
Last Updated: `2026-03-03`
Review Status: `Draft for management review`
CN/EN Pair Link:
1. CN: `docs/architecture/API_SPEC_OPENAPI_PLAN24.zh-TW.md`
2. EN: `docs/architecture/API_SPEC_OPENAPI_PLAN24.en.md`

## 1. 目的
1. 說明 `contracts/openapi/huoduoduo-v1.openapi.yaml` 在 PLAN24-P0 的治理重點。
2. 幫助非開發角色快速審核 API 契約，不需直接閱讀全部 YAML。

## 2. 契約來源
1. 主檔：`contracts/openapi/huoduoduo-v1.openapi.yaml`
2. 版本：`info.version = 0.2.5`
3. P0/P1 治理 metadata：`x-doc-id/x-owner/x-last-updated/x-review-status/x-language-pair`

## 3. P0/P1/P2/P3 重點變更
1. 補齊回傳欄位長度規範：`maxLength/maxItems`。
2. 套用範圍：Health/Auth/Bootstrap/Push/Shipments/Reservations/ErrorResponse。
3. 不改 endpoint 行為，只收斂 contract。
4. P1 已落地 request/response 契約 enforcement（Auth/Bootstrap/Push）。
5. P2 已落地 shipment response 契約 enforcement 與 delivery/exception request 長度驗證。
6. P3 已落地 reservation response 契約 enforcement 與 create/delete request 長度驗證。

## 4. 欄位長度治理基線
| 類別 | 規格 |
|---|---|
| ID/code/role | `64` |
| name/service | `128` |
| message | `1024` |
| URL | `2048` |
| fileName/path | `255` |
| lat/lng | `32`（各欄位） |
| datetime | `40` |
| reservation shipmentNos | `maxItems: 200` |

## 5. 相關文件
1. `docs/architecture/PLAN24_PHASED_API_GOVERNANCE_SPEC.zh-TW.md`
2. `contracts/legacy/soap-mapping-v1.zh-TW.md`
3. `contracts/legacy/error-code-mapping-v1.zh-TW.md`
4. `docs/architecture/CONTRACT_VERIFICATION_CHECKLIST.zh-TW.md`
