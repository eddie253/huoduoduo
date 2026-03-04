# PLAN19: Scanner UI Legacy Parity Lockdown

Doc ID: HDD-DOCS-PLANS-PLAN19
Version: v1.0
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: Draft
CN/EN Pair Link: N/A






## Summary
1. Goal: keep scanner UI and interaction aligned with legacy style while preserving the current refactor safety and testability.
2. Principle: no business behavior change, no route contract change, no plugin replacement.
3. Delivery mode: visual parity first, then regression-proof test/evidence closure.

## Scope
1. `apps/mobile_flutter/lib/features/scanner/presentation/scanner_page.dart` visual and interaction parity.
2. Scanner-related tests under `apps/mobile_flutter/lib/features/scanner/` (colocated).
3. Plan and evidence documentation updates for PLAN19.

## Out Of Scope
1. Map/navigation preflight flow changes.
2. Signature/shipment/settings feature redesign.
3. BFF API or contract modifications.

## Baseline (2026-03-03)
1. Flutter overall line coverage: `66.75% (1285/1925)`.
2. `scanner_page.dart` line coverage: `74.42% (32/43)`.
3. Current scanner flow already enforces:
   1. close button returns.
   2. non-empty scan result completes.
   3. completion pop happens only once.

## Evidence (Before)
1. Legacy scanner reference:
   1. `zbarlibary/src/main/res/layout/activity_qr.xml`
   2. `zbarlibary/src/main/java/shiyue/core/QRActivity.java`
   3. `zbarlibary/src/main/java/shiyue/core/QrConfig.java`
2. Locked style tokens from legacy:
   1. top header color `#ff5f00`
   2. white title text and left back affordance
   3. visible white hint text
   4. bottom tool row with three icon slots (flash/keypad/settings)
3. Flutter scanner invariants before edit:
   1. `/scanner` route contract unchanged (`scanType` in, scanned value out)
   2. close action pops page
   3. valid scan completes only once

## Implementation Plan
### M19-A: Legacy UI Baseline Freeze
1. Freeze scanner baseline references from current legacy expectation:
   1. AppBar title format.
   2. close icon placement and behavior.
   3. bottom hint card style and wording.
2. Record baseline in PLAN19 evidence section before edits.

### M19-B: Scanner UI Parity Alignment
1. Align scanner typography, spacing, icon sizing, and container visual style to legacy baseline.
2. Keep route/API unchanged:
   1. `/scanner` input: `scanType`.
   2. output: scanned string payload via `Navigator.pop`.
3. Keep existing testability seam (`scannerViewBuilder`) and pure helper (`firstNonEmptyBarcodeValue`).

### M19-C: Behavior Invariant Guard
1. Preserve behavior invariants:
   1. empty/blank code must not complete.
   2. valid code completes exactly once.
   3. close action always returns.
2. Validate no duplicate pops and no accidental multi-complete race.

### M19-D: Test Hardening
1. Maintain and extend scanner widget tests:
   1. scanType rendering.
   2. close pop.
   3. empty scan ignored.
   4. valid scan pop once.
2. Add one route-level assertion (`/scanner` extra parsing) if needed.
3. Ensure tests do not require real camera hardware.

### M19-E: Docs and Evidence Closure
1. Update `docs/architecture/WAVE3_WAVE4_FOUNDATION_EVIDENCE.md` with PLAN19 result summary.
2. Link scanner parity outcome to this plan file.
3. Keep coverage policy unchanged (threshold remains `>=65` from PLAN18).

## Test Cases
1. `Scanner (scanType)` title displays expected value.
2. close icon pops current page.
3. blank scan value does not pop.
4. two rapid valid callbacks still pop once.
5. hint text remains visible and unchanged for legacy parity.

## Acceptance Criteria
1. `flutter analyze`: PASS.
2. `flutter test`: PASS.
3. `npm run mobile:test:coverage`: PASS.
4. `npm run mobile:coverage:check`: PASS with threshold `65`.
5. Scanner UI and interaction match legacy acceptance checklist.

## Risks And Mitigations
1. Risk: visual drift due to theme/token changes.
   1. Mitigation: lock scanner-specific style tokens and verify via test checklist.
2. Risk: plugin rendering variation across devices.
   1. Mitigation: test behavior on widget layer and run one emulator smoke check.

## Assumptions
1. Legacy scanner parity target is defined by existing in-app baseline and current acceptance wording.
2. No requirement to redesign scanner UX in this plan.
3. Existing coverage gate (`65`) remains mandatory and must not be lowered.

## Result (After Implementation)
1. `scanner_page.dart` now uses legacy-style structure:
   1. orange top bar (`#ff5f00`) with white title and left back action
   2. white hint text kept unchanged: `Point the camera to barcode or QR code`
   3. bottom three-slot tool row (flashlight/keypad/settings)
2. Behavior invariants are preserved:
   1. blank scan is ignored
   2. first valid scan pops once and returns payload
   3. close action pops immediately
3. Test status:
   1. `flutter test lib/features/scanner/presentation/scanner_page_test.dart` -> PASS
   2. `npm run mobile:test:coverage` -> PASS (`66.79%`, `1289/1930`)
   3. `npm run mobile:coverage:check` -> PASS (threshold `65`)
4. Coverage snapshot after PLAN19:
   1. Flutter overall line coverage: `66.79% (1289/1930)`
   2. `scanner_page.dart` line coverage: `77.08% (37/48)`

