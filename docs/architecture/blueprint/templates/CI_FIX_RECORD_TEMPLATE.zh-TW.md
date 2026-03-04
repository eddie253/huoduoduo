# CI_FIX_RECORD_TEMPLATE

Doc ID: HDD-TPL-CI-FIX-RECORD
Version: v1.0
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: Approved
CN/EN Pair Link: N/A







## Purpose

1. 提供固定格式，記錄 CI 失敗到綠燈的完整修復軌跡。
2. 作為 Release 簽核、RCA 與回歸驗證證據。

## Usage

1. 每次 CI 由紅轉綠時新增一筆記錄，不覆寫歷史。
2. 檔案路徑必須使用純路徑，不使用 `vscode-resource`、`file+` 類 URL。
3. 時間一律標示 `Asia/Taipei`。

## Record Template

### Incident Header

- Incident ID:
- Workflow Name:
- Run Number / Run ID:
- Run URL:
- Branch:
- Commit SHA:
- Triggered At (Asia/Taipei):
- Closed At (Asia/Taipei):
- Owner:
- Reviewer:

### Symptom

1. 失敗 Job:
2. 失敗 Step:
3. 主要錯誤訊息:

### Root Cause

1.

### Fix Summary

1.

### Changed Files (Pure Paths)

1.

### Verification Commands

1. Command:
   - Expected Result:
2. Command:
   - Expected Result:

### Final Result

1. Final Green Run URL:
2. Remaining Risk:
3. Rollback Plan:

## Acceptance Checklist

- [ ] AC-01: 欄位完整可追溯
  - Command: `Select-String -Path <target-file> -Pattern "Incident ID|Run URL|Root Cause|Fix Summary|Changed Files|Final Green Run URL" -Encoding UTF8`
  - Expected Result: 主要欄位均有命中。
  - Failure Action: 補齊缺漏欄位後重跑。

- [ ] AC-02: 路徑格式合規
  - Command: `Select-String -Path <target-file> -Pattern "vscode-resource|file\\+|vscode-cdn" -Encoding UTF8`
  - Expected Result: 無命中。
  - Failure Action: 改成純路徑後重跑。

- [ ] AC-03: 時間格式合規
  - Command: `Select-String -Path <target-file> -Pattern "Asia/Taipei" -Encoding UTF8`
  - Expected Result: 有命中。
  - Failure Action: 補上時區標註後重跑。

## Change Log

1. v1.0 - 初版模板，定義 CI 修復記錄必要欄位與驗收。

