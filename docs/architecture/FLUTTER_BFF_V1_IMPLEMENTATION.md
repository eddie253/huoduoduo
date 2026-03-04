# Flutter + BFF v1 Implementation Baseline

Doc ID: HDD-DOCS-ARCHITECTURE-FLUTTER-BFF-V1-IMPLEMENTATION
Version: v1.0
Owner: BFF Lead
Last Updated: 2026-03-05
Review Status: Draft
CN/EN Pair Link: N/A






## Scope

This document captures what is implemented in this repository for the migration baseline:

1. Monorepo directory layout for Flutter app, BFF gateway, contracts, and ops.
2. BFF endpoint skeleton under `/v1` matching migration API contract.
3. Flutter app shell with login flow and `flutter_inappwebview` bridge adapter.
4. OpenAPI and JS bridge contract documents.
5. CI and security gate baseline files.

## Current status (Wave 2)

- `apps/bff_gateway`: SOAP transport + legacy adapter mapping + Redis-backed refresh token rotation.
- `apps/mobile_flutter`: Flutter app shell with real device id via `device_info_plus` for login payload.
- `contracts/openapi`: initial API contract.
- `contracts/bridge`: bridge v1 contract with error codes.
- `.github/workflows/ci.yml`: CI skeleton for BFF and Flutter.
- `scripts/run-wave2-uat-smoke.ps1`: UAT smoke script for login/bootstrap/refresh/shipment/logout.

## Deferred implementation

1. Integrate scanner/signature/maps native plugins in production mode.
2. Add full parity end-to-end tests against legacy Android UAT flows.
3. Promote secret management from ENV to managed vault provider.

