# Architecture Docs Index

Doc ID: HDD-DOCS-ARCHITECTURE-README
Version: v1.3
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: Draft
CN/EN Pair Link: N/A






## Active baseline

1. `FLUTTER_BFF_V1_IMPLEMENTATION.md`
2. `WAVE2_UAT_EVIDENCE.md`
3. `LEGACY_BASELINE_FREEZE.md`
4. `WAVE3_WAVE4_FOUNDATION_EVIDENCE.md`

## Wave execution specs

1. `WAVE3_EXECUTION_SPEC.md`
2. `CONTRACT_VERIFICATION_CHECKLIST.zh-TW.md`
3. `WAVE4_NATIVE_PARITY_MATRIX.md`
4. `E2E_SMOKE_RUNBOOK.md`
5. `LOCAL_MEDIA_STORAGE_SECURITY_SPEC.md`
6. `WAVE4_WEBVIEW_CACHE_POLICY.md`
7. `LOCATION_NAVIGATION_ENTRY_INVENTORY.md`

## Governance

1. `DOCS_REORGANIZATION_MATRIX.md`
2. `WORKSPACE_SETTINGS_PROTECTION.zh-TW.md`
3. `blueprint/DOC_GOVERNANCE_REMEDIATION_RULES.zh-TW.md`
4. `blueprint/DOC_REMEDIATION_MANIFEST_20260305.zh-TW.md`

## Naming And Compliance Status

1. Governance header coverage: `149/149` completed (current inventory increased to `150` after manifest generation).
2. Policy/contract checklist coverage: completed for required scope.
3. Readability remediation: completed for suspected garbled files listed in remediation report.

## Canonical Mapping

1. `docs/plans/PLAN14.md` is canonical; `docs/architecture/PLAN14-REFERENCE.md` is archived reference.
2. `docs/architecture/CONTRACT_VERIFICATION_CHECKLIST.zh-TW.md` + `.en.md` are canonical; `docs/architecture/CONTRACT_VERIFICATION_CHECKLIST_REFERENCE.md` is archived reference.
3. Naming standard canonical path: `docs/plans/PLAN_NAMING_STANDARD.zh-TW.md`.

## Usage rule

1. Start implementation from `WAVE3_EXECUTION_SPEC.md` or `WAVE4_NATIVE_PARITY_MATRIX.md`.
2. Record execution evidence in `WAVE2_UAT_EVIDENCE.md` (or next wave evidence file when created).
3. Runtime execution outputs are stored under `reports/output/`.
4. Long-lived test docs/scripts are under `tests/` (entry: `tests/INDEX.md`).
5. Generated document exports (for example PDF) are under `reports/output/pdf/`.
6. Keep this folder as the single architecture source of truth.

