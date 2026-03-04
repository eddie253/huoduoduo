# PLAN24 後端平台 Go/No-Go 決策（JNPF vs 自研）

Doc ID: HDD-PLAN24-BACKEND-DECISION
Version: v1.0
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: Draft
CN/EN Pair Link: N/A







## Purpose

1. 固化後端平台技術決策，避免開發期邊界漂移。

## Decision

1. 核心商業域採自研（.NET + BFF + MSSQL）。
2. JNPF 僅作通用能力參考，不綁定核心交易流程。

## Go / No-Go Criteria

1. Go：契約可追溯、測試可重跑、權限與審計可落地。
2. No-Go：核心規則被低代碼反向綁定、資料一致性無保障。

## Acceptance Checklist

- [ ] AC-01: 決策條件可追溯
  - Command: rg -n "Decision|Go / No-Go" docs/architecture/BACKEND_PLATFORM_GO_NO_GO_DECISION_PLAN24.zh-TW.md
  - Expected Result: 命中關鍵章節。
  - Failure Action: 補齊判準。

