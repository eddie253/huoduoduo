# Legacy 42-Method Status Matrix (PLAN24)

Doc ID: `HDD-LEGACY-42-MATRIX`
Version: `v1.1`
Owner: `Architecture Lead`
Last Updated: 2026-03-05
Review Status: Archived
CN/EN Pair Link: N/A






1. CN: `docs/architecture/LEGACY_API_42_STATUS_MATRIX_20260303.zh-TW.md`
2. EN: `docs/architecture/LEGACY_API_42_STATUS_MATRIX_20260303.en.md`

Date: 2026-03-03 (Asia/Taipei)

## 1. Definitions
1. `implemented`: mapped in current BFF API and adapter.
2. `waived`: intentionally handled by legacy web routes (WebView), no native API expansion in this phase.
3. `deferred`: not implemented yet, reserved for a later milestone.

## 2. Summary
1. implemented: `13`
2. waived: `17`
3. deferred: `12`
4. total: `42`

## 3. Matrix

| # | Legacy SOAP Method | Legacy URL | Legacy Request Fields | New BFF Endpoint / Replacement Path | Status | Reason | Owner | Target Milestone | Next Action | Waive Re-entry Condition |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `GetLogin` | `/Inquiry/didiservice.asmx` | `Account, Password, Kind` | `POST /v1/auth/login` | `implemented` | Core login flow is live | BFF Lead | `P0` | Keep contract tests | `-` |
| 2 | `UpdateRegID` | `/Inquiry/didiservice.asmx` | `DNUM, RegID, Kind, Version` | `POST /v1/push/register` | `implemented` | Push registration API is available | BFF Lead | `P1` | Wire Flutter client in P1 | `-` |
| 3 | `DeleteRegID` | `/Inquiry/didiservice.asmx` | `Contract, RegID` | `-` | `deferred` | Out of current login scope | BFF Lead | `P4` | Evaluate logout un-register API | `-` |
| 4 | `UpdateBank` | `/Inquiry/didiservice.asmx` | `DNUM, Code, Account` | `WebView: /app/currency/bank.aspx` | `waived` | Legacy behavior is web-based | Mobile Lead | `P4 review` | Keep WebView route | Re-open only if web flow is retired |
| 5 | `AddOrder_elf` | `/Inquiry/didiservice.asmx` | `DNUM, TNUM` | `-` | `deferred` | No native accept-order flow in new app | Product + BFF Lead | `P2` | Define order-accept use cases | `-` |
| 6 | `BackOrder` | `/Inquiry/didiservice.asmx` | `DNUM, TNUM` | `-` | `deferred` | No native back-order flow in new app | Product + BFF Lead | `P2` | Define status/error model | `-` |
| 7 | `GetShipment` | `/Inquiry/didiservice.asmx` | `TNUM` | `GET /v1/shipments/{trackingNo} (fallback)` | `implemented` | Fallback path is active | BFF Lead | `P0` | Keep fallback tests | `-` |
| 8 | `GetShipment_elf` | `/Inquiry/didiservice.asmx` | `TNUM` | `GET /v1/shipments/{trackingNo} (primary)` | `implemented` | Primary shipment lookup is active | BFF Lead | `P0` | Keep contract stable | `-` |
| 9 | `GetShipment_Currency` | `/Inquiry/didiservice.asmx` | `OrderNum` | `WebView: /app/currency/*.aspx` | `waived` | Currency flow is fully web-based | Mobile Lead | `P4 review` | Keep WebView route | Re-open when equivalent BFF API exists |
| 10 | `UpdateArrivalErr_NEW` | `/Inquiry/didiservice.asmx` | `DNUM, TNUM, Image, Image_FN, Itude` | `POST /v1/shipments/{trackingNo}/exception` | `implemented` | Single exception upload is live | BFF Lead | `P0` | Keep upload contract tests | `-` |
| 11 | `UpdateArrivalErr_Multi_NEW` | `/Inquiry/didiservice.asmx` | `DNUM, TNUM, Image, Image_FN, Itude` | `-` | `deferred` | Batch upload requirement not finalized | Product + BFF Lead | `P2` | Define batch UX and retry policy | `-` |
| 12 | `ClearArrival` | `/Inquiry/didiservice.asmx` | `DNUM, TNUM` | `-` | `deferred` | Clear-arrival flow not in scope | Product Lead | `P3` | Confirm whether behavior is required | `-` |
| 13 | `UpdateArrival` | `/Inquiry/didiservice.asmx` | `DNUM, TNUM, Image, Image_FN, Itude` | `POST /v1/shipments/{trackingNo}/delivery` | `implemented` | Single delivery upload is live | BFF Lead | `P0` | Keep tests green | `-` |
| 14 | `UpdateArrival_Multi` | `/Inquiry/didiservice.asmx` | `DNUM, TNUM, Image, Image_FN, Itude` | `-` | `deferred` | Batch delivery not in current scope | Product + BFF Lead | `P2` | Finalize batch contract first | `-` |
| 15 | `Alr_Order` | `/Inquiry/didiservice.asmx` | `DNUM` | `-` | `deferred` | Legacy native list has no new counterpart | Mobile Lead | `P3` | Decide native vs WebView ownership | `-` |
| 16 | `Alr_Shipment` | `/Inquiry/didiservice.asmx` | `DD, DNUM` | `-` | `deferred` | Delivered list not mapped yet | Mobile Lead | `P3` | Validate usage priority | `-` |
| 17 | `CreatePath` | `/Inquiry/didiservice.asmx` | `StartLatLng, EndLatLng, DNUM` | `-` | `deferred` | Route planning currently out-of-scope | Product Lead | `P4` | Re-evaluate with map roadmap | `-` |
| 18 | `CheckedArrivalErr` | `/Inquiry/didiservice.asmx` | `TNUM, Itude` | `-` | `deferred` | Pre-check flow not implemented | BFF Lead | `P2` | Define data validation contract | `-` |
| 19 | `GetDriverCurrency` | `/Inquiry/didiservice.asmx` | `DD, DNUM` | `WebView: /app/currency/day_cy.aspx` | `waived` | Daily statement is available on web | Mobile Lead | `P4 review` | Keep WebView route | Re-open if web route is removed |
| 20 | `GetDriverCurrencyMonth` | `/Inquiry/didiservice.asmx` | `DD, DNUM` | `WebView: /app/currency/month_cy.aspx` | `waived` | Monthly statement is available on web | Mobile Lead | `P4 review` | Keep WebView route | Same as above |
| 21 | `GetDriverBalance` | `/Inquiry/didiservice.asmx` | `DNUM` | `WebView: /app/currency/wda.aspx` | `waived` | Balance view is web-based | Mobile Lead | `P4 review` | Keep WebView route | Re-open on offline/native requirement |
| 22 | `ApplyWithDrawal` | `/Inquiry/didiservice.asmx` | `DNUM, Money` | `WebView: /app/currency/wda.aspx` | `waived` | Withdrawal flow is web-based | Product Lead | `P4 review` | Keep WebView route | Re-open when compliance requires native |
| 23 | `GetDeposit_Head` | `/Inquiry/didiservice.asmx` | `StartDate, EndDate, DNUM` | `WebView: /app/currency/virtual.aspx` | `waived` | Deposit summary is web-based | Mobile Lead | `P4 review` | Keep WebView route | Re-open if web route is retired |
| 24 | `GetDeposit_Body` | `/Inquiry/didiservice.asmx` | `TNUM, Addr, DNUM` | `WebView: /app/currency/virtual.aspx` | `waived` | Deposit detail is web-based | Mobile Lead | `P4 review` | Keep WebView route | Same as above |
| 25 | `GetARV_ZIP` | `/Inquiry/didiservice.asmx` | `(none)` | `WebView: /app/rvt/df_area.aspx` | `waived` | Reservation area flow is web-based | Mobile Lead | `P4 review` | Keep WebView route | Re-open only if reservation goes native |
| 26 | `GetARV` | `/Inquiry/didiservice.asmx` | `ZIP, DNUM` | `WebView: /app/rvt/ge.aspx` | `waived` | Reservable list is web-based | Mobile Lead | `P4 review` | Keep WebView route | Same as above |
| 27 | `GetARVed` | `/Inquiry/didiservice.asmx` | `DNUM` | `GET /v1/reservations?mode=standard` | `implemented` | API already available | BFF Lead | `P1` | Decide Flutter wiring priority | `-` |
| 28 | `UpdateARV` | `/Inquiry/didiservice.asmx` | `NUMs, Addr, DNUM` | `POST /v1/reservations?mode=standard` | `implemented` | API already available | BFF Lead | `P1` | Keep tests and plan wiring | `-` |
| 29 | `RemoveARV` | `/Inquiry/didiservice.asmx` | `NUMs, Addr, DNUM` | `DELETE /v1/reservations/{id}?mode=standard&address=...` | `implemented` | API already available | BFF Lead | `P1` | Keep tests and plan wiring | `-` |
| 30 | `GetAreaCode` | `/Inquiry/didiservice.asmx` | `DNUM` | `WebView: /app/rvt/df_area.aspx` | `waived` | Area-code flow is web-based | Mobile Lead | `P4 review` | Keep WebView route | Re-open when reservation becomes native |
| 31 | `GetArrived` | `/Inquiry/didiservice.asmx` | `DNUM` | `WebView: /app/inq/arv.aspx` | `waived` | Arrived list is web-based | Mobile Lead | `P4 review` | Keep WebView route | Re-open if web route is removed |
| 32 | `GetBARV` | `/Inquiry/didiservice.asmx` | `ZIP, DNUM` | `WebView: /app/rvt/bh.aspx` | `waived` | Bulk reservation list is web-based | Mobile Lead | `P4 review` | Keep WebView route | Re-open when reservation becomes native |
| 33 | `GetBARVed` | `/Inquiry/didiservice.asmx` | `DNUM` | `GET /v1/reservations?mode=bulk` | `implemented` | API already available | BFF Lead | `P1` | Decide Flutter wiring priority | `-` |
| 34 | `UpdateBARV` | `/Inquiry/didiservice.asmx` | `NUM, Addr, FEE, DNUM` | `POST /v1/reservations?mode=bulk` | `implemented` | API already available | BFF Lead | `P1` | Decide Flutter wiring priority | `-` |
| 35 | `RemoveBARV` | `/Inquiry/didiservice.asmx` | `NUM, Addr, DNUM` | `DELETE /v1/reservations/{id}?mode=bulk&address=...` | `implemented` | API already available | BFF Lead | `P1` | Decide Flutter wiring priority | `-` |
| 36 | `GetPxymate` | `/Inquiry/didiservice.asmx` | `Area` | `WebView: /app/pxy/mate.aspx` | `waived` | Proxy flow is web-based | Mobile Lead | `P4 review` | Keep `/proxy-menu` -> web | Re-open only for native proxy UI roadmap |
| 37 | `SearchKPI` | `/Inquiry/didiservice.asmx` | `Year, Month, Area` | `WebView: /app/pxy/kpi.aspx` | `waived` | KPI query flow is web-based | Mobile Lead | `P4 review` | Keep WebView route | Re-open for native KPI reporting roadmap |
| 38 | `GetKPI` | `/Inquiry/didiservice.asmx` | `Year, Month, Area` | `WebView: /app/pxy/kpi.aspx` | `waived` | KPI month data is web-based | Mobile Lead | `P4 review` | Keep WebView route | Same as above |
| 39 | `GetKPI_dis` | `/Inquiry/didiservice.asmx` | `DD, Area` | `WebView: /app/pxy/kpi.aspx` | `waived` | KPI daily detail is web-based | Mobile Lead | `P4 review` | Keep WebView route | Same as above |
| 40 | `GetSystemDate` | `/Inquiry/didiservice.asmx` | `format` | `-` | `deferred` | New system mostly uses server time headers | BFF Lead | `P4` | Add only if strict dependency appears | `-` |
| 41 | `GetVersion` | `/Inquiry/didiservice.asmx` | `Name` | `-` | `deferred` | Version policy is release-process driven | Mobile Lead | `P4` | Decide if dedicated version API is needed | `-` |
| 42 | `GetBulletin` | `/Inquiry/didiservice.asmx` | `(none)` | `GET /v1/bootstrap/bulletin` | `implemented` | Bulletin API is live | BFF Lead | `P0` | Keep mapping and tests up to date | `-` |

## 4. Notes
1. Method universe is the 42 SOAP methods from legacy Android `network/*.java`.
2. Every row contains `status/reason/owner/target milestone` as required by P0 governance.
3. `waived` rows include explicit re-entry conditions for future re-evaluation.

## Governance Waiver

- Reason: historical document retained for traceability under archive_waiver policy.
- Owner: Architecture Lead
- Original Date: N/A
- Retention: long-term archive retention.
- Reactivation Trigger: audit or historical trace request.

