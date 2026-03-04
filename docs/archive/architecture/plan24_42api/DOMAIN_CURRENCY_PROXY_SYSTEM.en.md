# DOMAIN: Currency / Proxy / System

Doc ID: HDD-DOC-ARCHITECTURE-PLAN24-42API-DOMAIN-CURRENCY-PROXY-SYSTEM-EN
Version: v1.0
Owner: Project Lead
Last Updated: 2026-03-05
Review Status: Archived
CN/EN Pair Link: docs/archive/architecture/plan24_42api/DOMAIN_CURRENCY_PROXY_SYSTEM.zh-TW.md







1. CN: `docs/architecture/plan24_42api/DOMAIN_CURRENCY_PROXY_SYSTEM.zh-TW.md`
2. EN: `docs/architecture/plan24_42api/DOMAIN_CURRENCY_PROXY_SYSTEM.en.md`

## 1. In-scope Methods
1. Currency:
   1. implemented in P6 (query): `GetShipment_Currency`, `GetDriverCurrency`, `GetDriverCurrencyMonth`, `GetDriverBalance`, `GetDeposit_Head`, `GetDeposit_Body`
   2. still waived (write): `UpdateBank`, `ApplyWithDrawal`
2. Proxy/KPI (implemented in P5): `GetPxymate`, `SearchKPI`, `GetKPI`, `GetKPI_dis`
3. System:
   1. implemented in P9: `GetVersion`
   2. deferred: `GetSystemDate`

## 2. Batch Strategy
1. P5: Proxy + KPI conversion is completed (no business-logic change).
2. P6: Currency query APIs are implemented; write APIs remain in read/write governance split.
3. P8: System deferred decision gate.
4. P9: Conditional-Go implementation completed for `GetVersion`.

## 3. Fixed P5 Endpoints
1. `GET /v1/proxy/mates?area=...`
2. `GET /v1/proxy/kpi/search?year=...&month=...&area=...`
3. `GET /v1/proxy/kpi?year=...&month=...&area=...`
4. `GET /v1/proxy/kpi/daily?date=...&area=...`

## 4. Fixed P6 Endpoints
1. `GET /v1/currency/daily?date=...`
2. `GET /v1/currency/monthly?date=...`
3. `GET /v1/currency/balance`
4. `GET /v1/currency/deposit/head?startDate=...&endDate=...`
5. `GET /v1/currency/deposit/body?tnum=...&address=...`
6. `GET /v1/currency/shipment?orderNum=...`

## 5. Fixed DTO Contract Values
1. `area <= 64`
2. `year <= 4`
3. `month <= 2`
4. `date <= 10` (`YYYY-MM-DD`)
5. response fields: `code/status/role <= 64`, `name/service <= 128`, `message <= 1024`, `datetime <= 40`

## 6. Risk Controls
1. No new aggregation/business-statistic logic; only equivalent legacy mapping.
2. Write APIs (`UpdateBank`, `ApplyWithDrawal`) must not go live before security checks are approved.
3. `GetSystemDate` remains deferred until a hard dependency on API-time endpoint is proven.

## Governance Waiver

- Reason: historical document retained for traceability under archive_waiver policy.
- Owner: Architecture Lead
- Original Date: N/A
- Retention: long-term archive retention.
- Reactivation Trigger: audit or historical trace request.

