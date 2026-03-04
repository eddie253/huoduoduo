# Legacy App API Specification (Final)

Doc ID: `HDD-LEGACY-API-SPEC`
Version: `v1.1`
Owner: `Architecture Lead`
Last Updated: 2026-03-05
Review Status: Archived
CN/EN Pair Link: N/A






1. CN: `docs/architecture/LEGACY_APP_API_SPEC_FINAL.zh-TW.md`
2. EN: `docs/architecture/LEGACY_APP_API_SPEC_FINAL.en.md`

## 1. Purpose (management-friendly)
1. This document is the as-is API specification for the legacy Android app in production.
2. It answers two core questions:
   1. Which URL does the old app call?
   2. Which fields are sent by each API call?
3. This is an inventory baseline. It does not imply full parity in the new app.

## 2. Legacy backend connection baseline

| Item | Value | Source |
|---|---|---|
| API Host | `https://old.huoduoduo.com.tw/` | `MainActivity.API_Host` |
| SOAP Namespace | `https://driver.huoduoduo.com.tw/` | `MainActivity.NAMESPACE` |
| SOAP Endpoint | `https://old.huoduoduo.com.tw/Inquiry/didiservice.asmx` | `WebService.URL` |
| Register/reset web host | `https://old.huoduoduo.com.tw/register/` | `MainActivity.awv_host` |
| Default WebView entry (legacy comment) | `https://app.elf.com.tw/cn/entrust.aspx?IDCompany=S1` | `AppWebView` |

## 3. Transport profile (legacy app)
1. Protocol: SOAP (ksoap2).
2. Invocation pattern: `SOAPAction = Namespace + MethodName`.
3. All SOAP methods are sent to the same endpoint (`didiservice.asmx`).
4. Return shape: `String` (usually JSON string; errors often returned as `Error-...`).

## 4. API catalog (full legacy set)

### 4.1 Account/device/bank (`ds001User`)

| Method | Business meaning | Request fields |
|---|---|---|
| `GetLogin` | Login validation | `Account`, `Password`, `Kind` |
| `UpdateRegID` | Register push token/device | `DNUM`, `RegID`, `Kind`, `Version` |
| `DeleteRegID` | Remove push registration | `Contract`, `RegID` |
| `UpdateBank` | Update bank info | `DNUM`, `Code`, `Account` |

### 4.2 Shipment core (`ds002貨件`)

| Method | Business meaning | Request fields |
|---|---|---|
| `AddOrder_elf` | Accept order | `DNUM`, `TNUM` |
| `BackOrder` | Reject/return order | `DNUM`, `TNUM` |
| `GetShipment` | Shipment lookup (general) | `TNUM` |
| `GetShipment_elf` | Shipment lookup (preferred path) | `TNUM` |
| `GetShipment_Currency` | Lookup by settlement/order number | `OrderNum` |
| `UpdateArrivalErr_NEW` | Upload exception proof (single) | `DNUM`, `TNUM`, `Image`, `Image_FN`, `Itude` |
| `UpdateArrivalErr_Multi_NEW` | Upload exception proof (batch) | `DNUM`, `TNUM`, `Image`, `Image_FN`, `Itude` |
| `ClearArrival` | Clear signed status | `DNUM`, `TNUM` |
| `UpdateArrival` | Upload delivery/signature proof (single) | `DNUM`, `TNUM`, `Image`, `Image_FN`, `Itude` |
| `UpdateArrival_Multi` | Upload delivery/signature proof (batch) | `DNUM`, `TNUM`, `Image`, `Image_FN`, `Itude` |
| `Alr_Order` | Accepted but not-delivered list | `DNUM` |
| `Alr_Shipment` | Delivered list | `DD`, `DNUM` |
| `CreatePath` | Route planning data | `StartLatLng`, `EndLatLng`, `DNUM` |
| `CheckedArrivalErr` | Check exception upload eligibility | `TNUM`, `Itude` |

Notes:
1. `Itude` is a location string, commonly `lat,lng`.
2. `Image` is Base64 content; `Image_FN` is filename.

### 4.3 Currency/withdraw/deposit (`ds003帳戶明細`)

| Method | Business meaning | Request fields |
|---|---|---|
| `GetDriverCurrency` | Daily account statement | `DD`, `DNUM` |
| `GetDriverCurrencyMonth` | Monthly account statement | `DD`, `DNUM` |
| `GetDriverBalance` | Balance | `DNUM` |
| `ApplyWithDrawal` | Withdrawal request | `DNUM`, `Money` |
| `GetDeposit_Head` | Deposit summary | `StartDate`, `EndDate`, `DNUM` |
| `GetDeposit_Body` | Deposit detail | `TNUM`, `Addr`, `DNUM` |

### 4.4 Reservation (`ds004預約貨件`)

| Method | Business meaning | Request fields |
|---|---|---|
| `GetARV_ZIP` | List reservable ZIP/areas | none |
| `GetARV` | List reservable shipments (standard) | `ZIP`, `DNUM` |
| `GetARVed` | List reserved shipments (standard) | `DNUM` |
| `UpdateARV` | Create reservation (standard) | `NUMs`, `Addr`, `DNUM` |
| `RemoveARV` | Cancel reservation (standard) | `NUMs`, `Addr`, `DNUM` |
| `GetAreaCode` | Get area code | `DNUM` |
| `GetArrived` | Arrived-to-warehouse shipments | `DNUM` |
| `GetBARV` | List reservable shipments (bulk/large) | `ZIP`, `DNUM` |
| `GetBARVed` | List reserved shipments (bulk/large) | `DNUM` |
| `UpdateBARV` | Create reservation (bulk/large) | `NUM`, `Addr`, `FEE`, `DNUM` |
| `RemoveBARV` | Cancel reservation (bulk/large) | `NUM`, `Addr`, `DNUM` |

### 4.5 Proxy/KPI (`ds005代理`)

| Method | Business meaning | Request fields |
|---|---|---|
| `GetPxymate` | Proxy teammate list | `Area` |
| `SearchKPI` | KPI search | `Year`, `Month`, `Area` |
| `GetKPI` | KPI monthly data | `Year`, `Month`, `Area` |
| `GetKPI_dis` | KPI daily detail | `DD`, `Area` |

### 4.6 Common/system (`WebService`)

| Method | Business meaning | Request fields |
|---|---|---|
| `GetSystemDate` | Get system date/time | `format` |
| `GetVersion` | Get app/version info | `Name` |
| `GetBulletin` | Get bulletin | none |

## 5. Management summary
1. Total legacy SOAP methods: `42`.
2. All SOAP methods are sent to one endpoint: `/Inquiry/didiservice.asmx`.
3. Most frequent fields:
   1. `DNUM` (contract number)
   2. `TNUM` (tracking number)
   3. `Image` / `Image_FN` / `Itude` (proof upload payloads)

## 6. Legacy web entry URLs (non-SOAP but actively used)

Base:
1. `https://old.huoduoduo.com.tw/app/`

Main routes:
1. Reservation: `rvt/ge.aspx`, `rvt/ge_c.aspx`, `rvt/bh.aspx`, `rvt/bh_c.aspx`, `inq/strg.aspx`, `rvt/df_area.aspx`, `inq/dep.aspx`
2. Shipment: `inq/dtl.aspx`
3. Arrival: `inq/arv.aspx`
4. Currency: `currency/wda.aspx`, `currency/bifm.aspx`, `currency/bank.aspx`, `currency/day_cy.aspx`, `currency/month_cy.aspx`, `currency/virtual.aspx`
5. Proxy: `pxy/mate.aspx`, `pxy/kpi.aspx`
6. Registration flow: `register.aspx`, `register_resetpwd.aspx`, `register_driver_id.aspx`, `register_driver_car.aspx`, `cfs/cfs_sign.aspx`

## 7. External services (additional)
1. TGOS geocoding: `http://addr.tgos.tw/addrws/v40/GeoQueryAddr.asmx`
2. Google Maps Directions/Places APIs

## 8. Source references
1. `app/src/main/java/network/*.java`
2. `app/src/main/java/didi/app/express/MainActivity.java`
3. `app/src/main/java/didi/app/express/AppWebView.java`
4. `app/src/main/java/didi/app/express/Menu_GridView*.java`
5. `app/src/main/java/controls/CheckData.java`

## Governance Waiver

- Reason: historical document retained for traceability under archive_waiver policy.
- Owner: Architecture Lead
- Original Date: N/A
- Retention: long-term archive retention.
- Reactivation Trigger: audit or historical trace request.

