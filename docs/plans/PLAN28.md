# PLAN28 — 條碼掃描可靠性與診斷工具計畫

## 問題描述

| # | 問題 | 現象 |
|---|-----|------|
| A | 一維條碼截短 | 20 字元追蹤號掃出 19 字元；末位或首位字元遺失 |
| B | 連續重複送出 | 掃完一筆後，未移開鏡頭就觸發第二次送出，造成同一筆重複接單 |
| C | 無測試入口 | 設定頁沒有條碼測試按鈕，需要進入完整業務流程才能測試掃描 |
| D | 無診斷記錄 | 無法留存掃描歷史、比對原始值與期望長度，無從改善 |

---

## 舊 APP vs 新 APP 根本原因對照

### 問題 A：條碼截短

| 面向 | 舊 APP | 新 APP 現況 | 根本原因 |
|-----|--------|------------|---------|
| 解碼引擎 | Android WebView + ZXing Java (硬體條碼槍優先) | `flutter_zxing 2.2.1`（純軟體解碼） | 軟體解碼每 30ms 取一幀，若當幀對焦稍差、條碼邊緣超出或位移，ZXing 可能在部分掃描邊界解碼出截短值 |
| 掃描幀率 | 硬體觸發（精確） | `scanDelay: 30ms`（連續拉取） | 每 30ms 掃一次，框架抖動期間可能解碼出不完整值 |
| 長度驗證 | 無（靠硬體準確） | 無 | 解碼器不驗證字元長度，截短值直接通過 |
| 解碼時間過濾 | 不適用 | 無 | `Code.duration < 2ms` 表示該幀可能只解到部分條碼，需排除 |

**新 APP 改善點**
1. `scanDelay` 從 30ms → 80ms（減少抖動期間的誤解碼機率）
2. `scanDelaySuccess` 從 60ms → 200ms（成功後給予足夠時間停止鏡頭）
3. `ZxingEngineAdapter`：`duration < 2ms` 的解碼結果視為不可靠，拋棄
4. `ScanRequest` 新增 `minLengthBySymbology`：code128 預設最小長度 = 10

---

### 問題 B：連續重複送出

| 面向 | 舊 APP | 新 APP 現況 | 根本原因 |
|-----|--------|------------|---------|
| 去重視窗 | 硬體觸發，天然防重 | `dedupWindowMs: 800ms` | 同一條碼在 800ms 後可再次觸發；司機連續掃描時，800ms 不足以防止多次觸發 |
| 停止時機 | 掃描器立即停止 | `stop()` 設定 flag，但 `ReaderWidget` 的 `onScan` callback 可能仍有一幀在 pipeline | `stop()` 後最多 60ms 內還可能收到一個幀事件 |
| 提交保護 | WebView JS 有 UI lock | `_viewModel.tryComplete()` 單線程安全，但不阻擋 pipeline 中的幀 | 需要在 `ScanSessionController` 的 stop 後增加 drain guard |

**新 APP 改善點**
1. `dedupWindowMs` 對 1D 模式從 800ms → 1500ms
2. `ScanSessionController`：`stop()` 後加入 `_draining = true` flag，`consumeEngineCode()` 在 draining 期間拋棄所有輸入
3. `ScannerViewModel.buildRequest()` 根據 `scanMode` 自動選擇 `dedupWindowMs`

---

## 實作步驟（純 client 層）

### P28-1 — ScanRequest 掃描參數精細化
**目標**：讓 1D 掃描使用更保守的時序參數，降低截短與重複觸發機率。

**修改 `scan_kit_core`**
- `ScanRequest` 新增欄位：
  ```dart
  final int scanDelayMs;         // 預設 80（原本固定 30）
  final int scanDelaySuccessMs;  // 預設 200（原本固定 60）
  final Map<ScanSymbology, int> minLengthBySymbology; // 預設 {}
  ```
- `HddScannerView` 將 `scanDelayMs`/`scanDelaySuccessMs` 傳入 `ReaderWidget`
- `ZxingEngineAdapter.mapEngineCode()` 新增參數 `Map<ScanSymbology, int> minLength`；若 `value.length < minLength[symbology]` 則回傳 `null`

**修改 `ScannerViewModel.buildRequest()`**
- 1D 模式：`scanDelayMs: 80`, `scanDelaySuccessMs: 200`, `dedupWindowMs: 1500`
  ```dart
  minLengthBySymbology: {
    ScanSymbology.code128: 10,
    ScanSymbology.code39: 4,
  }
  ```
- 2D / all 模式：維持原有預設

**測試**
- `ScannerViewModelTest`：1D 模式 `buildRequest()` 驗證 `dedupWindowMs == 1500`、`scanDelayMs == 80`
- `ZxingEngineAdapterTest`：長度 < minLength 時回傳 `null`

---

### P28-2 — ScanSessionController 停止後防洩漏（Drain Guard）
**目標**：`stop()` 後進入 drain 狀態，丟棄所有後續 engine 輸入，防止 pipeline 殘留幀觸發重複送出。

**修改 `scan_kit_core/src/application/scan_session_controller.dart`**
```dart
bool _draining = false;

void stop() {
  if (!_running) return;
  _running = false;
  _draining = true;
  _emit(ScanStoppedEvent(timestamp: _clock()));
  Future.delayed(const Duration(milliseconds: 300), () => _draining = false);
}

bool consumeEngineCode(Object engineCode) {
  if (!_running || _draining) return false;
  // ... existing logic
}
```

**測試**
- `ScanSessionControllerTest`：`stop()` 後 150ms 內呼叫 `consumeEngineCode()` 不觸發 `ScanSuccessEvent`
- `ScanSessionControllerTest`：`stop()` 後 400ms 後重新 `start()` 可正常掃描

---

### P28-3 — ScanAuditRepository（掃描記錄 SQLite）
**目標**：本機儲存每次掃描結果，用於診斷頁判讀準確性。

**新增 `lib/features/scanner/data/scan_audit_repository.dart`**
```
ScanAuditEntry {
  int id (auto)
  DateTime scannedAt
  String rawValue
  int length
  String symbology      // ScanSymbology.name
  String source         // camera | manual
  int? durationMs       // from rawMeta['durationMs']
  String sessionId
}
```
- `SqfliteScanAuditRepository` 操作 `scan_audit` 表
  - `insert(ScanAuditEntry)` 
  - `queryRecent({ int limit = 100 })` → `List<ScanAuditEntry>`
  - `clearAll()`
- `scanAuditRepositoryProvider` Riverpod provider

**新增 SQLite schema** 在 `MediaLocalSchema` 同一 DB 或獨立 DB（建議同 DB，統一升版）

**Wire** 在 `ScannerPage._onScanEvent` 中，成功後寫入記錄：
```dart
void _onScanEvent(ScanEvent event) {
  if (event is! ScanSuccessEvent) return;
  final result = _viewModel.tryComplete(event.result.value);
  if (result == null) return;
  _auditRepo?.insert(ScanAuditEntry.fromResult(event.result));
  _controller.stop();
  Navigator.of(context).pop(result);
}
```

**測試**
- `ScanAuditRepositoryTest`：insert + queryRecent 驗證長度與欄位；clearAll 後 query 回空

---

### P28-4 — 條碼診斷頁（ScanDiagnosticsPage）
**目標**：提供可讀掃描記錄的頁面，讓 QA 與開發人員判讀條碼準確性。

**新增 `lib/features/scanner/presentation/scan_diagnostics_page.dart`**
- 路由：`/scan-diagnostics`（加入 `router.dart`）
- UI：
  - `AppBar('條碼掃描記錄')` + 右上角「清除」button
  - `ListView` 每筆記錄顯示：
    - 原始值（等寬字型，`code` font）
    - 長度 badge（若 `symbology == code128 && length < 10`，顯示紅色 ⚠️，否則綠色）
    - 碼制 (`code128` / `code39` 等)
    - 解碼時間 `Xms`（若 `durationMs < 2`，顯示橙色 `fast` 標籤）
    - 時間戳記（`HH:mm:ss`）
  - 空狀態：「尚無掃描記錄」
- 上方 Summary banner：
  - 總筆數 / code128 短於 10 字元筆數 / 平均解碼時間

**測試**
- `ScanDiagnosticsPageTest`（widget smoke）：空狀態顯示正確文字；有記錄時顯示 ListView

---

### P28-5 — Settings 頁「條碼掃描測試」卡片
**目標**：在設定頁加入一鍵掃描入口與診斷頁連結，不影響業務流程。

**修改 `lib/features/settings/presentation/settings_page.dart`**
新增第三張 `Card`，位於主題色卡片之後：
```
Card ─ 條碼掃描測試
  ├── 說明文字：「測試模式：掃描結果不送出後端，僅記錄於本機診斷日誌」
  ├── FilledButton.icon(Icons.qr_code_scanner, '開始掃描測試')
  │     → push ScannerPage(scanType: 'barcode_test')
  │     → 返回後顯示 _lastTestResult inline
  └── TextButton.icon(Icons.history, '查看掃描診斷記錄')
        → push /scan-diagnostics
```
- `scanType: 'barcode_test'` 在 `ScannerViewModel.defaultScanMode` 映射至 `oneDimensional`

**測試**
- `SettingsPageTest`：新增掃描測試卡片的 widget smoke test

---

## 優先序與工作量估計

| 步驟 | 優先 | 工作量 | 風險 |
|------|------|--------|------|
| P28-1 ScanRequest 參數精細化 | 🔴 高 | S | 需調整 scan_kit_core 內部 |
| P28-2 Drain Guard | 🔴 高 | S | 無外部依賴 |
| P28-3 ScanAuditRepository | 🟡 中 | M | 需 SQLite schema 變更 |
| P28-4 ScanDiagnosticsPage | 🟡 中 | M | 純 UI，無外部依賴 |
| P28-5 Settings 掃描測試卡片 | 🟡 中 | S | 純 UI |

### 執行順序
```
P28-1 → P28-2 → P28-3 → P28-4 → P28-5
```
P28-1/2 先行（直接改善掃描準確性），P28-3/4/5 後行（診斷工具，不影響核心路徑）。

---

## 架構影響範圍

```
scan_kit_core/
  domain/scan_models.dart           ← P28-1: ScanRequest 新增欄位
  application/scan_session_controller.dart ← P28-2: Drain Guard
  infrastructure/flutter_zxing/zxing_engine_adapter.dart ← P28-1: minLength 驗證
  presentation/hdd_scanner_view.dart ← P28-1: 傳遞新 scanDelay 參數

lib/features/scanner/
  application/scanner_view_model.dart ← P28-1: 1D 模式參數調整
  data/scan_audit_repository.dart    ← P28-3: 新增
  presentation/scanner_page.dart     ← P28-3: wire audit insert
  presentation/scan_diagnostics_page.dart ← P28-4: 新增

lib/features/settings/
  presentation/settings_page.dart    ← P28-5: 新增卡片

lib/app/router.dart                  ← P28-4: 新增 /scan-diagnostics 路由
```
