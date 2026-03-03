# Legacy SOAP 對照規格 v1

Doc ID: `HDD-LEGACY-SOAP-MAP`
Version: `v1.4`
Owner: `BFF Lead`
Last Updated: `2026-03-03`
Review Status: `Draft for management review`
CN/EN Pair Link:
1. CN: `contracts/legacy/soap-mapping-v1.zh-TW.md`
2. EN: `contracts/legacy/soap-mapping-v1.en.md`

## 1. 範圍
1. 本文件定義 BFF REST endpoint 與 legacy SOAP（`didiservice.asmx`）的對照。
2. 本文件內容與英文版一致，供治理與審核使用。

Legacy 程式依據：
1. `app/src/main/java/network/WebService.java`
2. `app/src/main/java/didi/app/express/MainActivity.java`
3. `apps/bff_gateway/src/adapters/soap/legacy-soap.client.ts`

## 2. Endpoint 對 SOAP 對照

| BFF Endpoint | SOAP Method(s) | Request 對照 | Response 對照 |
|---|---|---|---|
| `POST /v1/auth/login` | `GetLogin` | `Account=account`, `Password=password`, `Kind=android` | Legacy JSON -> `user` + token payload |
| `POST /v1/auth/refresh` | N/A | 僅 Redis rotation | 新 access/refresh |
| `POST /v1/auth/logout` | N/A | 僅 Redis revoke | `{ revoked, subject }` |
| `GET /v1/bootstrap/webview` | N/A | 用 account + identify 組 cookie | `baseUrl/registerUrl/resetPasswordUrl/cookies` |
| `GET /v1/bootstrap/bulletin` | `GetBulletin` | 無 SOAP request 欄位 | `message/hasAnnouncement/updatedAt` |
| `POST /v1/push/register` | `UpdateRegID` | `DNUM=contractNo`, `RegID=fcmToken`, `Kind=Android|ios`, `Version=appVersion` | `{ ok, registeredAt }` |
| `GET /v1/shipments/{trackingNo}` | `GetShipment_elf` 後備 `GetShipment` | `TNUM=trackingNo` | Legacy 中文欄位 -> 標準 Shipment DTO |
| `POST /v1/shipments/{trackingNo}/delivery` | `UpdateArrival` | `DNUM`, `TNUM`, `Image`, `Image_FN`, `Itude=lat,lng` | `{ ok: true }` |
| `POST /v1/shipments/{trackingNo}/exception` | `UpdateArrivalErr_NEW` | `DNUM`, `TNUM`, `Image`, `Image_FN`, `Itude=lat,lng` | `{ ok: true }` |
| `GET /v1/reservations?mode=standard` | `GetARVed` | `DNUM=contractNo` | Legacy rows -> reservation DTO[] |
| `GET /v1/reservations?mode=bulk` | `GetBARVed` | `DNUM=contractNo` | Legacy rows -> reservation DTO[] |
| `POST /v1/reservations?mode=standard` | `UpdateARV` | `NUMs=shipmentNos.join(',')`, `Addr=address`, `DNUM=contractNo` | `{ reservationNo, mode }` |
| `POST /v1/reservations?mode=bulk` | `UpdateBARV` | `NUM=shipmentNos[0]`, `Addr=address`, `FEE=fee`, `DNUM=contractNo` | `{ reservationNo, mode }` |
| `DELETE /v1/reservations/{id}?mode=standard` | `RemoveARV` | `NUMs=id`, `Addr=address`, `DNUM=contractNo` | `{ ok: true }` |
| `DELETE /v1/reservations/{id}?mode=bulk` | `RemoveBARV` | `NUM=id`, `Addr=address`, `DNUM=contractNo` | `{ ok: true }` |

## 3. 身分與 Cookies
1. `Account` = 帳號。
2. `Identify` = `Base64(SHA-512(password bytes))`。
3. `Kind` = `android`。

## 4. Legacy 傳輸設定（UAT baseline）
1. SOAP base URL：`https://old.huoduoduo.com.tw`
2. SOAP namespace：`https://driver.huoduoduo.com.tw/`
3. SOAP path：`/Inquiry/didiservice.asmx`

## 5. P0 正規化策略
1. 合約長度限制以 OpenAPI 的 `maxLength` / `maxItems` 為準。
2. legacy 回傳超長時：
   1. 身分類與代碼類欄位：以 `LEGACY_BAD_RESPONSE` 拒絕。
   2. 自由文字欄位（如 message）：截斷到契約上限。
3. 本階段僅定義策略，不在 P0 實作 runtime 強制。

## 6. P1 實作註記
1. P1 已完成以下端點的契約 enforcement：
   1. `POST /v1/auth/login`
   2. `POST /v1/auth/refresh`
   3. `POST /v1/auth/logout`
   4. `GET /v1/bootstrap/webview`
   5. `GET /v1/bootstrap/bulletin`
   6. `POST /v1/push/register`
2. runtime 行為依 P0 規則：
   1. 關鍵結構欄位超限：`LEGACY_BAD_RESPONSE`。
   2. 顯示文字欄位（`user.name`、bulletin `message`）：截斷處理。

## 7. P2 實作註記
1. `GET /v1/shipments/{trackingNo}` 回傳欄位已加上契約 enforcement。
2. `POST /v1/shipments/{trackingNo}/delivery`、`/exception`：
   1. request 欄位新增 `MaxLength` 驗證。
   2. 仍維持 `{ ok: true }` 回傳形狀。

## 8. P3 實作註記
1. `GET /v1/reservations` 回傳欄位已加上契約 enforcement。
2. `POST /v1/reservations` 與 `DELETE /v1/reservations/{id}`：
   1. request 欄位已補 `MaxLength` / `ArrayMaxSize` 驗證。
   2. create response 契約已加 enforcement（`reservationNo`, `mode`）。
