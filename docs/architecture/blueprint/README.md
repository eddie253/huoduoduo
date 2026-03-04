# README

Doc ID: HDD-DOC-README
Version: v1.1
Owner: Architecture Lead
Last Updated: 2026-03-04
Review Status: In Review
CN/EN Pair Link: N/A

## Purpose

1. 本文件已重建為 UTF-8（修復 IDE 亂碼）。
2. 後續內容可依對應計畫逐步補齊。

## Scope

1. 保持既有檔名與定位，不變更目錄邊界。

## Quick Links

1. 架構凍結主檔：
   - `docs/architecture/blueprint/ARCHITECTURE_FREEZE_BASELINE.zh-TW.md`
2. Release 治理：
   - `docs/architecture/blueprint/RELEASE_GOVERNANCE.md`
3. CI 修復紀錄：
   - `docs/architecture/blueprint/CI_RECOVERY_LOG.zh-TW.md`
4. CI 修復模板：
   - `docs/architecture/blueprint/templates/CI_FIX_RECORD_TEMPLATE.zh-TW.md`

## Acceptance Checklist

- [ ] AC-01: 編碼為 UTF-8
  - Command: Get-Content docs/architecture/blueprint/README.md -Encoding utf8 -TotalCount 20
  - Expected Result: 中文可讀。
  - Failure Action: 重新以 UTF-8 寫入。
- [ ] AC-02: Quick Links 含 CI 修復入口
  - Command: Select-String -Path docs/architecture/blueprint/README.md -Pattern "CI_RECOVERY_LOG|CI_FIX_RECORD_TEMPLATE" -Encoding UTF8
  - Expected Result: 命中 CI 修復紀錄與模板路徑。
  - Failure Action: 補齊入口連結後重跑。

## Change Log

1. v1.1 - 新增 CI 修復紀錄與模板入口。
