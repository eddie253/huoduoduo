# Legacy Baseline Freeze

Doc ID: HDD-DOCS-ARCHITECTURE-LEGACY-BASELINE-FREEZE
Version: v1.0
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: Draft
CN/EN Pair Link: N/A






## Purpose

The legacy Android codebase is now frozen as a read-only baseline.

Frozen scope:

1. `app/`
2. `zbarlibary/`

This baseline is used only for:

1. Behavior parity reference.
2. SOAP contract truth source.
3. JS bridge compatibility reference.

It is no longer a maintenance target.

## Tagging and manifest

Use the freeze script at repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\freeze-legacy-baseline.ps1
```

Default outputs:

1. Tag name: `legacy-android-baseline-2026-03-01`
2. Manifest: `docs/architecture/LEGACY_BASELINE_MANIFEST.txt`

If current workspace has no `.git` metadata, the script still generates the manifest and skips tag creation.

## CI guard

`ops/ci/check-legacy-baseline-readonly.sh` enforces read-only policy in CI.

It fails builds when changes are detected under:

1. `app/`
2. `zbarlibary/`

Temporary override (explicitly opt-in):

`ALLOW_LEGACY_BASELINE_CHANGE=1`

## Ownership

New development must happen in:

1. `apps/mobile_flutter/`
2. `apps/bff_gateway/`
3. `contracts/`

## Acceptance Checklist

- [ ] AC-01: Governance header is complete
  - Command: Get-Content "docs/architecture/LEGACY_BASELINE_FREEZE.md" -Encoding UTF8 -TotalCount 40
  - Expected Result: six governance fields are visible.
  - Failure Action: add missing governance fields and rerun.

- [ ] AC-02: Command rerun capability
  - Command: docker compose -f ops/docker/docker-compose.yml config
  - Expected Result: no error.
  - Failure Action: use PowerShell fallback (Get-Content, Select-String) to verify file state.

