# GOVERNANCE_EXECUTION_STANDARD.zh-TW

Doc ID: HDD-GOV-EXECUTION-STANDARD
Version: v1.2
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: Draft
CN/EN Pair Link: N/A







## Purpose

1. 固化團隊執行基線，避免跨人員與跨倉開發時標準漂移。
2. 確保 AI 與開發者都依同一份治理規則工作。

## Scope

1. 適用範圍：前端 App、前端 Web、BFF、後端 .NET、文件與測試交付流程。
2. 執行環境基線：Windows + VSCode + PowerShell + Docker-first。

## Execution Baseline

1. 命令順序固定：Docker command -> PowerShell fallback。
2. 文件語言政策：中文主文 + 英文關鍵詞。
3. 交付回覆需包含可重跑驗收命令。

## Report Output Policy（輸出目錄政策）

1. 執行產物統一路徑為 `reports/output/`。
2. `reports/test/` 視為舊路徑，僅供歷史記錄參考，不再新增。
3. 每次交付需在 `reports/output/<run_id>/` 放置 log、summary 與報告檔。

## Link Format Policy（連結格式政策）

1. 文件與 AI 回覆中的檔案位置，必須使用「純路徑」。
2. 禁止輸出 `vscode-resource`、`file+`、`vscode-cdn` 或其他 webview URL。
3. 推薦格式：
   1. 相對路徑：`docs/architecture/README.md`
   2. 絕對路徑：`C:\Users\EDDIE\Downloads\APP_didiexpress-main\APP_didiexpress-main\docs\architecture\README.md`
4. 若需開啟檔案，以 IDE 檔案面板或 `Ctrl+P` 為準，不以瀏覽器 URL 作為來源。

## Acceptance Checklist

- [ ] AC-01: 執行基線已定義
  - Command: `rg -n "Windows|VSCode|PowerShell|Docker-first" docs/architecture/blueprint/GOVERNANCE_EXECUTION_STANDARD.zh-TW.md`
  - Expected Result: 命中執行環境基線。
  - Failure Action: 補齊基線條文後重跑。

- [ ] AC-02: 連結格式政策已定義
  - Command: `rg -n "Link Format Policy|純路徑|vscode-resource|file\+|vscode-cdn" docs/architecture/blueprint/GOVERNANCE_EXECUTION_STANDARD.zh-TW.md`
  - Expected Result: 命中政策與禁止項目。
  - Failure Action: 補齊連結格式政策後重跑。

- [ ] AC-03: 檔案為 UTF-8
  - Command: `Get-Content docs/architecture/blueprint/GOVERNANCE_EXECUTION_STANDARD.zh-TW.md -Encoding utf8 -TotalCount 40`
  - Expected Result: 中文可正常顯示。
  - Failure Action: 以 UTF-8 重存後重跑。

## Change Log

1. v1.2 - 新增 Report Output Policy：執行產物統一使用 `reports/output/`，`reports/test/` 改為歷史路徑。
2. v1.1 - 新增連結格式政策：永遠輸出純路徑，禁止 vscode-resource/file+ URL。

