# DEV_TOOLCHAIN_BASELINE

Doc ID: HDD-DOC-DEV-TOOLCHAIN-BASELINE
Version: v1.1
Owner: Architecture Lead
Last Updated: 2026-03-04
Review Status: In Review
CN/EN Pair Link: N/A

## Purpose

1. 固化團隊開發工具鏈，避免環境不一致造成「我這邊可以、你那邊不行」。
2. 提供 Windows + VSCode + PowerShell + Docker-first 的可重跑安裝與驗證命令。
3. 明確把 `ripgrep (rg)` 納入必裝清單，支援文件治理與驗收命令。

## Scope

1. 適用範圍：本專案所有開發者（Mobile/Web/BFF/.NET）。
2. 僅定義工具鏈與驗證命令，不涵蓋業務邏輯與部署流程。

## Platform Baseline

1. OS: Windows 11 x64
2. IDE: VSCode (Stable)
3. Shell: PowerShell 7+（可接受 Windows PowerShell 5.1 作備援）
4. Container Runtime: Docker Desktop（Docker-first）

## Team Install Commands (Windows)

1. 先安裝/更新基礎套件管理器（若公司電腦已內建可略過）
  - Command: `winget --version`
2. 安裝核心工具（建議逐條執行，失敗可單獨重跑）
  - Command: `winget install --id Git.Git -e`
  - Command: `winget install --id Microsoft.VisualStudioCode -e`
  - Command: `winget install --id OpenJS.NodeJS.LTS -e`
  - Command: `winget install --id Microsoft.DotNet.SDK.8 -e`
  - Command: `winget install --id Microsoft.DotNet.SDK.10 -e`
  - Command: `winget install --id Docker.DockerDesktop -e`
  - Command: `winget install --id BurntSushi.ripgrep.MSVC -e`
  - Command: `winget install --id Microsoft.Playwright -e`
3. 手機開發相關
  - Command: `winget install --id Google.AndroidStudio -e`
  - Command: `winget install --id Flutter.Flutter -e`
4. 資料庫工具（MSSQL）
  - Command: `winget install --id Microsoft.SQLServerManagementStudio -e`
  - Command: `winget install --id Microsoft.Sqlcmd -e`
5. 若 `winget` 因公司政策不可用，使用 Chocolatey 備援（至少安裝 `rg`）
  - Command: `choco install ripgrep -y`

## Verify Commands

1. `git --version`
2. `code --version`
3. `node -v`
4. `npm -v`
5. `dotnet --list-sdks`
6. `docker --version`
7. `docker compose version`
8. `rg --version`
9. `flutter --version`
10. `flutter doctor -v`
11. `adb version`
12. `emulator -list-avds`
13. `npx playwright --version`
14. `sqlcmd -?`

## Project Gate Smoke Commands

1. `docker compose -f ops/docker/docker-compose.yml config`
2. `npm run bff:build`
3. `npm run bff:test -- --runInBand`
4. `npm run mobile:test`

## Acceptance Checklist

- [ ] AC-01: 編碼為 UTF-8
  - Command: Get-Content docs/architecture/blueprint/DEV_TOOLCHAIN_BASELINE.md -Encoding utf8 -TotalCount 20
  - Expected Result: 中文可讀。
  - Failure Action: 重新以 UTF-8 寫入。
- [ ] AC-02: `ripgrep (rg)` 已列入團隊必裝
  - Command: Select-String -Path docs/architecture/blueprint/DEV_TOOLCHAIN_BASELINE.md -Pattern "ripgrep|rg --version|BurntSushi.ripgrep.MSVC" -Encoding UTF8
  - Expected Result: 至少命中 1 筆以上。
  - Failure Action: 補上安裝與驗證指令後重跑。
- [ ] AC-03: 工具安裝命令可在 Windows 重跑
  - Command: Select-String -Path docs/architecture/blueprint/DEV_TOOLCHAIN_BASELINE.md -Pattern "winget install|choco install|docker compose" -Encoding UTF8
  - Expected Result: 命中安裝命令與專案 smoke 命令。
  - Failure Action: 補齊命令後重跑。

## Change Log

1. v1.1 - 補齊團隊必裝工具、Windows 安裝命令、驗證命令，並加入 `ripgrep (rg)` 基線。
