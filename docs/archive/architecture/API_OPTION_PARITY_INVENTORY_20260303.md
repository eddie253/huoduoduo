# API Option / Condition Inventory (Legacy APK vs New Flutter+BFF)

Date: 2026-03-03 (Asia/Taipei)

## 1. Comparison baseline

1. Legacy APK artifact:
   1. `app/build/outputs/apk/debug/app-debug.apk` (2026-02-28 12:40:49).
2. Legacy source used for APK behavior verification:
   1. `app/src/main/java/network/*.java`
   2. `app/src/main/java/didi/app/express/*.java`
   3. `app/src/main/java/controls/*.java`
3. New API baseline:
   1. `apps/bff_gateway/src/modules/**/*`
   2. `contracts/openapi/huoduoduo-v1.openapi.yaml`
   3. `contracts/legacy/soap-mapping-v1.md`
   4. `apps/mobile_flutter/lib/**/*`

## 2. New BFF API: current options/conditions

### 2.1 Auth

1. `POST /v1/auth/login`
   1. Required: `account`, `password`, `deviceId`, `platform`.
   2. `platform` options: `android | ios`.
2. `POST /v1/auth/refresh`
   1. Required: `refreshToken`.
3. `POST /v1/auth/logout`
   1. Optional body: `refreshToken`.

### 2.2 Bootstrap

1. `GET /v1/bootstrap/webview`
   1. No query option.
   2. Requires bearer token.
2. `GET /v1/bootstrap/bulletin`
   1. No query option.
   2. Requires bearer token.

### 2.3 Push

1. `POST /v1/push/register`
   1. Required: `deviceId`, `platform`, `fcmToken`.
   2. Optional: `appVersion` (integer, >= 0).

### 2.4 Shipment

1. `GET /v1/shipments/{trackingNo}`
   1. Path param: `trackingNo`.
2. `POST /v1/shipments/{trackingNo}/delivery`
   1. Required: `imageBase64`, `imageFileName`, `latitude`, `longitude`.
   2. Optional: `driverId`, `signatureBase64`.
3. `POST /v1/shipments/{trackingNo}/exception`
   1. Required: `imageBase64`, `imageFileName`, `reasonCode`, `latitude`, `longitude`.
   2. Optional: `driverId`, `reasonMessage`.

### 2.5 Reservation

1. `GET /v1/reservations`
   1. Optional query: `mode`.
   2. `mode` options: `standard | bulk` (default `standard`).
2. `POST /v1/reservations`
   1. Optional query: `mode`.
   2. Required body: `address`, `shipmentNos[]`.
   3. Optional body: `areaCode`, `fee`, `note`.
3. `DELETE /v1/reservations/{id}`
   1. Path param: `id`.
   2. Required query: `address`.
   3. Optional query: `mode` (`standard | bulk`, default `standard`).

## 3. Legacy APK SOAP: options/conditions (from old Android module)

### 3.1 `ds001User` (auth/device/bank)

1. `GetLogin`: `Account`, `Password`, `Kind`.
2. `UpdateRegID`: `DNUM`, `RegID`, `Kind`, `Version`.
3. `DeleteRegID`: `Contract`, `RegID`.
4. `UpdateBank`: `DNUM`, `Code`, `Account`.

### 3.2 `ds002貨件` (shipment core)

1. `AddOrder_elf`: `DNUM`, `TNUM`.
2. `BackOrder`: `DNUM`, `TNUM`.
3. `GetShipment`: `TNUM`.
4. `GetShipment_elf`: `TNUM`.
5. `GetShipment_Currency`: `OrderNum`.
6. `UpdateArrivalErr_NEW`: `DNUM`, `TNUM`, `Image`, `Image_FN`, `Itude`.
7. `UpdateArrivalErr_Multi_NEW`: `DNUM`, `TNUM`, `Image`, `Image_FN`, `Itude`.
8. `ClearArrival`: `DNUM`, `TNUM`.
9. `UpdateArrival`: `DNUM`, `TNUM`, `Image`, `Image_FN`, `Itude`.
10. `UpdateArrival_Multi`: `DNUM`, `TNUM`, `Image`, `Image_FN`, `Itude`.
11. `Alr_Order`: `DNUM`.
12. `Alr_Shipment`: `DD`, `DNUM`.
13. `CreatePath`: `StartLatLng`, `EndLatLng`, `DNUM`.
14. `CheckedArrivalErr`: `TNUM`, `Itude`.

### 3.3 `ds003帳戶明細` (currency/deposit/withdraw)

1. `GetDriverCurrency`: `DD`, `DNUM`.
2. `GetDriverCurrencyMonth`: `DD`, `DNUM`.
3. `GetDriverBalance`: `DNUM`.
4. `ApplyWithDrawal`: `DNUM`, `Money`.
5. `GetDeposit_Head`: `StartDate`, `EndDate`, `DNUM`.
6. `GetDeposit_Body`: `TNUM`, `Addr`, `DNUM`.

### 3.4 `ds004預約貨件` (reservation extended)

1. `GetARV_ZIP`: no params.
2. `GetARV`: `ZIP`, `DNUM`.
3. `GetARVed`: `DNUM`.
4. `UpdateARV`: `NUMs`, `Addr`, `DNUM`.
5. `RemoveARV`: `NUMs`, `Addr`, `DNUM`.
6. `GetAreaCode`: `DNUM`.
7. `GetArrived`: `DNUM`.
8. `GetBARV`: `ZIP`, `DNUM`.
9. `GetBARVed`: `DNUM`.
10. `UpdateBARV`: `NUM`, `Addr`, `FEE`, `DNUM`.
11. `RemoveBARV`: `NUM`, `Addr`, `DNUM`.

### 3.5 `ds005代理` (proxy/KPI)

1. `GetPxymate`: `Area`.
2. `SearchKPI`: `Year`, `Month`, `Area`.
3. `GetKPI`: `Year`, `Month`, `Area`.
4. `GetKPI_dis`: `DD`, `Area`.

### 3.6 `WebService` (system/common)

1. `GetSystemDate`: `format`.
2. `GetVersion`: `Name`.
3. `GetBulletin`: no params.

## 4. Parity result (new API vs legacy APK)

### 4.1 Covered (mapped to BFF now)

1. Login (`GetLogin`) -> `/auth/login`.
2. Push register (`UpdateRegID`) -> `/push/register`.
3. Shipment detail (`GetShipment_elf` fallback `GetShipment`) -> `/shipments/{trackingNo}`.
4. Delivery (`UpdateArrival`) -> `/shipments/{trackingNo}/delivery`.
5. Exception (`UpdateArrivalErr_NEW`) -> `/shipments/{trackingNo}/exception`.
6. Reservation list/create/delete (core): `GetARVed/GetBARVed/UpdateARV/UpdateBARV/RemoveARV/RemoveBARV` -> `/reservations`.
7. Bulletin (`GetBulletin`) -> `/bootstrap/bulletin`.

### 4.2 Partial (schema exists but semantic not fully landed)

1. Exception API requires `reasonCode`, but current BFF does not forward it to legacy SOAP (`UpdateArrivalErr_NEW` has no corresponding field in mapping path).
2. Reservation request accepts `areaCode` and `note`, but current service only forwards `address`, `shipmentNos`, `fee`.
3. Delivery request accepts `driverId` and `signatureBase64`, but current service forwards only image + location.

### 4.3 Not mapped to current BFF (legacy existed)

1. Auth/device/bank: `DeleteRegID`, `UpdateBank`.
2. Shipment extra flows: `AddOrder_elf`, `BackOrder`, `GetShipment_Currency`, `UpdateArrivalErr_Multi_NEW`, `ClearArrival`, `UpdateArrival_Multi`, `Alr_Order`, `Alr_Shipment`, `CreatePath`, `CheckedArrivalErr`.
3. Currency/deposit/withdraw full set: `GetDriverCurrency*`, `GetDriverBalance`, `ApplyWithDrawal`, `GetDeposit_*`.
4. Reservation extended: `GetARV_ZIP`, `GetARV`, `GetBARV`, `GetAreaCode`, `GetArrived`.
5. Proxy/KPI: `GetPxymate`, `SearchKPI`, `GetKPI`, `GetKPI_dis`.
6. Common: `GetSystemDate`, `GetVersion`.

## 5. Client usage status (new Flutter app)

1. Flutter currently uses:
   1. `/auth/login`, `/auth/refresh`, `/auth/logout`
   2. `/shipments/{trackingNo}/delivery`, `/shipments/{trackingNo}/exception`
   3. `/bootstrap/bulletin`
2. Flutter currently does not call:
   1. `/push/register`
   2. `/reservations/*`

## 6. Suggested API closure order (for next plan)

1. P0:
   1. Decide whether old native flows (currency/proxy/KPI/deposit/bank) remain webview-only or need BFF API parity.
   2. If keeping webview-only, mark as explicit waive in parity doc to avoid perpetual ambiguity.
2. P1:
   1. Add shipment extended endpoints only if scanner/signature/native workflow still requires them (`AddOrder_elf`, `BackOrder`, `Alr_Order`, `ClearArrival`, `CheckedArrivalErr`).
3. P2:
   1. Align request-body semantics: remove unused fields or actually forward (`reasonCode`, `areaCode`, `note`, `signatureBase64`, `driverId`).
