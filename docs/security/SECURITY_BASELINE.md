# SECURITY_BASELINE

Doc ID: HDD-SEC-BASELINE
Version: v1.0
Owner: Security Lead
Last Updated: 2026-03-05
Review Status: Draft
CN/EN Pair Link: N/A







## Purpose & Scope

1. 定義密鑰、權限、稽核、弱掃與供應鏈安全基線。

## Policy Rules

1. Secrets：禁止硬編碼；分環境管理；輪替週期 90 天。
2. Access：RBAC 最小權限；服務帳號獨立。
3. Audit：記錄 actor/action/resource/result/requestId/timestamp。
4. Scans：SAST/SCA/Secret Scan/SBOM 為必跑 gate。

## Acceptance Checklist

- [ ] AC-01: 安全章節完整
  - Command: rg -n "Secrets|RBAC|Audit|SAST|SCA|SBOM" docs/security/SECURITY_BASELINE.md
  - Expected Result: 全部命中。
  - Failure Action: 補齊對應章節。

