# 錯誤碼對照規格 v1

Doc ID: `HDD-ERROR-CODE-MAP`
Version: `v1.1`
Owner: `BFF Lead`
Last Updated: `2026-03-03`
Review Status: `Draft for management review`
CN/EN Pair Link:
1. CN: `contracts/legacy/error-code-mapping-v1.zh-TW.md`
2. EN: `contracts/legacy/error-code-mapping-v1.en.md`

## 1. 範圍
本文件統一定義以下錯誤映射：
1. legacy SOAP 傳輸/業務錯誤。
2. BFF 正規化 REST 錯誤。
3. Flutter WebView bridge 錯誤。
4. P0 契約長度超限的治理策略。

## 2. Legacy SOAP -> BFF 映射

| 來源情境 | BFF HTTP Status | BFF `code` | 說明 |
|---|---|---|---|
| SOAP 請求中止 / timeout / 網路失敗 | `502` | `LEGACY_TIMEOUT` | 由 `SoapTransportService` 回傳 |
| SOAP HTTP 非 200 / XML 無效 / method result 缺失 | `502` | `LEGACY_BAD_RESPONSE` | 傳輸與協定解析失敗 |
| SOAP 業務回應字串以 `Error` 開頭 | `422` | `LEGACY_BUSINESS_ERROR` | legacy 業務錯誤 |

## 3. Auth/session 映射

| 情境 | HTTP Status | Code/Message |
|---|---|---|
| 登入帳密錯誤 | `401` | `UnauthorizedException` |
| 缺 bearer token | `401` | `Missing bearer token.` |
| bearer token 無效 | `401` | `Invalid bearer token.` |
| refresh token 缺失/撤銷/過期/重放 | `403`（現況） | `Refresh token revoked or expired.` |
| Redis token store 不可用 | `503` | `Token store unavailable.` |

## 4. Bridge 映射（WebView shell）

| 情境 | Bridge Error Code | 說明 |
|---|---|---|
| Payload 缺失或格式錯誤 | `BRIDGE_INVALID_PAYLOAD` | `BridgeMessage.fromDynamic` 解析失敗 |
| bridge method 未知 | `BRIDGE_UNSUPPORTED_METHOD` | 不在 v1 allowlist |
| 因缺 native wiring/權限而拒絕 | `BRIDGE_PERMISSION_DENIED` | 例如 `openfile` placeholder |
| handler 發生未預期例外 | `BRIDGE_RUNTIME_ERROR` | catch-all runtime protection |

## 5. P0 超限正規化策略

| 欄位類別 | 策略 | Error Code |
|---|---|---|
| ID/code/role 類（硬性 `maxLength`） | 拒絕回應 | `LEGACY_BAD_RESPONSE` |
| URL/path/fileName 類 | 拒絕回應 | `LEGACY_BAD_RESPONSE` |
| 自由文字 message 類 | 截斷到契約上限 | 無 |
| 陣列（`maxItems`） | 截斷到上限 | 無 |

## 6. Smoke test 分類

| 情境 | 分類 |
|---|---|
| login/bootstrap/refresh/shipment/logout 全通過 | `PASS` |
| reservation（standard+bulk）查無資料 | `BLOCKED` + `UAT_DATA_BLOCKED` |
| API/transport 失敗 | `FAIL`（附 BFF code） |
