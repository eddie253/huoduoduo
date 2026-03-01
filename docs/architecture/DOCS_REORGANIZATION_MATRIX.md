# Docs Reorganization Matrix

## Purpose

This file is the single checklist for deciding which docs are:

1. Kept in repository and maintained.
2. Local-only reference (not pushed).
3. Archived/deprecated.

## Keep in Repository (maintain)

| Path | Why keep | Owner |
|---|---|---|
| `docs/architecture/FLUTTER_BFF_V1_IMPLEMENTATION.md` | Current architecture baseline | Architecture |
| `docs/architecture/WAVE2_UAT_EVIDENCE.md` | UAT execution evidence | QA / Backend |
| `docs/architecture/LEGACY_BASELINE_FREEZE.md` | Legacy read-only policy | Architecture |
| `docs/architecture/WAVE3_EXECUTION_SPEC.md` | Wave 3 execution source | Architecture |
| `docs/architecture/CONTRACT_VERIFICATION_CHECKLIST.md` | Contract gate checklist | Backend/Mobile |
| `docs/architecture/WAVE4_NATIVE_PARITY_MATRIX.md` | Wave 4 parity tracker | Mobile |
| `docs/architecture/E2E_SMOKE_RUNBOOK.md` | End-to-end smoke SOP | QA |
| `docs/security/MASVS_ASVS_MAPPING_V1.md` | Security control mapping | Security |
| `docs/adr/0001-strangler-parallel-adoption.md` | Decision record | Architecture |
| `contracts/openapi/huoduoduo-v1.openapi.yaml` | API source contract | Backend |
| `contracts/bridge/js-bridge-v1.md` | Bridge source contract | Mobile |
| `contracts/legacy/soap-mapping-v1.md` | Legacy integration mapping | Backend |
| `contracts/legacy/bridge-matrix-v1.md` | Legacy bridge parity matrix | Mobile |
| `contracts/legacy/error-code-mapping-v1.md` | Error normalization contract | Backend/Mobile |

## Local-only (do not push)

| Path | Reason |
|---|---|
| `docs_local/legacy_docs/ARCHITECTURE_WEBVIEW_CACHE.md` | Legacy implementation notes, low ongoing value |
| `docs_local/legacy_docs/AUTOMATION_TESTING.md` | Legacy testing context, replaced by wave smoke + CI |
| `docs_local/legacy_docs/NETWORK_IP_PORT_MAPPING.md` | One-time environment note |
| `docs_local/legacy_docs/NETWORK_ROUTE_TEST_REPORT_2026-02-28.md` | Historical snapshot |
| `docs_local/legacy_docs/NETWORK_SUMMARY_REPORT_2026-02-28.md` | Historical snapshot |
| `docs_local/legacy_docs/OUTBOUND_ENDPOINTS_AUDIT.md` | Legacy audit snapshot (not active source of truth) |
| `docs_local/legacy_docs/LEGACY_BASELINE_MANIFEST.txt` | Generated artifact (changes by run) |

## Archive / Deprecated rule

A doc should be moved out of active set when:

1. It is not referenced by CI, test, release, or architecture decision.
2. It duplicates contract files under `contracts/`.
3. It cannot be verified by current codebase.

## Review cadence

1. Review at each wave close (Wave 3, Wave 4, ...).
2. Keep only docs that are executable or audit-relevant.
