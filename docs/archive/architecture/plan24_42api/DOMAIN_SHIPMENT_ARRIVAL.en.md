# DOMAIN: Shipment / Arrival

Doc ID: HDD-DOC-ARCHITECTURE-PLAN24-42API-DOMAIN-SHIPMENT-ARRIVAL-EN
Version: v1.0
Owner: Project Lead
Last Updated: 2026-03-05
Review Status: Archived
CN/EN Pair Link: docs/archive/architecture/plan24_42api/DOMAIN_SHIPMENT_ARRIVAL.zh-TW.md







1. CN: `docs/architecture/plan24_42api/DOMAIN_SHIPMENT_ARRIVAL.zh-TW.md`
2. EN: `docs/architecture/plan24_42api/DOMAIN_SHIPMENT_ARRIVAL.en.md`

## 1. In-scope Methods
1. `GetShipment_elf` (primary) + `GetShipment` (fallback) -> `GET /v1/shipments/{trackingNo}`
2. `UpdateArrival` -> `POST /v1/shipments/{trackingNo}/delivery`
3. `UpdateArrivalErr_NEW` -> `POST /v1/shipments/{trackingNo}/exception`
4. deferred: `AddOrder_elf`, `BackOrder`, `UpdateArrivalErr_Multi_NEW`, `ClearArrival`, `UpdateArrival_Multi`, `Alr_Order`, `Alr_Shipment`, `CheckedArrivalErr`

## 2. Current Status
1. implemented: single-item shipment query, delivery upload, and exception upload.
2. deferred: batch and historical-list methods pending product decisions.
3. waived: no new waived scope in this domain.

## 3. Contract Highlights
1. shipment response enforcement (P2) is implemented.
2. delivery/exception request `MaxLength` validation is implemented.
3. after P4, error output contract is unified while preserving legacy error-code semantics.

## 4. Next Actions
1. Batch upload support requires approved UX and retry strategy first.
2. `CheckedArrivalErr` requires a data-rule document before implementation.

## Governance Waiver

- Reason: historical document retained for traceability under archive_waiver policy.
- Owner: Architecture Lead
- Original Date: N/A
- Retention: long-term archive retention.
- Reactivation Trigger: audit or historical trace request.

