# Legacy SOAP Mapping v1

Doc ID: `HDD-LEGACY-SOAP-MAP`
Version: `v1.7`
Owner: `BFF Lead`
Last Updated: `2026-03-04`
Review Status: `Draft for management review`
CN/EN Pair Link:
1. CN: `contracts/legacy/soap-mapping-v1.zh-TW.md`
2. EN: `contracts/legacy/soap-mapping-v1.en.md`

## 1. Scope
1. This contract maps BFF REST endpoints to legacy SOAP methods in `didiservice.asmx`.
2. This file is the compatibility English baseline and is content-equivalent to `soap-mapping-v1.en.md`.

Legacy references:
1. `app/src/main/java/network/WebService.java`
2. `app/src/main/java/didi/app/express/MainActivity.java`
3. `apps/bff_gateway/src/adapters/soap/legacy-soap.client.ts`

## 2. Endpoint to SOAP mapping

| BFF Endpoint | SOAP Method(s) | Request Mapping | Response Mapping |
|---|---|---|---|
| `POST /v1/auth/login` | `GetLogin` | `Account=account`, `Password=password`, `Kind=android` | Legacy JSON -> `user` + token payload |
| `POST /v1/auth/refresh` | N/A | Redis rotation only | New access/refresh |
| `POST /v1/auth/logout` | N/A | Redis revoke only | `{ revoked, subject }` |
| `GET /v1/bootstrap/webview` | N/A | Uses account + identify to build cookies | `baseUrl/registerUrl/resetPasswordUrl/cookies` |
| `GET /v1/bootstrap/bulletin` | `GetBulletin` | No SOAP request fields | `message/hasAnnouncement/updatedAt` |
| `POST /v1/push/register` | `UpdateRegID` | `DNUM=contractNo`, `RegID=fcmToken`, `Kind=Android|ios`, `Version=appVersion` | `{ ok, registeredAt }` |
| `POST /v1/push/unregister` | `DeleteRegID` | `Contract=contractNo`, `RegID=fcmToken` | `{ ok, unregisteredAt }` |
| `GET /v1/shipments/{trackingNo}` | `GetShipment_elf` then fallback `GetShipment` | `TNUM=trackingNo` | Legacy Chinese fields -> normalized shipment DTO |
| `POST /v1/shipments/{trackingNo}/delivery` | `UpdateArrival` | `DNUM`, `TNUM`, `Image`, `Image_FN`, `Itude=lat,lng` | `{ ok: true }` |
| `POST /v1/shipments/{trackingNo}/exception` | `UpdateArrivalErr_NEW` | `DNUM`, `TNUM`, `Image`, `Image_FN`, `Itude=lat,lng` | `{ ok: true }` |
| `GET /v1/reservations?mode=standard` | `GetARVed` | `DNUM=contractNo` | Legacy rows -> normalized reservation DTO[] |
| `GET /v1/reservations?mode=bulk` | `GetBARVed` | `DNUM=contractNo` | Legacy rows -> normalized reservation DTO[] |
| `POST /v1/reservations?mode=standard` | `UpdateARV` | `NUMs=shipmentNos.join(',')`, `Addr=address`, `DNUM=contractNo` | `{ reservationNo, mode }` |
| `POST /v1/reservations?mode=bulk` | `UpdateBARV` | `NUM=shipmentNos[0]`, `Addr=address`, `FEE=fee`, `DNUM=contractNo` | `{ reservationNo, mode }` |
| `DELETE /v1/reservations/{id}?mode=standard` | `RemoveARV` | `NUMs=id`, `Addr=address`, `DNUM=contractNo` | `{ ok: true }` |
| `DELETE /v1/reservations/{id}?mode=bulk` | `RemoveBARV` | `NUM=id`, `Addr=address`, `DNUM=contractNo` | `{ ok: true }` |
| `GET /v1/proxy/mates?area=...` | `GetPxymate` | `Area=area` | `{ items: ProxyMateItem[] }` |
| `GET /v1/proxy/kpi/search?year=...&month=...&area=...` | `SearchKPI` | `Year=year`, `Month=month`, `Area=area` | `{ items: ProxyKpiItem[] }` |
| `GET /v1/proxy/kpi?year=...&month=...&area=...` | `GetKPI` | `Year=year`, `Month=month`, `Area=area` | `{ items: ProxyKpiItem[] }` |
| `GET /v1/proxy/kpi/daily?date=...&area=...` | `GetKPI_dis` | `DD=date`, `Area=area` | `{ items: ProxyKpiItem[] }` |
| `GET /v1/currency/daily?date=...` | `GetDriverCurrency` | `DD=date`, `DNUM=contractNo` | `{ items: CurrencyItem[] }` |
| `GET /v1/currency/monthly?date=...` | `GetDriverCurrencyMonth` | `DD=date`, `DNUM=contractNo` | `{ items: CurrencyItem[] }` |
| `GET /v1/currency/balance` | `GetDriverBalance` | `DNUM=contractNo` | `{ items: CurrencyItem[] }` |
| `GET /v1/currency/deposit/head?startDate=...&endDate=...` | `GetDeposit_Head` | `StartDate=startDate`, `EndDate=endDate`, `DNUM=contractNo` | `{ items: CurrencyItem[] }` |
| `GET /v1/currency/deposit/body?tnum=...&address=...` | `GetDeposit_Body` | `TNUM=tnum`, `Addr=address`, `DNUM=contractNo` | `{ items: CurrencyItem[] }` |
| `GET /v1/currency/shipment?orderNum=...` | `GetShipment_Currency` | `OrderNum=orderNum` | `{ items: CurrencyItem[] }` |
| `GET /v1/reservations/zip-areas` | `GetARV_ZIP` | no request fields | `{ items: ReservationSupportItem[] }` |
| `GET /v1/reservations/available?zip=...` | `GetARV` | `ZIP=zip`, `DNUM=contractNo` | `{ items: ReservationSupportItem[] }` |
| `GET /v1/reservations/available/bulk?zip=...` | `GetBARV` | `ZIP=zip`, `DNUM=contractNo` | `{ items: ReservationSupportItem[] }` |
| `GET /v1/reservations/area-codes` | `GetAreaCode` | `DNUM=contractNo` | `{ items: ReservationSupportItem[] }` |
| `GET /v1/reservations/arrived` | `GetArrived` | `DNUM=contractNo` | `{ items: ReservationSupportItem[] }` |
| `GET /v1/system/version?name=...` | `GetVersion` | `Name=name` | `{ name, versionCode }` |

## 3. Identity and cookies
1. `Account` = account identifier.
2. `Identify` = `Base64(SHA-512(password bytes))`.
3. `Kind` = `android`.

## 4. Legacy transport settings (UAT baseline)
1. SOAP base URL: `https://old.huoduoduo.com.tw`
2. SOAP namespace: `https://driver.huoduoduo.com.tw/`
3. SOAP path: `/Inquiry/didiservice.asmx`

## 5. P0 normalization policy
1. Contract length constraints are defined in OpenAPI (`maxLength` / `maxItems`).
2. For legacy payload overflow:
   1. identity/code fields: reject with `LEGACY_BAD_RESPONSE`.
   2. free-text message fields: truncate to contract max length.
3. P0 defines policy only; runtime enforcement is implemented in later phases.

## 6. P1 implementation note
1. P1 contract enforcement is implemented for:
   1. `POST /v1/auth/login`
   2. `POST /v1/auth/refresh`
   3. `POST /v1/auth/logout`
   4. `GET /v1/bootstrap/webview`
   5. `GET /v1/bootstrap/bulletin`
   6. `POST /v1/push/register`
2. Runtime behavior follows P0 policy:
   1. critical structural fields -> reject with `LEGACY_BAD_RESPONSE`.
   2. text display fields (`user.name`, bulletin `message`) -> truncate.

## 7. P2 implementation note
1. Response contract enforcement is implemented for `GET /v1/shipments/{trackingNo}`.
2. `POST /v1/shipments/{trackingNo}/delivery` and `/exception`:
   1. request DTO `MaxLength` validation is added.
   2. response shape remains `{ ok: true }`.

## 8. P3 implementation note
1. Response contract enforcement is implemented for `GET /v1/reservations`.
2. `POST /v1/reservations` and `DELETE /v1/reservations/{id}`:
   1. request DTO validation adds `MaxLength` / `ArrayMaxSize`.
   2. create response contract enforcement is applied (`reservationNo`, `mode`).

## 9. P4 implementation note
1. Cross-cutting error output is normalized to `{ code, message }`.
2. Legacy error-code semantics are preserved:
   1. `LEGACY_TIMEOUT`
   2. `LEGACY_BAD_RESPONSE`
   3. `LEGACY_BUSINESS_ERROR`
3. Health response contract enforcement is implemented for `GET /v1/health`.

## 10. P5 implementation note
1. Proxy/KPI equivalent mapping is implemented for:
   1. `GET /v1/proxy/mates`
   2. `GET /v1/proxy/kpi/search`
   3. `GET /v1/proxy/kpi`
   4. `GET /v1/proxy/kpi/daily`
2. Query validation applies `MaxLength` and format guards for `area/year/month/date`.
3. Response contract enforcement applies structural-field reject + message truncation.

## 11. P6 implementation note
1. Currency query equivalent mapping is implemented for:
   1. `GET /v1/currency/daily`
   2. `GET /v1/currency/monthly`
   3. `GET /v1/currency/balance`
   4. `GET /v1/currency/deposit/head`
   5. `GET /v1/currency/deposit/body`
   6. `GET /v1/currency/shipment`
2. Query validation applies `MaxLength` guards for `date/startDate/endDate/tnum/address/orderNum`.
3. Response contract enforcement applies structural-field reject + message truncation.

## 12. P7 implementation note
1. Reservation web-support query mapping is implemented for:
   1. `GET /v1/reservations/zip-areas`
   2. `GET /v1/reservations/available`
   3. `GET /v1/reservations/available/bulk`
   4. `GET /v1/reservations/area-codes`
   5. `GET /v1/reservations/arrived`
2. Query validation applies `MaxLength` guard for `zip`.
3. Response contract enforcement applies structural-field reject + message truncation.

## 13. P9 implementation note
1. Conditional-Go implementation is completed for:
   1. `POST /v1/push/unregister` -> `DeleteRegID`
   2. `GET /v1/system/version` -> `GetVersion`
2. Request validation applies `MaxLength` for:
   1. `push/unregister.fcmToken <= 4096`
   2. `system/version.name <= 64`
3. `GetVersion` response payload is normalized to `{ name, versionCode }` and invalid payloads are rejected with `LEGACY_BAD_RESPONSE`.
