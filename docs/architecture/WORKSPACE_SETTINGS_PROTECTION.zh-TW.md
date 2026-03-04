# Workspace Settings 保護規範（.vscode/settings.json）

Doc ID: HDD-GOV-WORKSPACE-SETTINGS-PROTECTION
Version: v1.0
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: Draft
CN/EN Pair Link: N/A







## 1. Purpose

1. 防止 `.vscode/settings.json` 被非授權人員誤改，造成工作區編碼與工具行為漂移。
2. 以「CODEOWNERS + CI Guard + Branch Protection」三層方式落地強制治理。

## 2. Scope

1. 保護檔案：`.vscode/settings.json`
2. 關聯治理檔案：
   1. `.github/CODEOWNERS`
   2. `.github/workflows/ci.yml`
   3. `ops/ci/check-workspace-settings-guard.sh`

## 3. Policy Rules

1. 任何 PR 若變更 `.vscode/settings.json`，必須滿足：
   1. CODEOWNERS 審核通過。
   2. `workspace_settings_guard` CI job 通過。
2. 非白名單 actor 修改受保護檔案，CI 必須 fail。
3. 緊急狀況才允許 bypass，且需留存審批紀錄。

## 4. Implementation

### 4.1 CODEOWNERS

1. 在 `.github/CODEOWNERS` 增加：

```text
/.vscode/settings.json @eddie253
/.github/workflows/ci.yml @eddie253
/ops/ci/check-workspace-settings-guard.sh @eddie253
```

### 4.2 CI Guard Script

1. 使用 `ops/ci/check-workspace-settings-guard.sh`。
2. 行為：
   1. 比對 PR diff（或 push 最近一次 diff）。
   2. 若未改 `.vscode/settings.json` -> pass。
   3. 若有改動但 `GITHUB_ACTOR` 不在 `ALLOWED_WORKSPACE_SETTINGS_ACTORS` -> fail。
   4. 若 `ALLOW_WORKSPACE_SETTINGS_CHANGE=1` -> 明確 bypass。

### 4.3 Workflow Job

1. 在 `.github/workflows/ci.yml` 新增 job：`workspace_settings_guard`。
2. 必填 env：
   1. `GITHUB_EVENT_NAME`
   2. `GITHUB_BASE_REF`
   3. `GITHUB_ACTOR`
   4. `ALLOWED_WORKSPACE_SETTINGS_ACTORS`

## 5. GitHub Repository Settings（手動）

1. Branch protection（`main`）啟用：
   1. `Require a pull request before merging`
   2. `Require review from Code Owners`
   3. `Require status checks to pass before merging`
2. Required checks 至少包含：
   1. `workspace_settings_guard`
   2. 既有核心 CI gate（例如 `bff_gateway`, `mobile_flutter`）

## 6. Emergency Change Procedure

1. 僅在阻斷開發或安全事件時可啟用 bypass。
2. 流程：
   1. 建立變更單並說明原因。
   2. 臨時設定 `ALLOW_WORKSPACE_SETTINGS_CHANGE=1`。
   3. 合併後 24 小時內移除 bypass，補齊 RCA。

## 7. Operations Notes

1. 新增可修改者時，只調整 `ALLOWED_WORKSPACE_SETTINGS_ACTORS`（逗號分隔）。
2. CODEOWNERS 仍建議維持單一 owner 或小範圍 owner，避免權限擴張。

## 8. Acceptance Checklist

- [ ] AC-01: CODEOWNERS 規則存在
  - Command: `rg -n "/\\.vscode/settings\\.json|check-workspace-settings-guard\\.sh|ci\\.yml" .github/CODEOWNERS`
  - Expected Result: 命中三條保護規則。
  - Failure Action: 補齊 CODEOWNERS 規則後重跑。

- [ ] AC-02: Workflow 已接線 guard job
  - Command: `rg -n "workspace_settings_guard|check-workspace-settings-guard\\.sh|ALLOWED_WORKSPACE_SETTINGS_ACTORS" .github/workflows/ci.yml`
  - Expected Result: 命中 job 與 env。
  - Failure Action: 修正 workflow 後重跑。

- [ ] AC-03: Guard script 存在
  - Command: `Get-ChildItem ops/ci/check-workspace-settings-guard.sh`
  - Expected Result: 檔案存在。
  - Failure Action: 補檔後重跑。

## 9. Change Log

1. `v1.0` - 初版，建立 `.vscode/settings.json` 強制保護機制。

