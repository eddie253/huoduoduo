# Coverage Docs

Doc ID: HDD-TESTS-COVERAGE-README
Version: v1.1
Owner: QA Lead
Last Updated: 2026-03-05
Review Status: In Review
CN/EN Pair Link: N/A

Store coverage gate notes, threshold decisions, and verification records here.

## Recommended Files

1. `COVERAGE_GATE_POLICY.zh-TW.md`
2. `COVERAGE_CHANGE_LOG.zh-TW.md`
3. `COVERAGE_EXCEPTION_WAIVER.zh-TW.md`

## Command Baseline

1. Docker first: `docker compose -f ops/docker/docker-compose.yml config`
2. PowerShell fallback: `powershell -ExecutionPolicy Bypass -File .\tests\scripts\run-mobile-coverage.ps1`
