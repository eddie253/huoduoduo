# PLAN22: Legacy Android Feature Parity Closure

Doc ID: HDD-DOC-PLANS-PLAN22
Version: v1.0
Owner: Project Lead
Last Updated: 2026-03-05
Review Status: Archived
CN/EN Pair Link: N/A







## Goal
Close remaining legacy Android feature mapping gaps in Flutter without expanding product scope.

## Scope
1. Android parity only.
2. Legacy boundary rule: native stays native, web stays web.
3. Complete test and coverage evidence package.

## Implementation Summary
1. Added routes:
   1. `/arrival-upload-errors`
   2. `/proxy-menu`
2. Added pages:
   1. `ArrivalUploadErrorsPage`
   2. `ProxyMenuPage`
3. Added orchestrator API:
   1. `retryFailedUploadById(int queueId)`
4. Centralized legacy menu mapping:
   1. `legacy_menu_mapping.dart`
5. Settings page converged to version-only parity.
6. Timeout strategy updated:
   1. `connectTimeout` set to 20 seconds.
   2. timeout-like `connectionError` also maps to friendly timeout hint.
7. Bridge log script improved for:
   1. no device
   2. offline device
   3. unauthorized device

## Validation
1. `npm run mobile:analyze` -> PASS
2. `npm run mobile:test` -> PASS (`143` tests)
3. `npm run mobile:test:coverage` -> PASS
4. `npm run mobile:coverage:check` -> PASS (`65.00%`, `1495/2300`, threshold `65`)
5. `npm run coverage:verify` -> PASS
6. `npm run coverage:html` -> PASS (`reports/coverage/index.html`)

## Report Artifacts
1. `reports/test/plan22_legacy_parity_closure_20260303/PARITY_CLOSURE_REPORT.md`
2. `reports/test/plan22_legacy_parity_closure_20260303/summary.json`
3. command logs in the same folder.

## Waive Notes
1. `NAT-SCANNER`: real-device vendor variance evidence deferred to UAT.
2. `NAT-SIGNATURE`: real-device gesture/file-output variance evidence deferred to UAT.
3. `NAT-MAP-GOOGLE`: permission/app-switch real-device capture deferred to UAT.

## Governance Waiver

- Reason: 歷史文件保留作為稽核與追溯證據，不作為現行實作準據。
- Owner: Architecture Lead
- Original Date: N/A
- Retention: 保留 24 個月或直到有新版正式文件取代。
- Reactivation Trigger: 當稽核、回歸調查或法遵要求需追溯歷史決策時啟用。

