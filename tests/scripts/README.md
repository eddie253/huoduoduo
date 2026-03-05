# Tests Script Wrappers

Doc ID: HDD-TESTS-SCRIPTS-README
Version: v1.1
Owner: QA Lead
Last Updated: 2026-03-05
Review Status: In Review
CN/EN Pair Link: N/A

## Purpose

This folder provides convenient wrappers for repeatable local test execution.

## Scripts

1. `run-mobile-unit.ps1` / `run-mobile-unit.mjs`
   - Runs Flutter unit/widget test suite from colocated tests under `apps/mobile_flutter/lib/`.
2. `run-mobile-coverage.ps1` / `run-mobile-coverage.mjs`
   - Runs mobile coverage and threshold gate.
3. `run-e2e-smoke.ps1` / `run-e2e-smoke.mjs`
   - Runs current E2E smoke command.

## Policy

1. If command logic changes, update root `package.json` first.
2. Wrappers should stay thin and delegate to `npm run ...`.
3. Keep both PowerShell and Node MJS wrappers for developer preference on Windows + VSCode.
