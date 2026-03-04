# DOMAIN: Reservation

Doc ID: HDD-DOC-ARCHITECTURE-PLAN24-42API-DOMAIN-RESERVATION-EN
Version: v1.0
Owner: Project Lead
Last Updated: 2026-03-05
Review Status: Archived
CN/EN Pair Link: docs/archive/architecture/plan24_42api/DOMAIN_RESERVATION.zh-TW.md







1. CN: `docs/architecture/plan24_42api/DOMAIN_RESERVATION.zh-TW.md`
2. EN: `docs/architecture/plan24_42api/DOMAIN_RESERVATION.en.md`

## 1. In-scope Methods
1. implemented:
1. `GetARVed` -> `GET /v1/reservations?mode=standard`
2. `UpdateARV` -> `POST /v1/reservations?mode=standard`
3. `RemoveARV` -> `DELETE /v1/reservations/{id}?mode=standard&address=...`
4. `GetBARVed` -> `GET /v1/reservations?mode=bulk`
5. `UpdateBARV` -> `POST /v1/reservations?mode=bulk`
6. `RemoveBARV` -> `DELETE /v1/reservations/{id}?mode=bulk&address=...`
2. implemented in P7 (web-support query APIs): `GetARV_ZIP`, `GetARV`, `GetAreaCode`, `GetArrived`, `GetBARV`

## 2. Current Status
1. P3 contract convergence is complete (response enforcement + request DTO hardening).
2. reservation list/create/delete already has `maxLength/maxItems` protection.
3. P7 web-support query APIs are implemented.

## 3. Contract Highlights
1. `reservationNo <= 64`
2. `address <= 512`
3. `shipmentNos[] each <= 64`
4. `shipmentNos maxItems <= 200`
5. `mode in [standard, bulk]`

## 4. Next Actions
1. Keep read-only reservation web-support APIs contract-stable.
2. Any flow-state behavior change must be moved to deferred and decided in P8.

## Governance Waiver

- Reason: historical document retained for traceability under archive_waiver policy.
- Owner: Architecture Lead
- Original Date: N/A
- Retention: long-term archive retention.
- Reactivation Trigger: audit or historical trace request.

