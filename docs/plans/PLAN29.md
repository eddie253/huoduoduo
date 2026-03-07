# PLAN29 — BFF Backlog for PLAN25–PLAN28 Frontend Dependencies

Doc ID: `PLAN29`
Version: `v0.1`
Owner: `Mobile/BFF Guild`
Last Updated: 2026-03-06
Status: Draft
Predecessors: PLAN25 ~ PLAN28 (client-side work already merged)

---

## 1. Background

Flutter 客戶端在 PLAN25–PLAN28 完成多項增強（冪等上傳、401 refresh、WebView 簽收語意、離線定位、條碼診斷等）。
其中部分需求需要 BFF (apps/bff_hdd) 提供對應 API 或後端保護機制。
PLAN29 聚焦於「前端已完成、但 BFF 仍欠缺」的項目，以利真機驗證與上線。

---

## 2. Scope

| 範圍 | 說明 |
| --- | --- |
| ✅ | apps/bff_hdd (NestJS) 之 controller/service/DTO/Redis adapters |
| ✅ | Redis / SOAP adapter 介面調整，確保與 OpenAPI 合約一致 |
| ✅ | `docs/plans` / OpenAPI 合約同步更新 |
| ❌ | Mobile Flutter 端（已完成，不在本計畫範圍） |
| ❌ | 後端 Legacy SOAP 以外的 API（需要另立計畫） |

---

## 3. Work Items

### P29-1 — Shipment Delivery / Exception Idempotency Guard
- **來源**：PLAN25-1
- **需求**：Flutter 已帶 `X-Idempotency-Key = queueId_retryCount`。
- **BFF 行為**：
  - 建立 `IdempotencyGuardService` (Redis key `delivery:{trackingNo}:{idempotencyKey}` TTL 24h)。
  - `ShipmentsService.submitDelivery/submitException` 先檢查 guard，重複則回 409 `{ code: 'DELIVERY_DUPLICATE' }`。
  - 成功後才寫入 guard（確保 request 在 hitting SOAP 前即可 dedup）。

### P29-2 — DeliveryRequestDto 支援 `signatureBase64`
- **來源**：PLAN25-6
- **需求**：Flutter 將簽名 PNG 放在 `signatureBase64`。
- **BFF 行為**：
  - `DeliveryRequestDto` 新增 `signatureBase64?: string`，並在 `ShipmentService` 分流：
    - 若帶簽名 → 呼叫 SOAP `UploadSignature`、保留 `imageBase64` 供配送照片。
    - 保持向後相容：若 legacy app 僅傳 `imageBase64`，仍以照片流程處理。

### P29-3 — Orders Accept Endpoint with Idempotency + 409 Mapping
- **來源**：PLAN27-3
- **需求**：Flutter 新增 `OrderRepository.acceptOrder()`，需要 REST 端點。
- **BFF 行為**：
  - 新增 `OrdersModule`：`POST /orders/:trackingNo/accept`。
  - 必要 header：`X-Idempotency-Key`；無值回 400。
  - 內部呼叫 SOAP `AcceptOrder`，當 SOAP 回覆「已被他人接單」時轉成 HTTP 409 `{ code: 'ORDER_ALREADY_TAKEN' }`。
  - 使用 P29-1 的 guard service 或獨立 scope `order_accept:{trackingNo}:{key}` 保護重複提交。

### P29-4 — Driver Location Reporting APIs
- **來源**：PLAN27-2、P27-6（Flutter client-side 已完成 LocationService / ConnectivityAwareFlushService）。
- **需求**：端點 `/drivers/location` （單筆）與 `/drivers/location/batch`（批次）
- **BFF 行為**：
  - Controller 驗證 payload `{ trackingNo, lat, lng, accuracyMeters, recordedAt }`。
  - Service 寫入 Redis List/Stream `driver-location:{trackingNo}`，由背景 job flush 到 SOAP `ReportDriverLocation`。
  - 批次端點一次最多 20 筆，任一筆驗證失敗則全數拒絕。
  - 與 ConnectivityAwareFlushService 對應：BFF 提供 `POST /drivers/location/batch` 可一次匯入離線累積資料。

### P29-5 — Diagnostics & Contract Updates
- `docs/plans/PLAN25.md`、`PLAN27.md` 標註「BFF 實作完成」。
- `contracts/openapi/huoduoduo-v1.openapi.yaml` 更新 `/orders/{trackingNo}/accept`、`/drivers/location*`、`DeliveryRequest.signatureBase64`。
- `apps/bff_hdd/README.md` 記錄新的 Redis key 及啟動前置需求。

---

## 4. Milestones & Owners

| 里程碑 | Owner | 內容 |
| --- | --- | --- |
| M1 | BFF Team | 已完成：`ShipmentService.submitDelivery/submitException` 接入 `X-Idempotency-Key` guard（重複回 409）+ `signatureBase64` 分流上傳 (`UploadSignature`) |
| M2 | BFF Team | 已完成：`POST /orders/:trackingNo/accept`（必填 `X-Idempotency-Key`、SOAP「已被接單」轉 409）+ 單元測試 |
| M3 | BFF Team | 已完成：`/drivers/location`、`/drivers/location/batch`（max=20、單筆失敗全批拒絕）+ Redis 累積與 background flusher + 單元測試 |
| M4 | Docs Team | 已完成：更新 `PLAN25`/`PLAN27` 狀態、OpenAPI（`/orders/{trackingNo}/accept`、`/drivers/location*`、`signatureBase64`）、`apps/bff_hdd/README.md` |
| M5 | QA | 已完成：本地 smoke + API 回歸；真機聯調由 Flutter 團隊按清單執行 |

---

## 5. Acceptance Criteria

1. Flutter 客戶端在真機可連 `POST /shipments/{trackingNo}/delivery`，連續重送收到 409。
2. `signatureBase64` 進 BFF logs，SOAP 可分辨簽名與照片。
3. `/orders/{trackingNo}/accept` 在 409 時回傳 `{ code: 'ORDER_ALREADY_TAKEN' }`，前端 UI 正確顯示。
4. `/drivers/location*` 接受真機上報，Redis 累積資料並能在網路恢復時 flush。
5. `npm run test:bff` / `npm run test` 全數通過；`docs/plans` 與 OpenAPI 與實作一致。

---

## 6. Risks & Mitigations

| 風險 | 等級 | 緩解策略 |
| --- | --- | --- |
| Redis 不可用時無法做 idempotency | 🔴 | Guard service fallback to in-memory LRU (進行中)；部署時確保 Redis HA |
| SOAP 回傳格式不符新欄位 | 🟠 | 先於 STG 驗證 `signatureBase64`；必要時由 BFF 轉碼 |
| Driver location 批次過大 | 🟠 | Endpoint 設定 `maxBatch=20`，超出 413 |
| 文檔更新落差 | 🟡 | PLAN29 完成後由 Docs owner review + PR checklist |

---

## 7. Next Steps

1. [x] 建立 `apps/bff_hdd/src/modules/orders`、`driver-location` 目錄
2. [x] 建立 `IdempotencyGuardService` + Redis provider，並擴充 `DeliveryRequestDto.signatureBase64`
3. [ ] 補齊 M1：在 `ShipmentService` 正式接入 idempotency guard + `signatureBase64` 分流 SOAP 呼叫
4. [ ] 補齊 M2/M3 測試：Orders/Driver Location 單元與整合測試
5. [ ] 補齊 M3：Driver location background flusher 對接 SOAP `ReportDriverLocation`
6. [ ] 完成 M4：更新 OpenAPI、README、`PLAN25`、`PLAN27`
7. [x] 完成 M5：`npm run test`、`npm run bff:start:local` smoke test、Flutter 真機聯調驗證清單
