# PLAN24 分階段 API 治理規格（P0~P4）

Doc ID: `HDD-PLAN24-PHASED-GOV`
Version: `v1.4`
Owner: `Architecture Lead`
Last Updated: `2026-03-03`
Review Status: `Draft for management review`
CN/EN Pair Link:
1. CN: `docs/architecture/PLAN24_PHASED_API_GOVERNANCE_SPEC.zh-TW.md`
2. EN: `docs/architecture/PLAN24_PHASED_API_GOVERNANCE_SPEC.en.md`

日期：2026-03-03（Asia/Taipei）
用途：先完成文件交付與治理對齊，再進入實作。

## 1. 說明
1. 本文件定義 PLAN24 的 P0~P4 階段化治理框架。
2. 每個階段都包含：
   1. 要對照的文件
   2. 後端回傳欄位長度規格（合約標準）
3. 長度規格落地位置：
   1. OpenAPI `maxLength/maxItems`
   2. BFF normalization（truncate/reject）
   3. 測試驗證

## 2. P0：基線凍結與文件治理框架

### 2.1 P0 對照文件
1. `contracts/openapi/huoduoduo-v1.openapi.yaml`
2. `contracts/legacy/soap-mapping-v1.md`
3. `contracts/legacy/error-code-mapping-v1.md`
4. `docs/architecture/LEGACY_APP_API_SPEC_FINAL.zh-TW.md`
5. `docs/architecture/LEGACY_API_42_STATUS_MATRIX_20260303.zh-TW.md`
6. `docs/architecture/CONTRACT_VERIFICATION_CHECKLIST.md`

### 2.2 P0 後端回傳欄位長度（通用治理）
| 欄位型別 | 長度規範 |
|---|---|
| `UUID/ID` 類字串 | `maxLength: 64` |
| `一般代碼(code/status/role)` | `maxLength: 64` |
| `名稱(name/service)` | `maxLength: 128` |
| `訊息(message)` | `maxLength: 1024` |
| `URL` | `maxLength: 2048` |
| `檔名(fileName)` | `maxLength: 255` |
| `路徑(path)` | `maxLength: 255` |
| `座標字串(lat,lng)` | `maxLength: 64` |
| `日期時間字串(ISO8601)` | `maxLength: 40` |

## 3. P1：Auth / Bootstrap / Push 契約收斂

狀態：`implemented (2026-03-03)`

### 3.1 P1 對照文件
1. `contracts/openapi/huoduoduo-v1.openapi.yaml`
2. `apps/bff_gateway/src/modules/auth/*`
3. `apps/bff_gateway/src/modules/webview/*`
4. `apps/bff_gateway/src/modules/notification/*`
5. `contracts/legacy/soap-mapping-v1.md`

### 3.2 P1 後端回傳欄位長度
| Endpoint | 回傳欄位 | 長度規範 |
|---|---|---|
| `POST /v1/auth/login` | `accessToken` | `maxLength: 4096` |
|  | `refreshToken` | `maxLength: 1024` |
|  | `user.id` | `maxLength: 64` |
|  | `user.contractNo` | `maxLength: 64` |
|  | `user.name` | `maxLength: 128` |
|  | `user.role` | `maxLength: 32` |
|  | `webviewBootstrap.baseUrl` | `maxLength: 2048` |
|  | `webviewBootstrap.registerUrl` | `maxLength: 2048` |
|  | `webviewBootstrap.resetPasswordUrl` | `maxLength: 2048` |
|  | `webviewBootstrap.cookies[].name` | `maxLength: 64` |
|  | `webviewBootstrap.cookies[].value` | `maxLength: 4096` |
|  | `webviewBootstrap.cookies[].domain` | `maxLength: 255` |
|  | `webviewBootstrap.cookies[].path` | `maxLength: 255` |
| `POST /v1/auth/refresh` | `accessToken` | `maxLength: 4096` |
|  | `refreshToken` | `maxLength: 1024` |
| `POST /v1/auth/logout` | `subject` | `maxLength: 64` |
| `GET /v1/bootstrap/bulletin` | `message` | `maxLength: 2000` |
|  | `updatedAt` | `maxLength: 40` |
| `POST /v1/push/register` | `registeredAt` | `maxLength: 40` |

### 3.3 P1 實作備註
1. `Auth/Bootstrap/Push` request DTO 已套用長度驗證（`MaxLength`）。
2. service 層已套用超限策略：
   1. 關鍵結構欄位：reject -> `LEGACY_BAD_RESPONSE`。
   2. 顯示文字欄位：truncate（`user.name`, `bulletin.message`）。
3. OpenAPI 版本由 `0.2.2` 升級為 `0.2.3`（patch）。

## 4. P2：Shipment 回傳規格收斂

狀態：`implemented (2026-03-04)`

### 4.1 P2 對照文件
1. `contracts/openapi/huoduoduo-v1.openapi.yaml`
2. `apps/bff_gateway/src/modules/shipment/*`
3. `apps/bff_gateway/src/adapters/soap/legacy-soap.client.ts`
4. `contracts/legacy/soap-mapping-v1.md`

### 4.2 P2 後端回傳欄位長度
| Endpoint | 回傳欄位 | 長度規範 |
|---|---|---|
| `GET /v1/shipments/{trackingNo}` | `trackingNo` | `maxLength: 32` |
|  | `recipient` | `maxLength: 128` |
|  | `address` | `maxLength: 512` |
|  | `phone` | `maxLength: 32` |
|  | `mobile` | `maxLength: 32` |
|  | `zipCode` | `maxLength: 16` |
|  | `city` | `maxLength: 64` |
|  | `district` | `maxLength: 64` |
|  | `status` | `maxLength: 64` |
|  | `signedAt` | `maxLength: 40` |
|  | `signedImageFileName` | `maxLength: 255` |
|  | `signedLocation` | `maxLength: 64` |
| `POST /v1/shipments/{trackingNo}/delivery` | `ok` | `boolean` |
| `POST /v1/shipments/{trackingNo}/exception` | `ok` | `boolean` |

### 4.3 P2 實作備註
1. `ShipmentService.getShipment` 已套用回傳欄位契約 enforcement。
2. `trackingNo/contractNo` 在提交 delivery/exception 前套用長度檢查。
3. `delivery/exception` request DTO 已補上 P2 相關 `MaxLength` 驗證。
4. OpenAPI 版本更新為 `0.2.4`。

## 5. P3：Reservation 回傳規格收斂

狀態：`implemented (2026-03-04)`

### 5.1 P3 對照文件
1. `contracts/openapi/huoduoduo-v1.openapi.yaml`
2. `apps/bff_gateway/src/modules/reservation/*`
3. `contracts/legacy/soap-mapping-v1.md`
4. `docs/architecture/LEGACY_API_42_STATUS_MATRIX_20260303.zh-TW.md`

### 5.2 P3 後端回傳欄位長度
| Endpoint | 回傳欄位 | 長度規範 |
|---|---|---|
| `GET /v1/reservations` | `[].reservationNo` | `maxLength: 64` |
|  | `[].address` | `maxLength: 512` |
|  | `[].shipmentNos[]` | `maxLength(each): 64` |
|  | `[].shipmentNos` | `maxItems: 200` |
|  | `[].mode` | `maxLength: 16` (`standard|bulk`) |
| `POST /v1/reservations` | `reservationNo` | `maxLength: 64` |
|  | `mode` | `maxLength: 16` |
| `DELETE /v1/reservations/{id}` | `ok` | `boolean` |

### 5.3 P3 實作備註
1. reservation list/create response 已加上契約 enforcement（長度、`maxItems`、mode 合法值）。
2. create/delete request DTO 已補齊 `MaxLength` 與 `ArrayMaxSize`。
3. `DELETE /reservations/:id` 已改用 path param DTO 驗證（超長回 `400`）。
4. OpenAPI 版本更新為 `0.2.5`。

## 6. P4：Cross-cutting（Error/Health/驗證）

### 6.1 P4 對照文件
1. `contracts/openapi/huoduoduo-v1.openapi.yaml`
2. `contracts/legacy/error-code-mapping-v1.md`
3. `docs/architecture/CONTRACT_VERIFICATION_CHECKLIST.md`
4. `ops/ci/check-route-diff.js`
5. `ops/ci/check-error-code-map.js`

### 6.2 P4 後端回傳欄位長度
| Endpoint/Schema | 回傳欄位 | 長度規範 |
|---|---|---|
| `ErrorResponse` | `code` | `maxLength: 64` |
|  | `message` | `maxLength: 1024` |
| `GET /v1/health` | `status` | `maxLength: 32` |
|  | `service` | `maxLength: 64` |
|  | `timestamp` | `maxLength: 40` |

## 7. 開工前交付物
1. `PLAN24_PHASED_API_GOVERNANCE_SPEC.zh-TW.md`（本文件）
2. `LEGACY_APP_API_SPEC_FINAL.zh-TW.md` / `.en.md`
3. `LEGACY_API_42_STATUS_MATRIX_20260303.zh-TW.md` / `.en.md`
4. `API_DOCUMENT_INVENTORY_PLAN24.zh-TW.md` / `.en.md`
5. `CONTRACT_VERIFICATION_CHECKLIST.zh-TW.md` / `.en.md`

## 8. 開工前確認清單
1. 是否同意長度規格作為正式 OpenAPI contract？
2. `waived` 項是否維持 webview 承接、不做 BFF 新 API？
3. `implemented but unused` 是否在下一輪要求 Flutter 接線？
