# PLAN26 — 狀態管理改善計畫：交易即時更新與跨頁面同步

Doc ID: `PLAN26`
Version: `v1.0`
Owner: `Architecture Lead`
Last Updated: 2026-06-01
Status: **Draft**
Predecessor: [PLAN25](PLAN25.md) — 送單健壯性（Idempotency、Retry、Server State）

---

## 0. 核心原則

> **UI 狀態可以是暫時的，交易狀態必須以伺服器為最終真相。**
>
> 任何影響金錢、庫存、訂單的操作，都必須在 server 回應 `2xx` 之後才視為完成。
> Flutter 端的 Riverpod `StateNotifier`/`AsyncNotifier` 只負責「快取 + 呈現」，
> 不能作為業務狀態的唯一來源。

---

## 1. 舊版（Legacy Android SOAP）vs 新版（Flutter/Riverpod）業務邏輯比較

### 1.1 整體架構差異

| 維度 | 舊版 Android | 新版 Flutter |
|---|---|---|
| 通訊協議 | SOAP via ksoap2，全走 `/Inquiry/didiservice.asmx` | REST + BFF（Dio），WebView 仍走舊 HTTPS 頁面 |
| 狀態容器 | Android `Activity` 本地欄位，`onResume` 重新 fetch | Riverpod `Provider`/`StateNotifier`，部分僅 `setState` |
| 跨畫面通知 | 無（每個 Activity 自己 refresh） | 無（目前各 tab 各自獨立，無共享 provider） |
| 後端 Push | Firebase `RegID` 推播（裝置層級） | 尚未接入 WebSocket/SSE/SignalR |
| Session | Cookie-based，`Activity.onResume` 時重注入 | Cookie bootstrap 於 `initState`；Riverpod `AuthController` 持有 token |
| 錯誤解析 | `parseResponseCode(xml)` 解析 SOAP Error 字串 | P25-4 已改為 `DioException` 結構化解析 |
| 重試策略 | 無（直接失敗，要使用者手動重試） | P25 導入 SQLite queue + Dio 重試攔截器 |

---

### 1.2 預約貨件（預約 Tab）

| 面向 | 舊版 | 新版 | 落差 |
|---|---|---|---|
| 資料來源 | SOAP `GetOrderList`（`ds004預約貨件`） | WebView 載入 `old.huoduoduo.com.tw/app/rvt/ge.aspx` | 新版依賴 WebView render，Flutter 端無狀態 |
| 預約成功通知 | `Activity.finish()` → 前頁 `onResume` 重 fetch | WebView 內部 postback，Flutter 端不知道 | **Flutter 端無法感知預約完成事件** |
| 押金扣款反映 | 下一次打 `GetBalance` 時顯示 | 錢包 Tab WebView 未強制 reload | **錢包 tab 不知道押金已變動** |
| 衝突保護 | SOAP 端 Lock（server-side transaction） | WebView 走相同舊 server，有鎖；但 Flutter 端無樂觀鎖顯示 | 低風險，但無前端 hint |

**關鍵問題**：預約完成後，Flutter 端的錢包 Tab 不會知道餘額已變動，使用者切換到錢包頁看到的是舊資料。

---

### 1.3 接單（接單 Tab）

| 面向 | 舊版 | 新版 | 落差 |
|---|---|---|---|
| 掃碼接單 | SOAP `AcceptOrder`，回傳結果顯示 Toast | Flutter Scanner → 回傳掃碼字串給 WebView 的 bridge | Scanner 結果回 WebView，Flutter 不保留狀態 |
| 接單明細 | `Activity` 開 `InquiryActivity`，`onResume` 重 fetch | WebView 載入 `inq/dtl.aspx` | WebView 保持 keepAlive，切回時資料可能過期 |
| 接單取消 | SOAP 取消後立即更新本地 list | WebView postback，Flutter 無感知 | **接單取消後簽收 Tab 的 queue 不知道需移除** |
| 重複接單 | SOAP server 端防重（同 TNUM 只能接一次） | Scanner bridge 只回傳字串，無 dedup | 低風險（server 防重），但 UI 可能顯示重複掃碼 |

---

### 1.4 簽收 / 上傳（簽收 Tab）

| 面向 | 舊版 | 新版 | 落差 |
|---|---|---|---|
| 照片上傳 | SOAP `UploadDelivery`（直接呼叫，失敗則 Toast） | `ShipmentUploadOrchestrator` + SQLite Queue + Dio | **新版比舊版更健壯** |
| 上傳成功後確認 | SOAP 回傳成功字串，直接更新 UI | P25-3 加入 `fetchShipment`，但結果未傳播到 UI | **`fetchShipment` 的 `ShipmentDetail` 沒有 Riverpod provider 讓其他 widget 訂閱** |
| 簽名（`cfs_sign`） | `cfs_sign.aspx` 在 WebView 內完成，SOAP 上傳 | Flutter bridge 取得 PNG 路徑 → `MediaType.signature` 入 queue | Bridge 回傳 `filePath` 給 JS，但 JS 端只收到路徑，**實際上傳是非同步的，JS 認為「已完成」其實上傳可能仍在 queue** |
| 佇列狀態 | 無（直接失敗） | `ShipmentPage` 的 `_queueFuture`（local `FutureBuilder`） | **Queue 狀態是頁面本地 state，`ArrivalUploadErrors` 需自己 load，無法共享** |
| 送達異常 | SOAP `UploadException` | 同上，入 SQLite queue | 同上 |

**最嚴重問題**：`cfs_sign` bridge 回傳 `signature_completed` 給 JS 頁面，JS 頁面認為交易已完成並可能跳轉或更新 UI，但此時 Flutter 的 `MediaType.signature` 僅進入本地 SQLite queue，實際 `POST /shipments/{trackingNo}/delivery` 可能還未送出或已失敗。這造成 **UI 顯示成功但後端未完成** 的核心缺陷。

---

### 1.5 錢包（錢包 Tab）

| 面向 | 舊版 | 新版 | 落差 |
|---|---|---|---|
| 餘額顯示 | SOAP `GetBalance`，Activity 每次 `onResume` 重取 | WebView 載入 `currency/wda.aspx` 等頁面 | WebView keepAlive，不會在切 tab 時自動 reload |
| 提現申請 | SOAP `WithdrawApply`，結果立即 Toast | WebView postback | Flutter 完全不知道提現是否成功 |
| 帳戶明細 | SOAP `GetDailyDetail`/`GetMonthlyDetail` | WebView 載入對應頁面 | WebView 可能顯示舊資料 |
| 餘額變動觸發來源 | 每次 `onResume` 重取（高頻但準確） | 只在 WebView 初次載入時取得 | **簽收完成後 → 餘額更新 → 錢包 tab 不刷新** |

---

## 2. 問題矩陣（Risk × Impact）

| # | 問題 | 觸發場景 | 風險 | 影響 |
|---|---|---|---|---|
| **S1** | `cfs_sign` 回傳 `signature_completed` 但實際上傳非同步 | 使用者簽名 → JS 頁面看到成功 → 實際 queue 上傳失敗 | 🔴 HIGH | 客戶認為簽收完成但系統未記錄 |
| **S2** | `ShipmentDetail` 未傳播至 UI / 其他 provider | 上傳完成後無 server 確認顯示 | 🔴 HIGH | 無法驗證 server 最終狀態 |
| **S3** | WebView keepAlive 跨 tab 顯示過期資料 | 預約後切錢包 tab 看到舊餘額 | 🟠 MEDIUM | 使用者決策基於錯誤資料 |
| **S4** | `queueSnapshotProvider` 為頁面本地 state | `ArrivalUploadErrors` 與 `ShipmentPage` 各自 load queue | 🟠 MEDIUM | 雙重讀取、不一致顯示 |
| **S5** | Tab 切換不觸發 WebView reload | 接單取消後切簽收 tab 仍顯示舊 list | 🟠 MEDIUM | 使用者重複操作同一貨件 |
| **S6** | 重複送單防護僅在 UI 層（`_isBusy`） | 使用者快速導出再導入 `ShipmentPage` → `_isBusy` 重置 | 🟠 MEDIUM | Queue 中同一貨件出現多筆 |
| **S7** | Token 過期 → Refresh 失敗 → 未強制登出 | Refresh interceptor 失敗，後續請求全部 401 | 🟠 MEDIUM | App 卡在無效狀態，需手動重啟 |
| **S8** | `runStartupMaintenance` 只在 `initState` 執行 | App 從背景回前景，未重跑維護 | 🟡 LOW | 舊失敗項不自動補傳 |

---

## 3. 改善計畫（步驟）

每個步驟說明：**問題根因 → 修改方案 → 實作位置 → 驗收標準**。

---

### 🔴 P26-1：`queueSnapshotProvider` — 佇列狀態提升為 Riverpod Provider

**問題根因（對應 S4）**

`ShipmentPage` 持有 `late Future<QueueSnapshot> _queueFuture` 作為 Widget 本地 state。
`ArrivalUploadErrorsPage` 另外自行載入佇列資料。兩個頁面的佇列狀態互不同步。

**修改方案**

新增 Riverpod `AsyncNotifierProvider<QueueSnapshotNotifier, QueueSnapshot>`，
取代 `ShipmentPage` 的本地 `_queueFuture`。

```dart
// lib/features/shipment/application/queue_snapshot_provider.dart

@riverpod
class QueueSnapshotNotifier extends _$QueueSnapshotNotifier {
  @override
  Future<QueueSnapshot> build() async {
    final orchestrator = await ref.watch(shipmentUploadOrchestratorProvider.future);
    return orchestrator.getQueueSnapshot();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
```

呼叫端（`ShipmentPage`、`ArrivalUploadErrorsPage`）改為：

```dart
final snapshot = ref.watch(queueSnapshotNotifierProvider);
```

上傳完成後只需 `ref.invalidate(queueSnapshotNotifierProvider)` 即可讓兩個頁面同步更新。

**實作位置**
- 新增：`lib/features/shipment/application/queue_snapshot_provider.dart`
- 修改：`shipment_page.dart`（移除本地 `_queueFuture`）
- 修改：`arrival_upload_errors_page.dart`（改用新 provider）

**驗收標準**
- `ShipmentPage` 上傳後，`ArrivalUploadErrorsPage` 不需重新進入即可反映最新佇列狀態。
- 單元測試：`queueSnapshotNotifierProvider` 在 `invalidate` 後回傳更新資料。

---

### 🔴 P26-2：`ShipmentDetail` 結果 Provider — Server State 傳播

**問題根因（對應 S2）**

P25-3 在 `submitDelivery` 之後新增了 `fetchShipment`，取得 `ShipmentDetail`。
但 `ShipmentDetail` 只作為 `_attemptUpload` 的內部結果，沒有任何 Riverpod provider
讓 `ShipmentPage` 或其他 widget 訂閱顯示最終 server 狀態。

**修改方案**

新增 `lastConfirmedShipmentProvider`，在 `fetchShipment` 成功後 update：

```dart
// lib/features/shipment/application/shipment_confirmation_provider.dart

@riverpod
class ShipmentConfirmationNotifier extends _$ShipmentConfirmationNotifier {
  @override
  Map<String, ShipmentDetail> build() => {};

  void confirm(String trackingNo, ShipmentDetail detail) {
    state = {...state, trackingNo: detail};
  }

  void clear(String trackingNo) {
    final updated = Map<String, ShipmentDetail>.from(state);
    updated.remove(trackingNo);
    state = updated;
  }
}
```

`ShipmentUploadOrchestrator._attemptUpload` 在 `fetchShipment` 成功後呼叫：

```dart
// orchestrator 取得 ref 後（透過 Riverpod read）
ref.read(shipmentConfirmationNotifierProvider.notifier)
   .confirm(item.trackingNo, detail);
```

`ShipmentPage` 可訂閱此 provider，在上傳完成後顯示「Server 確認：狀態 = Delivered」。

**實作位置**
- 新增：`lib/features/shipment/application/shipment_confirmation_provider.dart`
- 修改：`shipment_upload_orchestrator.dart`（在 `fetchShipment` 成功後 notify）
- 修改：`shipment_page.dart`（watch `shipmentConfirmationNotifierProvider` 顯示確認）

**驗收標準**
- 上傳 + `fetchShipment` 成功後，`ShipmentPage` 顯示 server 回傳的最終狀態。
- 單元測試：orchestrator 呼叫 confirm，provider state 正確更新。

---

### 🔴 P26-3：`cfs_sign` Bridge — 同步回傳改為非同步確認流程

**問題根因（對應 S1）**

`_handleSignature` 在 `openSignature` 完成後立即回傳 `signature_completed`。
此時 JS 頁面認為「簽收成功」，但 Flutter 僅將簽名 PNG 放入 SQLite queue，
`POST /shipments/{trackingNo}/delivery` 尚未發出。

**舊 APP 行為**：`cfs_sign.aspx` 內的 JS 直接呼叫 SOAP，等待 200 才跳頁。
**新 APP 問題**：bridge 回傳「已收到簽名」，JS 誤判為「已上傳成功」。

**修改方案**

`_handleSignature` 回傳的 `action` 改為明確區分「已收到（queued）」vs「已完成（confirmed）」：

```dart
// js_bridge_service.dart  _handleSignature

Future<Map<String, dynamic>> _handleSignature(BridgeUiPort uiPort) async {
  final result = await uiPort.openSignature();
  if (result == null) {
    return _ok('signature_cancelled');
  }
  // 明確告知 JS：簽名已進入上傳佇列，但尚未完成
  return _ok('signature_queued', data: {
    ...result.toJson(),
    'uploadStatus': 'queued',   // JS 端應顯示「上傳中」而非「完成」
  });
}
```

同時，`WebView` 的 JS bridge adapter 中 `cfs_sign` 的呼叫方應處理 `signature_queued`：

```javascript
// bridgeAdapterScript 的說明文件補充（不改 Dart，改 bridge 合約文件）
// cfs_sign() 回傳 uploadStatus:
//   "queued"    → 已收到，上傳中（應顯示 spinner）
//   "confirmed" → server 確認完成（由 P26-2 fetchShipment 後另行推送）
//   "cancelled" → 使用者取消
```

若需要「已確認」的回調，新增 `notifyWebViewSignatureConfirmed` 方法：

```dart
// webview_shell_page.dart
Future<void> notifyWebViewSignatureConfirmed(String trackingNo) async {
  await _controller?.evaluateJavascript(source: '''
    if (window.onSignatureConfirmed) {
      window.onSignatureConfirmed({ trackingNo: "$trackingNo", status: "confirmed" });
    }
  ''');
}
```

`ShipmentConfirmationNotifier.confirm()` 呼叫後，`WebViewShellPage` 監聽 provider 並呼叫此方法。

**實作位置**
- 修改：`js_bridge_service.dart`（`_handleSignature` action 改為 `signature_queued`）
- 修改：`webview_shell_page.dart`（監聽 `shipmentConfirmationNotifierProvider` 並 notify WebView）
- 修改：bridge 合約文件（新增 `uploadStatus` 說明）
- 修改：相關測試（`js_bridge_service_test.dart`）

**驗收標準**
- Bridge 回傳 `action: 'signature_queued'`，不再是 `signature_completed`。
- `fetchShipment` 成功後，WebView 收到 `onSignatureConfirmed` 回調。
- 測試：JS bridge 單元測試確認新 action 值；orchestrator 整合測試確認 notify 順序。

---

### 🟠 P26-4：WebView Tab 切換時 Stale 資料刷新策略

**問題根因（對應 S3、S5）**

`WebViewShellPage` 使用 `InAppWebViewKeepAlive` 讓 WebView 保持在 DOM 中。
使用者在 Tab A 完成操作（如預約），切到 Tab B（錢包），WebView 不會重載。
舊 Android App 的對應行為：每個 `Activity.onResume` 都會重新 `fetch` 資料。

**現況**：`ShellNavigationState` 沒有記錄「最後訪問時間」，無法判斷資料是否過期。

**修改方案**

在 `ShellNavigationState` 加入每個 section 的 `lastActiveAt`：

```dart
// shell_navigation_state.dart

class ShellNavigationState {
  // 新增
  final Map<ShellSection, DateTime> sectionLastActiveAt;

  // copyWith 時更新 sectionLastActiveAt[currentSection]
  ShellNavigationState markSectionActive(ShellSection section) {
    final updated = Map<ShellSection, DateTime>.from(sectionLastActiveAt);
    updated[section] = DateTime.now();
    return copyWith(sectionLastActiveAt: updated);
  }

  bool isSectionStale(ShellSection section, {Duration threshold = const Duration(seconds: 30)}) {
    final last = sectionLastActiveAt[section];
    if (last == null) return true;
    return DateTime.now().difference(last) > threshold;
  }
}
```

在 `_buildTabBar` 的 `onTap` 切換 tab 時，若 `isSectionStale` 為 true，
注入 JS `location.reload()` 強制刷新該 section 的 WebView 頁面：

```dart
// webview_shell_page.dart  _onTabTap
void _onTabTap(ShellSection section) {
  if (_navState.inWeb && _navState.isSectionStale(section)) {
    _controller?.reload();
  }
  setState(() {
    _navState = _navState.selectSection(section).markSectionActive(section);
  });
}
```

**實作位置**
- 修改：`shell_navigation_state.dart`（新增 `sectionLastActiveAt`、`markSectionActive`、`isSectionStale`）
- 修改：`webview_shell_page.dart`（tab 切換邏輯加入 stale check + reload）

**驗收標準**
- 同一 Section 30 秒內切回不觸發 reload（避免頻繁刷新）。
- 超過 30 秒或其他 tab 有完成操作時，切回觸發 `_controller?.reload()`。
- Widget 測試：`isSectionStale` 邏輯單元測試。

---

### 🟠 P26-5：Orchestrator 層級重複送單防護

**問題根因（對應 S6）**

`ShipmentPage._isBusy` 只是 Widget 層的 bool flag，導航離開後重置。
若使用者：
1. 點「Upload Delivery」→ 進 queue
2. 離開 `ShipmentPage`，回來
3. 再次點「Upload Delivery」（相同 trackingNo）

SQLite queue 中會有兩筆相同 `trackingNo` 的 `MediaType.deliveryPhoto` 項目。
雖然 idempotency key 可防止 server 重複處理，但 queue 本身顯示兩筆造成混淆。

**修改方案**

在 `ShipmentUploadOrchestrator` 加入 per-trackingNo active lock：

```dart
// shipment_upload_orchestrator.dart

final Set<String> _activeTrackingNos = {};

Future<UploadResult> uploadDelivery({
  required String trackingNo,
  ...
}) async {
  if (_activeTrackingNos.contains(trackingNo)) {
    return UploadResult(
      queueId: '',
      status: UploadStatus.inProgress,  // 新增此 enum 值
    );
  }
  _activeTrackingNos.add(trackingNo);
  try {
    return await _doEnqueueDelivery(trackingNo: trackingNo, ...);
  } finally {
    // 僅在上傳完成（success/fail）後移除，queue 中有 pending 時保持鎖
    if (/* no pending items for this trackingNo */) {
      _activeTrackingNos.remove(trackingNo);
    }
  }
}
```

**實作位置**
- 修改：`shipment_upload_orchestrator.dart`
- 修改：`UploadStatus` enum（新增 `inProgress`）
- 修改：`shipment_page.dart`（顯示 `inProgress` 狀態提示）
- 修改：orchestrator 測試（新增重複呼叫測試）

**驗收標準**
- 相同 trackingNo 在佇列中有 pending 時，第二次呼叫回傳 `UploadStatus.inProgress`。
- Queue snapshot 中不會出現同一 trackingNo 的兩筆 pending deliveryPhoto。

---

### 🟠 P26-6：Token 過期 → Refresh 失敗 → 強制登出

**問題根因（對應 S7）**

P25-2 加入的 `_RefreshInterceptor` 在 refresh 失敗時拋出 `DioException`。
但攔截器沒有辦法直接呼叫 `ref.read(authControllerProvider.notifier).logout()`，
因為 `Dio` 層不持有 `WidgetRef` 或 `Ref`。

**現況**：Refresh 失敗 → 後續所有 API 請求全部 401 → App 卡住，使用者只能重啟。

**修改方案**

使用 Dart `Stream` 作為橋梁：新增 `AuthEventBus`，攔截器發送 `sessionExpired` 事件，
`WebViewShellPage` 或 `AuthController` 訂閱後執行登出：

```dart
// lib/features/auth/application/auth_event_bus.dart

enum AuthEvent { sessionExpired }

class AuthEventBus {
  static final AuthEventBus instance = AuthEventBus._();
  AuthEventBus._();

  final StreamController<AuthEvent> _controller =
      StreamController<AuthEvent>.broadcast();

  Stream<AuthEvent> get stream => _controller.stream;

  void emit(AuthEvent event) => _controller.add(event);
}
```

`_RefreshInterceptor` refresh 失敗時：

```dart
// dio_provider.dart  _RefreshInterceptor
on DioException catch (e) {
  // refresh 失敗，通知 App 層
  AuthEventBus.instance.emit(AuthEvent.sessionExpired);
  handler.reject(e, callFollowingErrorInterceptor: false);
}
```

`WebViewShellPage.initState` 訂閱：

```dart
// webview_shell_page.dart  initState
_authEventSub = AuthEventBus.instance.stream.listen((event) {
  if (event == AuthEvent.sessionExpired && mounted) {
    ref.read(authControllerProvider.notifier).logout().then((_) {
      if (mounted) context.go('/login');
    });
  }
});
```

**實作位置**
- 新增：`lib/features/auth/application/auth_event_bus.dart`
- 修改：`lib/core/network/dio_provider.dart`（refresh 失敗時 emit）
- 修改：`webview_shell_page.dart`（訂閱 + 登出）
- 新增：單元測試（`auth_event_bus_test.dart`）

**驗收標準**
- Refresh token 過期（模擬 `POST /auth/refresh` 回 401）→ App 自動導向 `/login`。
- 使用者不需要手動重啟 App。
- 測試：mock Dio 拋 refresh 錯誤 → `AuthEventBus.stream` 發出 `sessionExpired`。

---

### 🟠 P26-7：跨 Tab 交易完成事件傳播（Transaction Event Bus）

**問題根因（對應 S3）**

目前各 Tab WebView 頁面完成交易後（如預約扣押金、提現申請），
Flutter 端無任何機制知道「哪個 Tab 的狀態需要更新」。

**修改方案**

擴展 `AuthEventBus` 為通用 `AppEventBus`，或新增 `TransactionEventBus`：

```dart
// lib/core/events/transaction_event_bus.dart

enum TransactionDomain {
  reservation,   // 預約完成
  order,         // 接單完成
  signature,     // 簽收完成
  wallet,        // 錢包餘額變動
}

class TransactionEvent {
  const TransactionEvent({required this.domain, this.trackingNo});
  final TransactionDomain domain;
  final String? trackingNo;
}

class TransactionEventBus {
  static final TransactionEventBus instance = TransactionEventBus._();
  TransactionEventBus._();

  final StreamController<TransactionEvent> _controller =
      StreamController<TransactionEvent>.broadcast();

  Stream<TransactionEvent> get stream => _controller.stream;
  void emit(TransactionEvent event) => _controller.add(event);
}
```

觸發點：
1. **Scanner 完成接單**：`_openScanner` 回傳結果後 emit `TransactionDomain.order`
2. **簽收佇列上傳成功**：`fetchShipment` 成功後 emit `TransactionDomain.signature`
3. **WebView `APPEvent` bridge**：新增 `kind: 'transaction_done'` 支援

`WebViewShellPage` 訂閱事件，對相應 Section 標記 stale（配合 P26-4 強制下次切換時 reload）：

```dart
// webview_shell_page.dart
_transactionSub = TransactionEventBus.instance.stream.listen((event) {
  setState(() {
    _navState = _navState.markSectionStale(_domainToSection(event.domain));
  });
});
```

**實作位置**
- 新增：`lib/core/events/transaction_event_bus.dart`
- 修改：`webview_shell_page.dart`（訂閱 + markSectionStale）
- 修改：`shipment_upload_orchestrator.dart`（簽收成功後 emit）
- 修改：`js_bridge_service.dart`（支援新 `kind: 'transaction_done'` APPEvent）

**驗收標準**
- 簽收 tab 上傳成功後，切到錢包 tab 時自動觸發 WebView reload。
- Widget 測試：`TransactionEventBus` 發送事件 → `ShellNavigationState` 對應 section 變成 stale。

---

### 🟡 P26-8：`runStartupMaintenance` 在前景回復時重執行

**問題根因（對應 S8）**

`ShipmentPage.initState` 呼叫 `orchestrator.runStartupMaintenance()`，
但 App 從背景回前景時，`ShipmentPage` 若已掛載則不會再次觸發 `initState`。
舊版 Android App 在每個 `Activity.onResume` 都會重新嘗試失敗的上傳。

**修改方案**

使用 `WidgetsBindingObserver` 偵測 `AppLifecycleState.resumed`：

```dart
// shipment_page.dart  （或 app-level observer）

class _ShipmentPageState extends ConsumerState<ShipmentPage>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runMaintenance();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runMaintenance();
    }
  }

  Future<void> _runMaintenance() async {
    final orchestrator = await ref.read(shipmentUploadOrchestratorProvider.future);
    await orchestrator.runStartupMaintenance();
    if (mounted) ref.invalidate(queueSnapshotNotifierProvider);
  }
}
```

**實作位置**
- 修改：`shipment_page.dart`（加入 `WidgetsBindingObserver`）

**驗收標準**
- App 切到背景再回前景，`ShipmentPage` 自動重跑 `runStartupMaintenance`。
- `queueSnapshotNotifierProvider` 在重跑後更新顯示。

---

## 4. 實作優先序與依賴關係

```
P26-1 (queueSnapshotProvider)
  └─ P26-2 (ShipmentDetail provider)
       └─ P26-3 (cfs_sign queued/confirmed)
            └─ P26-7 (TransactionEventBus)
                 └─ P26-4 (Stale tab reload)

P26-5 (Duplicate guard)        ← 獨立，無依賴
P26-6 (Token expiry logout)    ← 獨立，無依賴
P26-8 (Lifecycle maintenance)  ← 獨立，建議最後
```

| 順序 | 步驟 | 優先 | 依賴 |
|---|---|---|---|
| 1 | P26-1 | 🔴 HIGH | 無 |
| 2 | P26-5 | 🟠 MEDIUM | 無 |
| 3 | P26-6 | 🟠 MEDIUM | 無 |
| 4 | P26-2 | 🔴 HIGH | P26-1 |
| 5 | P26-3 | 🔴 HIGH | P26-2 |
| 6 | P26-4 | 🟠 MEDIUM | 無 |
| 7 | P26-7 | 🟠 MEDIUM | P26-3、P26-4 |
| 8 | P26-8 | 🟡 LOW | P26-1 |

---

## 5. 新舊 APP 狀態管理落差矩陣（完整版）

| 功能域 | 舊版 Android | 新版 Flutter（PLAN25 後） | PLAN26 補足後 |
|---|---|---|---|
| 佇列狀態共享 | 無佇列（直接失敗） | 頁面本地 `FutureBuilder` | 全域 `queueSnapshotProvider` |
| Server 狀態確認 | SOAP 回傳即確認 | `fetchShipment` 有實作但無 provider | `ShipmentConfirmationNotifier` |
| 簽名完成語意 | SOAP 200 = 完成 | bridge 回傳 = 完成（錯誤！） | `signature_queued` + `onSignatureConfirmed` |
| Tab 切換刷新 | `Activity.onResume` 重 fetch | keepAlive 不 reload | `sectionLastActiveAt` + stale reload |
| 跨 Tab 通知 | 無 | 無 | `TransactionEventBus` |
| 重複送單防護 | Server 端 SOAP lock | UI `_isBusy` flag | Orchestrator `_activeTrackingNos` |
| Token 過期處理 | SOAP 直接失敗，使用者重登 | 可能卡住 | `AuthEventBus` → 自動 logout |
| 前景回復補傳 | `Activity.onResume` 重試 | 僅 `initState` 一次 | `WidgetsBindingObserver` |

---

## 6. 測試策略

每個 P26 步驟完成後須通過：

1. **單元測試**：Provider state 轉換邏輯、EventBus 發送/接收。
2. **Widget 測試**：`ShipmentPage` 使用新 provider，`ArrivalUploadErrorsPage` 資料同步。
3. **整合測試**（Fake repository）：
   - 上傳成功 → `queueSnapshotProvider` 更新 → `ShipmentConfirmationNotifier` 更新。
   - `cfs_sign` → `signature_queued` → `fetchShipment` → `onSignatureConfirmed` callback。
4. **Regression**：全套現有測試 (`flutter test`) 無紅燈。

---

## 7. 不在本計畫範圍內

下列項目超出 P26 範圍，留待後續計畫：

- **WebSocket / SSE 即時推播**：需後端配合，另立 PLAN27。
- **押金餘額 Flutter-native 顯示**：需 BFF 新增 `GET /wallet/balance`，另立計畫。
- **KPI / 代理功能 native 化**：低優先，維持 WebView。
- **多裝置同步**（Driver A 接單 → Driver B 頁面即時更新）：需 Push 整合。
