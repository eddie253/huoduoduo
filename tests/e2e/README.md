# E2E Docs

Doc ID: HDD-TESTS-E2E-README
Version: v1.1
Owner: QA Lead
Last Updated: 2026-03-05
Review Status: In Review
CN/EN Pair Link: N/A

Store Playwright E2E scenario docs, runbooks, and command references here.

## Recommended Files

1. `E2E_SCENARIO_MATRIX.zh-TW.md`
2. `E2E_RUNBOOK.zh-TW.md`
3. `E2E_FAILURE_TRIAGE.zh-TW.md`

## Command Baseline

1. Docker first: `docker compose -f ops/docker/docker-compose.yml config`
2. PowerShell fallback: `powershell -ExecutionPolicy Bypass -File .\tests\scripts\run-e2e-smoke.ps1`
