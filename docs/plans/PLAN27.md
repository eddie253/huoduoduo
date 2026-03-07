# PLAN27 — 可靠性與定位修正計畫

> BFF 對應狀態：`PLAN29` 已完成 `/orders/{trackingNo}/accept`、`/drivers/location`、`/drivers/location/batch` 與 409/idempotency 映射。

## 問題對照：舊 APP vs. 新 APP

| # | 問題描述 | 舊 APP | 新 APP 現況 | 根本原因 |
|---|---------|--------|------------|---------|
| A | 網路斷線後本地顯示完成，後端未收到 | 無離線佇列，直接失敗 | 媒體上傳有離線佇列，但 UI 狀態語意不清，`signature_queued` 送出後 WebView 仍可能自行顯示「完成」 | Flutter ↔ WebView 狀態語意未對齊；WebView JS 未等待 `onSignatureConfirmed` 才更新 UI |
| B | 接單成功但後端未收到 | WebView 直接呼叫後端，無 idempotency | WebView 接單流程未受 Flutter bridge 管控，沒有 idempotency key | 接單 API 呼叫全在 WebView 內，Flutter 層無感知 |
| C | 導航 App 切出再切回，任務頁狀態錯亂 | 無任何恢復機制 | P26-4（stale reload）+ P26-8（lifecycle maintenance）已改善，但 WebView 活躍任務頁並未強制重新驗證後端狀態 | 切回後僅重載靜態頁面，未拉取後端最新任務狀態 |
| D | 一筆訂單被多位司機接單 | 無 client 層防護 | 無 client 層防護 | 後端需原子鎖（Pessimistic Lock）；client 端需正確處理 409 Conflict 並顯示「訂單已被接走」 |
| E | 多扣押金 | 同上 | 同上 | D 的連鎖效應；client 需對 409 做不重試處理（non-retryable error code） |
| F | 定位不準確 | 直接使用手動輸入或單次 GPS | 定位以字串傳入，無精度篩選 | 缺少 `LocationService`，未過濾精度差的 GPS 讀值（accuracy > 50m） |
| G | 司機配送中未將定位回傳公司 | 無定位回傳機制 | 無定位回傳機制 | 缺少週期性定位心跳服務 |

---

## 實作步驟

### P27-1 — LocationService：精度閾值 + 統一定位 Provider
**目標**：建立單一 `LocationService`，所有需要 GPS 的功能都透過它取值，並確保只回傳精度 ≤ 50m 的讀值。

**新增**
- `lib/core/location/location_service.dart`
  - `LocationResult { double lat, lng, accuracy, DateTime timestamp }`
  - `Future<LocationResult> getCurrentLocation({ Duration timeout = 10s, double maxAccuracyMeters = 50.0 })`
  - 逾時後回傳精度最佳的快取值（即使超過閾值），並於 `LocationResult` 中標記 `isBelowAccuracyThreshold`
  - 底層使用 `geolocator` package（`LocationAccuracy.high`）

**修改**
- `ShipmentPage`：移除手動輸入經緯度欄位，改呼叫 `LocationService`
- `_attemptUpload`（orchestrator）：metadata 中額外存 `accuracyMeters` 欄位
- `pubspec.yaml`：加入 `geolocator: ^13.x`

**測試**
- `LocationService` unit test：mock `geolocator`，驗證精度過高時等待重試，逾時後回傳最佳快取值

---

### P27-2 — DeliveryLocationReporter：配送中週期性定位心跳
**目標**：司機進行活躍配送時，每 30 秒向後端 `POST /drivers/location` 回報定位；網路斷線時排隊，恢復後補傳。

**新增**
- `lib/features/shipment/application/delivery_location_reporter.dart`
  - `class DeliveryLocationReporter`
  - `void startReporting(String trackingNo)` — 啟動 30s 週期 Timer
  - `void stopReporting()` — 取消 Timer
  - 每次 tick：呼叫 `LocationService.getCurrentLocation()`，呼叫 `DriverLocationRepository.report(...)` 
  - 失敗時（網路斷線）：寫入本機 SQLite `location_queue` 表，稍後 flush
  - `void flushPendingLocations()` — 在網路恢復後呼叫，批次補傳

- `lib/features/shipment/domain/driver_location_repository.dart`
  - `abstract class DriverLocationRepository`
  - `Future<void> report({ required String trackingNo, required double lat, required double lng, required double accuracyMeters, required DateTime recordedAt })`

- `lib/features/shipment/data/driver_location_repository.dart`
  - 實作：`POST /drivers/location`

**修改**
- `JsBridgeService`：監聽 `APPEvent(kind='delivery_started', result=trackingNo)` → 呼叫 `reporter.startReporting(trackingNo)`
- `APPEvent(kind='delivery_ended')` → 呼叫 `reporter.stopReporting()`
- `WebViewShellPage.didChangeAppLifecycleState`：`resumed` → `reporter.flushPendingLocations()`

**測試**
- `DeliveryLocationReporter` unit test：fake timer, fake repo；驗證 tick 間隔、斷線排隊、flush 補傳

---

### P27-3 — 接單 Bridge + Idempotency Key + 409 處理
**目標**：將「接單」操作納入 Flutter bridge 管控，加上 idempotency key 防重複，正確處理 409 Conflict。

**新增**
- `JsBridgeService._handleOrderAccept(BridgeMessage, BridgeUiPort)`:
  - 從 `message.params['trackingNo']` 取得追蹤號
  - 生成 idempotency key：`sha1(trackingNo + driverId + date)` 
  - 呼叫 `OrderRepository.acceptOrder(trackingNo, idempotencyKey)`
  - 成功 → `_ok('order_accepted', data: {...})`
  - 409 Conflict → `_ok('order_already_taken')` — 非錯誤，WebView 顯示「訂單已被接走」
  - 其他錯誤 → `_error('ORDER_ACCEPT_FAILED', ...)`

- `lib/features/shipment/domain/order_repository.dart`
  - `abstract class OrderRepository`
  - `Future<OrderAcceptResult> acceptOrder(String trackingNo, String idempotencyKey)`

- `lib/features/shipment/data/order_repository.dart`
  - 實作：`POST /orders/{trackingNo}/accept`，帶 `X-Idempotency-Key` header

**修改**
- `JsBridgeService`：在 `handle()` switch 加入 `case 'order_accept'` 分支
- `WebViewShellPage._bridgeAdapterScript`：加入 `window.android.order_accept = function(trackingNo) {...}` 

**測試**
- `JsBridgeServiceTest`：`order_accept` 成功 → `order_accepted`；409 → `order_already_taken`；5xx → `order_accept_failed`

---

### P27-4 — WebView 任務頁主動重新驗證（切回後 Server Reconcile）
**目標**：從外部導航 App 切回時，強制 WebView 重新載入當前任務頁，避免顯示過時狀態。

**修改**
- `WebViewShellPage.didChangeAppLifecycleState(resumed)`:
  - 若 `_inWeb && _currentSection == ShellSection.order`：直接 `_controller?.reload()`（不等待 stale threshold）
  - 維持 P26-8 的 maintenance + queue refresh 邏輯

- `ShellNavigationState`：
  - `staleThreshold` 針對 `order` section 縮短為 `Duration(seconds: 0)`（resume 後一律視為 stale）

**測試**
- `ShellNavigationStateTest`：`isSectionStale` 以 threshold=0 時立即為 true

---

### P27-5 — 離線提交 UI 語意：「已離線暫存」vs「已上傳完成」
**目標**：避免使用者誤以為「本地顯示完成＝後端已收到」。

**新增**
- `NetworkStatusProvider`（`Provider<bool> isOnline`）：訂閱 `connectivity_plus`，暴露當前是否有網路

**修改**
- `ShipmentPage._showResultBanner(ShipmentUploadResult)`:
  - `status == uploaded` → 綠色「✔ 已上傳至後端」
  - `status == pending + isOnline == false` → 橙色「📶 已離線暫存，恢復網路後自動上傳」
  - `status == failed` → 紅色「✗ 上傳失敗，請前往錯誤列表重試」
  - `status == pending（已在 _activeTrackingNos，即重複提交）` → 灰色「⏳ 正在上傳中，請勿重複提交」

- `WebView _bridgeAdapterScript`：
  - `cfs_sign` handler：收到 `signature_queued` 後，在 JS 端設置 pending state；
    **不**顯示「已完成」，改顯示「簽名已儲存，等待上傳」
  - 收到 `onSignatureConfirmed` callback 後，才更新 UI 為「已完成」

---

### P27-6 — 網路恢復自動重傳：ConnectivityAwareFlushService
**目標**：網路從 offline → online 時，自動觸發 `retryFailedUploads()` + `flushPendingLocations()`。

**新增**
- `lib/features/shipment/application/connectivity_aware_flush_service.dart`
  - 訂閱 `ConnectivityStatusPort.onConnectivityChanged()`
  - 偵測到從 `offline → online` 時：
    1. 呼叫 `orchestrator.retryFailedUploads()`
    2. 呼叫 `locationReporter.flushPendingLocations()`
    3. 顯示 `TransactionEventBus` toast：「網路已恢復，上傳中…」
  - 在 `WebViewShellPage.initState()` 啟動；`dispose()` 停止

**測試**
- `ConnectivityAwareFlushService` unit test：fake connectivity stream, fake orchestrator；驗證 offline→online 觸發 flush；online→online 不重複觸發

---

### P27-7 — 後端 API 規格需求（Mobile → Backend 協議備忘）
> 以下為給後端團隊的配合項目，不屬於 Flutter 層實作，但是 P27-1~P27-6 的前提依賴。

| API | Method | 說明 | 防護機制 |
|-----|--------|-----|---------|
| `/orders/{trackingNo}/accept` | POST | 接單 | `X-Idempotency-Key`；已接單回 409 `{ code: 'ORDER_ALREADY_TAKEN' }` |
| `/shipments/{trackingNo}/delivery` | POST | 送達確認 | `X-Idempotency-Key`（已存在）；重複提交回 200（冪等） |
| `/drivers/location` | POST | 司機定位心跳 | `{ trackingNo, lat, lng, accuracyMeters, recordedAt }` |
| `/drivers/location/batch` | POST | 離線補傳批次定位 | Array of location events |
| `/orders/{trackingNo}/status` | GET | 任務頁切回時驗證後端狀態 | 回傳最新 status；app 據此決定是否顯示衝突警告 |

---

## 優先序與工作量估計

| 步驟 | 優先 | 工作量 | 風險 |
|------|------|--------|------|
| P27-1 LocationService | 🔴 高 | M | 需 `geolocator` 權限設定 |
| P27-3 接單 Bridge + 409 | 🔴 高 | M | 需後端 409 規格確認 |
| P27-5 UI 語意修正 | 🔴 高 | S | 純前端，無外部依賴 |
| P27-4 任務頁重新驗證 | 🟡 中 | S | 已有 P26-4/P26-8 基礎 |
| P27-6 自動重傳 | 🟡 中 | S | 需 connectivity stream |
| P27-2 定位心跳 | 🟡 中 | L | 需後端 API + 背景服務 |
| P27-7 後端規格 | 🔵 協議 | — | 需跨團隊溝通 |
