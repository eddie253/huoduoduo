# Contract Verification Checklist Reference (Archived)

Doc ID: HDD-DOC-ARCH-CONTRACT-CHECKLIST-REFERENCE
Version: v1.0
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: Archived
CN/EN Pair Link: N/A







## Purpose

1. 本檔為 `CONTRACT_VERIFICATION_CHECKLIST` 無語系後綴版本的 reference 檔。
2. canonical 檔案為語系化版本：`*.zh-TW.md` 與 `*.en.md`。

## Canonical Path

1. docs/architecture/CONTRACT_VERIFICATION_CHECKLIST.zh-TW.md
2. docs/architecture/CONTRACT_VERIFICATION_CHECKLIST.en.md

## Governance Waiver

- Reason: 保留舊路徑相容性，避免歷史連結失效。
- Owner: Architecture Lead
- Original Date: N/A
- Retention: 永久保留 reference。
- Reactivation Trigger: 若語系 canonical 路徑再次重構。

## Change Log

1. v1.0 (2026-03-05) - 改為 reference 檔並標記 Archived。

## Acceptance Checklist

- [ ] AC-01: Governance header is complete
  - Command: Get-Content "docs/architecture/CONTRACT_VERIFICATION_CHECKLIST_REFERENCE.md" -Encoding UTF8 -TotalCount 40
  - Expected Result: six governance fields are visible.
  - Failure Action: add missing governance fields and rerun.

- [ ] AC-02: Command rerun capability
  - Command: docker compose -f ops/docker/docker-compose.yml config
  - Expected Result: no error.
  - Failure Action: use PowerShell fallback (Get-Content, Select-String) to verify file state.

