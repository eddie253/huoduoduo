## Flutter 架構審查報告

整體架構品質相當不錯，屬於合格的 Feature-first + Riverpod 設計。以下分層列出具體問題與建議。

## ✅ 架構優點（符合國際標準）

- **Feature-first 目錄** — `lib/features/<feature>/domain|data|application|presentation` 結構清晰
- **Port/Adapter 模式** — [webview_shell](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/webview_shell:0:0-0:0) 的 [UrlLauncherPort](cci:2://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/webview_shell/application/bridge_action_executor.dart:6:0-10:1)、[BridgeActionExecutor](cci:2://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/webview_shell/application/bridge_action_executor.dart:47:0-62:1)、`MapNavigationPreflightPort` 都是正確的介面抽象
- **Abstract repository interfaces** — [AuthRepository](cci:2://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/auth/data/auth_repository.dart:3:0-7:1)、[ShipmentRepository](cci:2://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/shipment/data/shipment_repository.dart:5:0-23:1)、[MediaLocalRepository](cci:2://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/shipment/data/local/media_local_repository.dart:8:0-21:1) 可替換、可測試
- **SQLite 離線佇列 + 重試機制** — [ShipmentUploadOrchestrator](cci:2://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/shipment/application/shipment_upload_orchestrator.dart:39:0-324:1) 是完整的 UseCase 實作
- **Build-time 設定** — `AppConfig.fromEnvironment` 正確隔離環境設定
- **GoRouter + Riverpod** — 業界主流選擇，版本一致

## 🔴 HIGH — 層次邊界違反（需修正）

### 1.  Service 層接收 `BuildContext`（已修正）

```@c:\users\eddie\Downloads\APP_didiexpress-main\HDD-Express\apps\mobile_flutter\lib\features\webview_shell\application\js_bridge_service.dart:39-42
Future<Map<String, dynamic>> handle(
  List<dynamic> args,
  BuildContext context,   // ← Service 不應依賴 UI 框架
) async {
```

**問題**：[JsBridgeService](cci:2://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/webview_shell/application/js_bridge_service.dart:10:0-701:1)（application 層）直接依賴 `BuildContext`，打破 Clean Architecture 的 *UI 不得滲透 Service* 原則。雖然 [BridgeActionExecutor](cci:2://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/webview_shell/application/bridge_action_executor.dart:47:0-62:1) 已抽象了大部分 UI 操作，但 `BuildContext` 仍透傳進來。

**建議**：將 `context` 包裝成 callback port：

```dart
abstract class BridgeUiPort {
  Future<ScannerResult?> openScanner(String scanType);
  Future<SignatureResult?> openSignature();
  Future<bool> closePage();
  Future<void> showExitDialog(String message);
  Future<void> redirect(String page);
}
```

[JsBridgeService](cci:2://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/webview_shell/application/js_bridge_service.dart:10:0-701:1) 只依賴 `BridgeUiPort`，`BuildContext` 留在 Presentation 層的具體實作裡。

### 2.  Presentation 層直接讀取 Data 層 Repository（已修正）

```@c:\users\eddie\Downloads\APP_didiexpress-main\HDD-Express\apps\mobile_flutter\lib\features\shipment\presentation\shipment_page.dart:176-183
Future<_QueueSnapshot> _loadQueueSnapshot() async {
  final repository = await ref.read(mediaLocalRepositoryProvider.future);  // ← Data 層
  final pending = await repository.listByStatus(MediaQueueStatus.pending);
  final failed  = await repository.listByStatus(MediaQueueStatus.failed);
  ...
```

**問題**：[ShipmentPage](cci:2://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/shipment/presentation/shipment_page.dart:10:0-15:1)（presentation）繞過 [ShipmentUploadOrchestrator](cci:2://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/shipment/application/shipment_upload_orchestrator.dart:39:0-324:1)（application）直接存取 SQLite repository（data）。

**建議**：在 [ShipmentUploadOrchestrator](cci:2://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/shipment/application/shipment_upload_orchestrator.dart:39:0-324:1) 加一個 `getQueueSnapshot()` 方法，讓 Presentation 只和 orchestrator 溝通。

### 3.  Feature 之間直接跨層 import（已修正）

```@c:\users\eddie\Downloads\APP_didiexpress-main\HDD-Express\apps\mobile_flutter\lib\features\maps\presentation\maps_page.dart:4
import '../../webview_shell/application/map_navigation_preflight_service.dart';
```

```@c:\users\eddie\Downloads\APP_didiexpress-main\HDD-Express\apps\mobile_flutter\lib\features\auth\application\auth_controller.dart:9
import '../../webview_shell/application/webview_session_cleanup_service.dart';
```

**問題**：[maps](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/maps:0:0-0:0) feature 和 [auth](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/auth:0:0-0:0) feature 都直接 import [webview_shell](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/webview_shell:0:0-0:0) 的 application 層內部實作，形成 feature 間耦合。

**建議**：將共用的 port 介面移至 [core/](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/core:0:0-0:0)：

```
lib/core/
  navigation/
    map_navigation_preflight_port.dart   ← 介面
  session/
    session_cleanup_port.dart            ← 介面
```

各 feature 的實作留在自己的 [application/](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/auth/application:0:0-0:0) 或 [data/](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/auth/data:0:0-0:0) 層，透過 Riverpod provider 注入。

## 🟡 MEDIUM — 層次擺放問題

### 4.  Repository 抽象介面應在 [domain/](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/auth/domain:0:0-0:0)，不在 [data/](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/auth/data:0:0-0:0)


| 檔案                                                                                                                                                                                                                  | 問題                 |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- |
| [auth/data/auth_repository.dart](cci:7://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/auth/data/auth_repository.dart:0:0-0:0)                                   | 抽象介面混在 data 層 |
| [shipment/data/shipment_repository.dart](cci:7://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/shipment/data/shipment_repository.dart:0:0-0:0)                   | 同上                 |
| [shipment/data/local/media_local_repository.dart](cci:7://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/shipment/data/local/media_local_repository.dart:0:0-0:0) | 同上                 |

**Clean Architecture 標準**：

```
auth/
  domain/
    auth_repository.dart          ← abstract interface (只 import domain models)
  data/
    auth_repository_impl.dart     ← 實作 (import dio, etc.)
```

---

### 5. [WebviewBootstrap](cci:2://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/auth/domain/auth_models.dart:52:0-82:1) / [WebCookieModel](cci:2://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/auth/domain/auth_models.dart:23:0-50:1) 放錯 feature

```@c:\users\eddie\Downloads\APP_didiexpress-main\HDD-Express\apps\mobile_flutter\lib\features\auth\domain\auth_models.dart:53-83
class WebviewBootstrap {         // ← webview 概念，不屬於 auth domain
class WebCookieModel {           // ← 同上
```

這兩個 model 是 WebView 啟動參數，應移至 [webview_shell/domain/](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/webview_shell/domain:0:0-0:0)。[AuthSession](cci:2://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/auth/domain/auth_models.dart:107:0-130:1) 持有 [WebviewBootstrap](cci:2://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/auth/domain/auth_models.dart:52:0-82:1) 是合理的（登入後得到），但 model 定義本身屬於 webview feature。

---

### 6.  AuthController 持有 `Ref`（已修正）（整個 provider container）

```@c:\users\eddie\Downloads\APP_didiexpress-main\HDD-Express\apps\mobile_flutter\lib\features\auth\application\auth_controller.dart:30-37
class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  AuthController({
    required this.ref,              // ← 依賴整個 container
    required this.authRepository,
  })
  final Ref ref;
```

**問題**：`Ref` 的使用讓 controller 隱式依賴 `tokenStorageProvider` 和 `webviewSessionCleanupServiceProvider`，這些依賴應明確注入：

```dart
AuthController({
  required this.authRepository,
  required this.tokenStorage,
  required this.sessionCleanupService,
})
```

---

### 7.  有業務邏輯的 Page 缺少 ViewModel 層（已修正）


| Feature                                                                                                                                    | 缺少                     |
| ------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------ |
| [scanner/](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/scanner:0:0-0:0)     | application/ (ViewModel) |
| [maps/](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/maps:0:0-0:0)           | application/ (ViewModel) |
| [signature/](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/signature:0:0-0:0) | application/ (ViewModel) |

例如 [maps_page.dart](cci:7://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/maps/presentation/maps_page.dart:0:0-0:0) 的座標驗證、URI 建構、preflight 呼叫都是業務邏輯，不應在 `StatefulWidget` 裡。

---

## 🟢 LOW — 一致性與治理

### 8. [application/](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/auth/application:0:0-0:0) 層語義不一致


| Feature                                                                                                                                                                    | 用途                               |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| [auth/application/](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/auth/application:0:0-0:0)                   | Riverpod StateNotifier (ViewModel) |
| [shipment/application/](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/shipment/application:0:0-0:0)           | UseCase Orchestrator               |
| [webview_shell/application/](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/webview_shell/application:0:0-0:0) | 多個 Services                      |

建議：在 README 或 `docs/architecture/` 定義 [application/](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/auth/application:0:0-0:0) 層的職責語義（建議採用：ViewModel 用 `*_controller.dart`，UseCase 用 `*_use_case.dart`，Service 用 `*_service.dart`）。

---

### 9. Provider 定義散落在實作檔案中

Riverpod providers 直接定義在 service/repository 檔（如 [shipment_repository.dart](cci:7://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/shipment/data/shipment_repository.dart:0:0-0:0) 尾端的 `shipmentRepositoryProvider`）。建議每個 feature 獨立出一個 `*_providers.dart`：

```
shipment/
  shipment_providers.dart    ← 集中所有 providers
```

---

### 10. [data/](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/auth/data:0:0-0:0) 下混合遠端與本地 repository

[shipment/data/](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/shipment/data:0:0-0:0) 同時有 [shipment_repository.dart](cci:7://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/shipment/data/shipment_repository.dart:0:0-0:0)（遠端 HTTP）和 [local/](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/shipment/data/local:0:0-0:0)（SQLite），這是可接受的，但建議明確分子目錄：

```
shipment/data/
  remote/
    shipment_remote_repository.dart
  local/
    media_local_repository.dart
    media_local_schema.dart
    media_local_provider.dart
```

---

## 優先修正建議


| 優先順序 | 修正項目                                                                                                                                                                                                                             | 預期效益                                      |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------- |
| **P1**  | [JsBridgeService](cci:2://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/webview_shell/application/js_bridge_service.dart:10:0-701:1) 移除 `BuildContext` → 改用 `BridgeUiPort` | 解除 Service/UI 耦合，大幅提升可測試性        |
| **P1**  | [ShipmentPage](cci:2://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/shipment/presentation/shipment_page.dart:10:0-15:1) 停止直接讀 `mediaLocalRepositoryProvider`              | 維持 presentation→application→data 單向依賴 |
| **P1**  | `MapNavigationPreflightPort` 移至 [core/](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/core:0:0-0:0)                                                                            | 消除 feature 間跨層 import                    |
| **P2**  | Repository 介面移至[domain/](cci:9://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/auth/domain:0:0-0:0)                                                                         | 符合 Clean Architecture 標準                  |
| **P2**  | [AuthController](cci:2://file:///c:/users/eddie/Downloads/APP_didiexpress-main/HDD-Express/apps/mobile_flutter/lib/features/auth/application/auth_controller.dart:29:0-153:1) 改構造注入（移除 `Ref` 欄位）                          | 明確依賴，易於單元測試                        |
| **P3**  | Scanner/Maps/Signature 新增 ViewModel 層                                                                                                                                                                                             | 業務邏輯從 Widget 中解耦                      |

整體架構的方向是正確的，P1 三項是真正的邊界洩漏，其餘屬於優化。

---

## 修正歷程

| 日期 | 批次 | 完成項目 | 測試 |
| ---------- | ---- | -------- | ---- |
| 2026-03-06 | P1 | #1 BridgeUiPort 解耦、#2 ShipmentPageOrchestrator、#3 MapNavigationPreflightPort 移至 core/ | 220/220  |
| 2026-03-06 | P2-A | #4 Repository 介面移至 domain/（auth、shipment、media_local） | 220/220  |
| 2026-03-06 | P2-B | #6 AuthController 移除 Ref、明確注入 tokenStorage + sessionCleanupService | 220/220  |
| 2026-03-06 | P3 | #7 MapsViewModel、ScannerViewModel、SignatureViewModel 新增 | 253/253  |

> 待辦：#5（AuthSession 模型歸屬）、#8#10（治理項目）尚未處理。
