# 合約驗證檢查清單

Doc ID: `HDD-CONTRACT-VERIFY-CHECKLIST`
Version: `v1.4`
Owner: `QA Lead`
Last Updated: `2026-03-03`
Review Status: `Draft for management review`
CN/EN Pair Link:
1. CN: `docs/architecture/CONTRACT_VERIFICATION_CHECKLIST.zh-TW.md`
2. EN: `docs/architecture/CONTRACT_VERIFICATION_CHECKLIST.en.md`

## 1. API 合約
1. [ ] OpenAPI 路徑清單與 controllers 一致。
2. [ ] `POST` endpoint 回傳狀態碼符合契約（規範為 `200`）。
3. [ ] 未授權行為符合契約（`/bootstrap/webview` 無 token 時為 `401`）。
4. [ ] 錯誤物件型別符合 OpenAPI（`code`, `message`）。
5. [ ] P0 定義的回傳欄位均有 `maxLength`/`maxItems`。
6. [ ] P1 邊界驗證：
   1. login/refresh/logout request 超長 -> `400`。
   2. push/register request 超長 -> `400`。
   3. 關鍵回傳欄位超長 -> `502 LEGACY_BAD_RESPONSE`。
   4. `user.name` 與 bulletin `message` 超長 -> truncation。
7. [ ] P2 邊界驗證：
   1. shipment response 超長欄位 -> `502 LEGACY_BAD_RESPONSE`。
   2. delivery/exception request 相關欄位超長 -> `400`。
   3. delivery/exception response 維持 `{ ok: boolean }`。
8. [ ] P3 邊界驗證：
   1. reservation response 超長欄位或 shipmentNos 超過 `200` -> `502 LEGACY_BAD_RESPONSE`。
   2. reservation create/delete request 超長 -> `400`。
   3. reservation create response 維持 `{ reservationNo, mode }` 並符合長度規格。

命令：

```bash
npm run bff:route-diff
npm run bff:error-code-map
npm run bff:test -- --runInBand
```

## 2. SOAP 對照合約
1. [ ] `login -> GetLogin` 對照正確。
2. [ ] `shipment -> GetShipment_elf/GetShipment` fallback 對照正確。
3. [ ] `reservation mode=standard|bulk` 對照正確。
4. [ ] `push/register -> UpdateRegID` 對照正確。
5. [ ] `bootstrap/bulletin -> GetBulletin` 對照正確。

參考：
1. `contracts/legacy/soap-mapping-v1.md`
2. `apps/bff_gateway/src/adapters/soap/legacy-soap.client.ts`

## 3. Bridge 合約
1. [ ] 8 個 methods 已被 adapter 層接受。
2. [ ] unsupported method 回傳 `BRIDGE_UNSUPPORTED_METHOD`。
3. [ ] invalid payload 回傳 `BRIDGE_INVALID_PAYLOAD`。
4. [ ] permission denied 回傳 `BRIDGE_PERMISSION_DENIED`。
5. [ ] runtime protection 回傳 `BRIDGE_RUNTIME_ERROR`。

參考：
1. `contracts/bridge/js-bridge-v1.md`
2. `contracts/legacy/bridge-matrix-v1.md`

## 4. WebView 快取/Session 政策
1. [ ] App 前景/背景切換不應強制重登入。
2. [ ] 交易路徑使用 no-cache/no-store。
3. [ ] 交易回應可看到 `Cache-Control`, `Pragma`, `Expires`。
4. [ ] 登出可清掉 cookie/storage/cache。

參考：
1. `docs/architecture/WAVE4_WEBVIEW_CACHE_POLICY.md`

## 5. 錯誤碼正規化
1. [ ] SOAP timeout/network -> `LEGACY_TIMEOUT` (`502`)。
2. [ ] SOAP malformed/protocol -> `LEGACY_BAD_RESPONSE` (`502`)。
3. [ ] SOAP business error string -> `LEGACY_BUSINESS_ERROR` (`422`)。
4. [ ] 欄位超限依 P0 策略採 reject/truncate。

參考：
1. `contracts/legacy/error-code-mapping-v1.md`

## 6. P0 文件治理 Gate
1. [ ] 核心 API 文件具有中英雙語版本。
2. [ ] 舊 API 42/42 都有 status + reason + owner + milestone。
3. [ ] 文件標頭有跨語言連結。

## 7. CI Final Gate
1. [ ] `npm run bff:route-diff`
2. [ ] `npm run bff:error-code-map`
3. [ ] `npm run bff:test -- --runInBand`
