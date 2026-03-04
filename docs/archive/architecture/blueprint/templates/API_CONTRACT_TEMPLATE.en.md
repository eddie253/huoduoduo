# API Contract Template

Doc ID: HDD-DOC-ARCHITECTURE-BLUEPRINT-TEMPLATES-API-CONTRACT-TEMPLATE-EN
Version: v1.0
Owner: Project Lead
Last Updated: 2026-03-04
Review Status: Draft
CN/EN Pair Link: docs/architecture/blueprint/templates/API_CONTRACT_TEMPLATE.zh-TW.md

## 1. Purpose

1. Describe the API contract objective and scope.

## 2. Endpoint Summary

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET/POST/...` | `/v1/...` | `<desc>` | `Yes/No` |

## 3. Request Contract

1. Query/Path/Header/Body schema
2. Field types and length constraints
3. Validation rules

## 4. Response Contract

1. Success schema
2. Error schema
3. maxLength/maxItems/boolean contract

## 5. Error Code Mapping

1. Internal code
2. Legacy mapping
3. HTTP status mapping

## 6. Traceability

1. Legacy method mapping or `N/A` with reason.

## 7. Test Cases

1. Happy path
2. Validation failures
3. Boundary/overflow behavior

## 8. Change Log

1. `v1.0` - initial template

## Acceptance Checklist

- [ ] AC-01: 治理標頭完整
  - Command: rg -n "Doc ID|Version|Owner|Last Updated|Review Status|CN/EN Pair Link" docs/architecture/blueprint/templates/API_CONTRACT_TEMPLATE.en.md
  - Expected Result: 六個治理欄位皆可被命中。
  - Failure Action: 補齊缺漏欄位後重跑。

- [ ] AC-02: Docker 優先命令可執行
  - Command: docker --version
  - Expected Result: 可輸出 Docker 版本資訊。
  - Failure Action: 啟動 Docker Desktop 後重跑。

- [ ] AC-03: PowerShell fallback 可執行
  - Command: Get-Content docs/architecture/blueprint/templates/API_CONTRACT_TEMPLATE.en.md -TotalCount 20
  - Expected Result: 可成功讀取文件內容。
  - Failure Action: 修正路徑或檔案編碼後重跑。
