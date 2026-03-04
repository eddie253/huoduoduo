# iOS Permission Checklist (PLAN10)

Doc ID: HDD-DOCS-ARCHITECTURE-IOS-PERMISSION-CHECKLIST
Version: v1.0
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: Draft
CN/EN Pair Link: N/A






This checklist is used in Mac validation stage before iOS real-device smoke.

## Required Info.plist keys

1. `NSCameraUsageDescription`
2. `NSPhotoLibraryUsageDescription`
3. `NSLocationWhenInUseUsageDescription` (if map flow uses current location)

## Suggested copy baseline

1. Camera: "Used to scan shipment barcodes and capture shipment proof images."
2. Photo Library: "Used to pick shipment proof images for upload."
3. Location: "Used to open map/navigation flows for delivery tasks."

## Validation steps (Mac)

1. Confirm keys exist in `ios/Runner/Info.plist`.
2. Run `flutter build ios --no-codesign`.
3. Install to test device and verify permission prompts appear on first use.
4. Verify denial paths do not crash app and show fallback guidance.

## Acceptance Checklist

- [ ] AC-01: Governance header is complete
  - Command: Get-Content "docs/architecture/IOS_PERMISSION_CHECKLIST.md" -Encoding UTF8 -TotalCount 40
  - Expected Result: six governance fields are visible.
  - Failure Action: add missing governance fields and rerun.

- [ ] AC-02: Command rerun capability
  - Command: docker compose -f ops/docker/docker-compose.yml config
  - Expected Result: no error.
  - Failure Action: use PowerShell fallback (Get-Content, Select-String) to verify file state.

