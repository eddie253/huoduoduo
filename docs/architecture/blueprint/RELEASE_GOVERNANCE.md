# RELEASE_GOVERNANCE

Doc ID: HDD-DOC-RELEASE-GOVERNANCE
Version: v1.1
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: In Review
CN/EN Pair Link: N/A







## Purpose

1. 本文件已重建為 UTF-8（修復 IDE 亂碼）。
2. 後續內容可依對應計畫逐步補齊。

## Scope

1. 保持既有檔名與定位，不變更目錄邊界。

## CI Repair Record Policy

1. 每次 CI 由失敗轉為綠燈，必須新增一筆修復記錄。
2. 記錄檔案固定放在：
   - `docs/architecture/blueprint/CI_RECOVERY_LOG.zh-TW.md`
3. 記錄格式固定使用模板：
   - `docs/architecture/blueprint/templates/CI_FIX_RECORD_TEMPLATE.zh-TW.md`
4. 修復記錄至少要包含：
   - `Run URL`
   - `Root Cause`
   - `Fix Summary`
   - `Changed Files`
   - `Verification Commands`
   - `Final Result`

## Evidence Links

1. CI 修復紀錄：
   - `docs/architecture/blueprint/CI_RECOVERY_LOG.zh-TW.md`
2. CI 修復模板：
   - `docs/architecture/blueprint/templates/CI_FIX_RECORD_TEMPLATE.zh-TW.md`

## Acceptance Checklist

- [ ] AC-01: 編碼為 UTF-8
  - Command: Get-Content docs/architecture/blueprint/RELEASE_GOVERNANCE.md -Encoding utf8 -TotalCount 20
  - Expected Result: 中文可讀。
  - Failure Action: 重新以 UTF-8 寫入。
- [ ] AC-02: CI 修復政策已定義
  - Command: Select-String -Path docs/architecture/blueprint/RELEASE_GOVERNANCE.md -Pattern "CI Repair Record Policy|CI_RECOVERY_LOG|CI_FIX_RECORD_TEMPLATE" -Encoding UTF8
  - Expected Result: 命中 CI 修復政策與證據路徑。
  - Failure Action: 補齊政策章節後重跑。

## Change Log

1. v1.1 - 新增 CI 修復紀錄政策與證據路徑。

