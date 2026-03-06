## Flutter API 強健性審查報告（P25）

**審查日期**：2026-03-06
**審查範圍**：`apps/mobile_flutter` 全 HTTP 層 + 業務流程
**比對基礎**：`contracts/openapi/huoduoduo-v1.openapi.yaml`、舊版 `AppWebView.java` bridge 行為矩陣
**現況測試**：253/253 （P1-P3 完成後）

---

##  HIGH  交易安全性缺口

### 1. Delivery / Exception 提交缺少 Idempotency Key

**現況**：

```dart
// shipment_repository.dart  submitDelivery
await _dio.post<void>(
  '/shipments/$trackingNo/delivery',
  data: { 'imageBase64': ..., 'latitude': ..., 'longitude': ... },
);
```

沒有 `X-Idempotency-Key` 標頭。

**問題**：當網路在伺服器已接受後、回應回到客戶端前中斷，
`ShipmentUploadOrchestrator` 會重試，造成同一單**雙重送達/異常紀錄**。
司機派送與簽收是金融/運務憑據，重複提交直接影響對帳。

**建議**：

```dart
// 以 queueId + retryCount 作為冪等鍵
options.headers['X-Idempotency-Key'] = '${item.id}_${item.retryCount}';
```

BFF 端依 key 做 24h dedup（Redis），Flutter 端每次 retry **保持相同 key**（不遞增），直到成功或 dead-letter。

---

### 2. 無 Token 自動刷新攔截器（401  refresh  retry）

**現況**：`dio_provider.dart` 只注入 Bearer token，沒有攔截 401 後自動呼叫 `/auth/refresh` 重試的邏輯。

**問題**：Access token 過期後，所有 API 呼叫傳回 401，
畫面卡住或白屏，直到使用者手動重新登入。
司機在路上作業時體驗最差。

**建議**：

```dart
dio.interceptors.add(InterceptorsWrapper(
  onError: (DioException e, handler) async {
    if (e.response?.statusCode == 401) {
      try {
        final newTokens = await authRepository.refresh(storedRefreshToken);
        await tokenStorage.saveTokens(newTokens);
        // retry 原始 request
        final retry = await dio.fetch<dynamic>(e.requestOptions
          ..headers['Authorization'] = 'Bearer ${newTokens['accessToken']}');
        return handler.resolve(retry);
      } catch (_) {
        // refresh 也失敗  觸發登出
      }
    }
    handler.next(e);
  },
));
```

攔截器需防重入（同時多個 401 只 refresh 一次，其他 request 排隊等待）。

---

### 3. WebView 完成後缺少 Server State 確認（`GET /shipments/{trackingNo}`）

**現況**：WebView bridge `cfs_sign()` 回傳簽名 PNG 路徑後，Flutter 端只更新本地 ViewModel，
沒有呼叫 `GET /shipments/{trackingNo}` 確認伺服器狀態。

**問題**：

1. WebView 完成  Flutter 認為「已完成」 但伺服器可能還未更新或失敗
2. `APPEvent("close", ...)` bridge 事件觸發後，Flutter 未向伺服器確認最終狀態
3. **前端本地狀態不應作為最終真相，一律以 server state 為準**

**建議**：在 `ShipmentRepository` 新增：

```dart
Future<ShipmentDetail> fetchShipment(String trackingNo);
```

對應 `GET /shipments/{trackingNo}`（OpenAPI 已定義，Flutter 端目前無實作）。

Bridge 完成流程：

```
cfs_sign() 完成
   uploadSignature(trackingNo, pngPath)
     POST /shipments/{trackingNo}/delivery (含 signatureBase64)
       GET /shipments/{trackingNo}   確認 status 已更新
         pop(ShipmentDetail)         以 server state 為最終結果
```

---

##  MEDIUM  資料正確性缺口

### 4. `DioException` 錯誤解析仰賴 Regex，丟失結構化錯誤碼

**現況**：

```dart
// shipment_upload_orchestrator.dart
String _extractErrorCode(Object error) {
  final raw = error.toString();
  final match = RegExp(r'LEGACY_[A-Z_]+').firstMatch(raw);
  return match?.group(0) ?? 'UPLOAD_FAILED';
}
```

**問題**：BFF 回傳結構化 `{ "code": "LEGACY_BUSINESS_ERROR", "message": "..." }`（422/502），
但此 regex 只能比對 `LEGACY_*` 模式，遇到 `401`、`403`、`503`、`network timeout` 等全部落入 `UPLOAD_FAILED`。

**建議**：

```dart
String _extractErrorCode(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final code = data['code'] as String?;
      if (code != null && code.isNotEmpty) return code;
    }
    final status = error.response?.statusCode;
    if (status != null) return 'HTTP_$status';
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'TIMEOUT';
    }
  }
  return 'UPLOAD_FAILED';
}
```

---

### 5. `fromJson` 對必填欄位靜默回退 `''`，不符 OpenAPI `required:` 合約

**現況**：

```dart
// auth_models.dart  AuthSession.fromJson
accessToken: json['accessToken'] as String? ?? '',  // required 欄位，空字串不安全
refreshToken: json['refreshToken'] as String? ?? '',
id: json['id'] as String? ?? '',
```

**問題**：OpenAPI 標記 `required: [accessToken, refreshToken, user, webviewBootstrap]`。
若後端回傳缺少這些欄位（BFF bug、schema 異動），Flutter 靜默產生無效 session，
後續所有 API 呼叫帶空 token，形成難以追蹤的連鎖錯誤。

**建議**：required 欄位使用 Dart 3 pattern matching，缺失則拋出 `FormatException`：

```dart
factory AuthSession.fromJson(Map<String, dynamic> json) {
  return switch (json) {
    {
      'accessToken': final String accessToken,
      'refreshToken': final String refreshToken,
      'user': final Map<String, dynamic> userMap,
      'webviewBootstrap': final Map<String, dynamic> bootstrapMap,
    } =>
      AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: UserProfile.fromJson(userMap),
        webviewBootstrap: WebviewBootstrap.fromJson(bootstrapMap),
      ),
    _ => throw FormatException('AuthSession: missing required field'),
  };
}
```

同樣適用 `UserProfile.fromJson`、`WebviewBootstrap.fromJson`。

---

### 6. `MediaType.signature` 上傳未附 `signatureBase64`

**現況**：

```dart
// shipment_upload_orchestrator.dart  _attemptUpload
case MediaType.signature:
  await _shipmentRepository.submitDelivery(
    trackingNo: item.trackingNo,
    imageBase64: imageBase64,   // 這是簽名 PNG
    imageFileName: item.fileName,
    latitude: ..., longitude: ...,
  );
```

**問題**：OpenAPI `DeliveryRequest` 定義了獨立的 `signatureBase64` 欄位，
與 `imageBase64`（配送照片）語意不同。當前實作將簽名 PNG 放進 `imageBase64`，
BFF 端可能無法正確分辨照片與簽名，導致後台簽收紀錄異常。

**建議**：

```dart
// ShipmentRepository 新增 signatureBase64 參數
Future<void> submitDelivery({
  required String trackingNo,
  required String imageBase64,
  required String imageFileName,
  String? signatureBase64,   //  新增
  required String latitude,
  required String longitude,
});

// 呼叫端
case MediaType.signature:
  await _shipmentRepository.submitDelivery(
    trackingNo: item.trackingNo,
    imageBase64: '',                // 簽名單通常無額外照片
    imageFileName: item.fileName,
    signatureBase64: imageBase64,   //  簽名放正確欄位
    latitude: ..., longitude: ...,
  );
```

---

##  LOW  一致性與韌性治理

### 7. Dio timeout 單一設定，upload 與 query 混用同一 client

**現況**：connect/send/receive 統一 20 秒。

**問題**：訂單狀態查詢（`GET /shipments/{trackingNo}`）、token refresh（`POST /auth/refresh`）
不應等 20 秒，使用者體驗差；大型 base64 圖片上傳則需要較長的 send/receive timeout。

**建議**：區分兩組 Dio 設定：

```dart
// 查詢 client（短 timeout，快速失敗）
final queryDioProvider = Provider<Dio>((ref) => Dio(BaseOptions(
  baseUrl: AppConfig.apiBaseUrl,
  connectTimeout: const Duration(seconds: 8),
  receiveTimeout: const Duration(seconds: 8),
  sendTimeout: const Duration(seconds: 8),
)));

// 上傳 client（長 timeout，適合 base64 payload）
final uploadDioProvider = Provider<Dio>((ref) => Dio(BaseOptions(
  baseUrl: AppConfig.apiBaseUrl,
  connectTimeout: const Duration(seconds: 20),
  receiveTimeout: const Duration(seconds: 60),
  sendTimeout: const Duration(seconds: 60),
)));
```

---

### 8. 無 Dio 級別重試攔截器（5xx / network-error）

**現況**：網路錯誤一律落入 SQLite queue 標記 failed，依賴 `retryFailedUploads`。

**問題**：一次性的 5xx（伺服器瞬斷）或網路抖動，不應立即 mark failed 進 queue。
應在 Dio 層先重試 1-2 次（exponential backoff），確認真的失敗才進 queue。

**建議**：上傳 Dio client 加入輕量重試攔截器（僅對 5xx 與 timeout，不對 4xx）：

```dart
// 最多 2 次自動重試，間隔 1s / 2s
RetryInterceptor(
  dio: uploadDio,
  retries: 2,
  retryDelays: [Duration(seconds: 1), Duration(seconds: 2)],
  retryEvaluator: (error, attempt) =>
    error.type == DioExceptionType.connectionTimeout ||
    error.type == DioExceptionType.receiveTimeout ||
    (error.response?.statusCode ?? 0) >= 500,
)
```

此層重試**不遞增 retryCount**（SQLite queue 的 retryCount 只在 Dio 重試全部用盡後才增加）。

---

## 新舊 APP 落差矩陣

| 功能 | 舊版 AppWebView（Java） | 新版 Flutter | 落差 |
|---|---|---|---|
| 冪等提交保護 | 無（舊版本同樣缺乏） |  無 | 待補 |
| Token 過期自動刷新 | WebView session 自動管理 |  無攔截器 | 待補 |
| 簽收後 server state 確認 | 舊版依賴 WebView reload |  Flutter 無 GET /shipments | 待補 |
| 錯誤碼解析 | Java `parseResponseCode(xml)` |  Regex 比對字串 | 待改善 |
| 簽名欄位區分 | `cfs_sign` 回傳獨立欄位 |  混入 imageBase64 | 待修正 |
| 網路弱訊號提示 | 無 |  NetworkSignalAlertHost | 新版優於舊版 |
| 離線佇列 + dead-letter | 無（直接失敗） |  SQLite queue (5 retry) | 新版優於舊版 |
| 上傳 timeout 區分 | 無 |  一律 20s | 待改善 |

---

## 優先修正建議

| 優先順序 | 修正項目 | 預期效益 | 影響檔案 |
|---|---|---|---|
| **P25-1** | 加入 Idempotency Key 標頭 | 防止雙重派送/簽收 | `shipment_repository.dart`、`shipment_upload_orchestrator.dart` |
| **P25-2** | 401 自動 refresh + retry 攔截器 | 消除 token 過期白屏 | `dio_provider.dart`、`auth_repository.dart` |
| **P25-3** | WebView 完成後呼叫 GET /shipments 確認 | Server state 為唯一真相 | `shipment_repository.dart`（新增方法）、bridge handler |
| **P25-4** | 結構化 DioException 錯誤碼解析 | 正確分類 422/502/401/timeout | `shipment_upload_orchestrator.dart` |
| **P25-5** | `fromJson` required 欄位嚴格驗證 | 防止無效 session 靜默傳播 | `auth_models.dart` |
| **P25-6** | `signatureBase64` 獨立欄位 | 後台正確區分照片與簽名 | `shipment_repository.dart`、orchestrator |
| **P25-7** | 區分 query / upload Dio client | 短路查詢超時，長傳大圖 | `dio_provider.dart` |
| **P25-8** | Dio 級別 5xx/timeout 重試（2次） | 減少網路抖動進 SQLite queue | `dio_provider.dart` |

---

> **原則**：前端本地狀態（SQLite queue、ViewModel）僅作為**樂觀 UI**，最終狀態一律以 `GET /shipments/{trackingNo}` server response 為準。
