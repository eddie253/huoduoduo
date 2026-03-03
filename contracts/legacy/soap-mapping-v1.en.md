# Legacy SOAP Mapping v1

Doc ID: `HDD-LEGACY-SOAP-MAP`
Version: `v1.4`
Owner: `BFF Lead`
Last Updated: `2026-03-03`
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
| `GET /v1/shipments/{trackingNo}` | `GetShipment_elf` then fallback `GetShipment` | `TNUM=trackingNo` | Legacy Chinese fields -> normalized shipment DTO |
| `POST /v1/shipments/{trackingNo}/delivery` | `UpdateArrival` | `DNUM`, `TNUM`, `Image`, `Image_FN`, `Itude=lat,lng` | `{ ok: true }` |
| `POST /v1/shipments/{trackingNo}/exception` | `UpdateArrivalErr_NEW` | `DNUM`, `TNUM`, `Image`, `Image_FN`, `Itude=lat,lng` | `{ ok: true }` |
| `GET /v1/reservations?mode=standard` | `GetARVed` | `DNUM=contractNo` | Legacy rows -> normalized reservation DTO[] |
| `GET /v1/reservations?mode=bulk` | `GetBARVed` | `DNUM=contractNo` | Legacy rows -> normalized reservation DTO[] |
| `POST /v1/reservations?mode=standard` | `UpdateARV` | `NUMs=shipmentNos.join(',')`, `Addr=address`, `DNUM=contractNo` | `{ reservationNo, mode }` |
| `POST /v1/reservations?mode=bulk` | `UpdateBARV` | `NUM=shipmentNos[0]`, `Addr=address`, `FEE=fee`, `DNUM=contractNo` | `{ reservationNo, mode }` |
| `DELETE /v1/reservations/{id}?mode=standard` | `RemoveARV` | `NUMs=id`, `Addr=address`, `DNUM=contractNo` | `{ ok: true }` |
| `DELETE /v1/reservations/{id}?mode=bulk` | `RemoveBARV` | `NUM=id`, `Addr=address`, `DNUM=contractNo` | `{ ok: true }` |

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
