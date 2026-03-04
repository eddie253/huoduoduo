# Wave 2 UAT Evidence

Doc ID: HDD-DOCS-ARCHITECTURE-WAVE2-UAT-EVIDENCE
Version: v1.0
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: Draft
CN/EN Pair Link: N/A






## Metadata

- Date: 2026-03-01
- Environment: Local workstation (UAT-target configuration)
- Commit ID: N/A (no `.git` metadata detected in current workspace snapshot)
- Scope: PLAN6 + PLAN8 (UAT smoke convergence + Android host/build readiness)

## PLAN6 Change Summary

1. Updated UAT smoke script to support auto-discovery:
   - `scripts/run-wave2-uat-smoke.ps1`
2. Added optional `TrackingNo` and default `AutoDiscoverTracking=true`.
3. Added reservation-based tracking discovery sequence:
   - `GET /v1/reservations?mode=standard`
   - fallback `GET /v1/reservations?mode=bulk`
4. Added explicit blocked classification:
   - `UAT_DATA_BLOCKED` when no shipment tracking can be discovered.
5. Added smoke output fields:
   - `trackingSource` (`manual|standard-reservation|bulk-reservation|none`)
   - `selectedTrackingNo`
6. Updated BFF README with manual and auto-discovery usage.

## Verification Commands

### BFF quality gate

1. `npm run bff:verify`

### UAT smoke (local Node mode, credential passed by parameter)

1. Start Redis locally (`redis://localhost:6379`)
2. Start BFF locally (`npm --workspace apps/bff_gateway run start:dev`)
3. Run smoke script:
   - `powershell -ExecutionPolicy Bypass -File .\scripts\run-wave2-uat-smoke.ps1 -Account "<masked>" -Password "<masked>"`

## Execution Results

### bff:verify

- Status: PASS
- Result summary:
  - `bff:route-diff`: pass
  - `bff:lint`: pass
  - `bff:test`: pass
  - `bff:build`: pass

### smoke (manual tracking mode)

- Status: PASS
- Account: `A11***669` (masked)
- TrackingNo: `907563299214`
- Execution command:
  - `powershell -ExecutionPolicy Bypass -File .\scripts\run-wave2-uat-smoke.ps1 -Account "<masked>" -Password "<masked>" -TrackingNo "907563299214"`
- Runtime summary:
  - login: PASS
  - bootstrap: PASS
  - refresh: PASS
  - shipment: PASS
  - logout: PASS (`revoked=True`)
- Result fields:
  - `trackingSource=manual`
  - `selectedTrackingNo="907563299214"`
  - `status=PASS`

### smoke (auto-discovery mode)

- Status: BLOCKED
- Account: `A11***669` (masked)
- Execution command:
  - `powershell -ExecutionPolicy Bypass -File .\scripts\run-wave2-uat-smoke.ps1 -Account "<masked>" -Password "<masked>"`
- Runtime summary:
  - login: PASS
  - bootstrap: PASS
  - refresh: PASS
  - reservation discovery:
    - `GET /v1/reservations?mode=standard` -> no usable `shipmentNos[0]`
    - `GET /v1/reservations?mode=bulk` -> no usable `shipmentNos[0]`
  - shipment: SKIPPED (blocked by missing tracking number)
  - logout: PASS (`revoked=True`)
- Result fields:
  - `trackingSource=none`
  - `selectedTrackingNo=""`
  - blocked code: `UAT_DATA_BLOCKED`
  - blocked message: `no shipment tracking found`

## Credential Handling

1. Credential used only in local execution parameters.
2. No credential stored in repository file/script/CI secret.
3. Evidence keeps only masked account representation.

## Conclusion

1. PLAN6 implementation is complete and validated: smoke script now auto-discovers tracking number and classifies data blocking explicitly.
2. Manual UAT smoke is now fully PASS with provided tracking number (`907563299214`).
3. Auto-discovery path remains `BLOCKED (UAT_DATA_BLOCKED)` in current dataset because no discoverable shipment number exists in both standard and bulk reservation lists.

## PLAN8 Execution Evidence

### Flutter host/project readiness

- `apps/mobile_flutter/android` and `apps/mobile_flutter/ios` were created with Flutter standard host scaffolding.
- `flutter build apk --debug` moved from `unsupported Gradle project` to successful APK output:
  - `apps/mobile_flutter/build/app/outputs/flutter-apk/app-debug.apk`

### Flutter quality gates

- `flutter analyze`: PASS (no issues)
- `flutter test`: PASS
- `flutter build apk --debug`: PASS (after one `flutter clean` to resolve Windows file lock in Gradle cache)

### UAT smoke re-run (manual tracking mode)

- Execution mode: docker compose (BFF + Redis) + local smoke script
- Status: PASS
- Account: `A11***669` (masked)
- TrackingNo: `907563299214`
- Runtime summary:
  - login: PASS
  - bootstrap: PASS
  - refresh: PASS
  - shipment: PASS
  - logout: PASS (`revoked=True`)

### iOS status

- iOS host files are present in `apps/mobile_flutter/ios`.
- `flutter build ios --no-codesign` is not executable on this Windows workstation.
- iOS compile and real-device smoke remain pending on Mac runner / macOS workstation.

