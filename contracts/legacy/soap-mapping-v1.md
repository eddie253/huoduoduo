# Legacy SOAP Mapping v1

## Scope

This contract maps BFF REST endpoints to legacy SOAP methods in `didiservice.asmx`.

Legacy references:

1. `app/src/main/java/network/WebService.java`
2. `app/src/main/java/didi/app/express/MainActivity.java`
3. `apps/bff_gateway/src/adapters/soap/legacy-soap.client.ts`

## Endpoint to SOAP mapping

| BFF Endpoint | SOAP Method(s) | Request Mapping | Response Mapping |
|---|---|---|---|
| `POST /v1/auth/login` | `GetLogin` | `Account=account`, `Password=password`, `Kind=android` | Legacy JSON -> `user` + token payload |
| `POST /v1/auth/refresh` | N/A | Redis rotation only | New access/refresh |
| `POST /v1/auth/logout` | N/A | Redis revoke only | `{ revoked }` |
| `GET /v1/bootstrap/webview` | N/A | Uses account + identify to build cookies | `baseUrl/registerUrl/resetPasswordUrl/cookies` |
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

## Identity and cookies

For web bootstrap compatibility, BFF issues cookies equivalent to legacy behavior:

1. `Account` = account identifier.
2. `Identify` = `Base64(SHA-512(password bytes))`.
3. `Kind` = `android`.

## Legacy transport settings (UAT baseline)

1. SOAP base URL: `https://old.huoduoduo.com.tw`
2. SOAP namespace: `https://driver.huoduoduo.com.tw/`
3. SOAP path: `/Inquiry/didiservice.asmx`
