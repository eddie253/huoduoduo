# PLAN30 — 全量驗證與治理作業規範（BFF / Mobile / Integration / Coverage / Wiki）

Doc ID: `PLAN30`
Version: `v1.0`
Owner: `Engineering Productivity Guild`
Last Updated: 2026-03-07
Status: Active

## 1. 目的

建立單一、可重複、可稽核的全量驗證流程。
所有里程碑（Milestone）均使用同一流程，不允許局部測試取代全量測試。

---

## 2. 核心原則

1. **全量原則（Full-run only）**：BFF、Mobile、Integration 測試一律跑完整集合，不採局部或抽樣。
2. **單一入口（Root-only）**：所有指令必須在 repo 根目錄執行（`pnpm run ...`）。
3. **Fail-fast**：任一步驟失敗立即停止，不得跳步。
4. **里程碑治理**：每個 Milestone 完成前，必跑一次治理檢查。
5. **產物一致**：測試、覆蓋率、Wiki 文件必須同步且可重建。

---

## 3. 標準執行單元（Standard Full Unit）

一鍵執行入口：

- `pnpm run quality:full`
- `pnpm run quality:full:ci`（CI 用，不含 clean）

### Phase 0 — Clean

- `pnpm run clean:deep`

### Phase 1 — Install

- `pnpm install --frozen-lockfile`

說明：

- `--frozen-lockfile` 代表安裝時不允許修改 `pnpm-lock.yaml`。
- 若 `package.json` 與 lockfile 不一致，會直接失敗，避免非預期依賴漂移。

### Phase 2 — BFF 全量驗證

- `pnpm run bff:verify`

### Phase 3 — Mobile Flutter 全量驗證

- `pnpm run mobile:verify`

### Phase 4 — Integration 全量驗證

- `pnpm run mobile:test:uat-login-it`
- `pnpm run wave2:uat-smoke`

### Phase 5 — Coverage + Wiki

- `pnpm run coverage:verify`
- `pnpm run wiki:generate`
- `pnpm run wiki:check`

### Phase 6 — Milestone 治理（每個里程碑至少一次）

- `pnpm run turbo:verify`

---

## 4. 禁止事項

- 禁止使用局部測試（例如僅跑單檔、單案例）來宣告里程碑通過。
- 禁止跳過 `coverage` 或 `wiki` 同步。
- 禁止在子資料夾手動執行不一致命令作為正式結果。
- 禁止在失敗後直接進下一階段。

---

## 5. 里程碑通過條件（Definition of Done）

每次 Milestone 要同時滿足：

1. Phase 0~6 全部成功。
2. 無未處理失敗步驟。
3. Coverage 與 Wiki 檢查通過。
4. 治理步驟（`pnpm run turbo:verify`）在該里程碑週期內至少成功一次。
5. 執行紀錄可追溯（命令、時間、結果、失敗原因與修正）。

---

## 6. 推薦執行頻率

- **日常開發（本地）**：至少執行一次 `bff:verify` 或 `mobile:verify` 對應模組全量檢查。
- **PR 前**：至少執行一次 Standard Full Unit。
- **里程碑前**：必執行一次 Standard Full Unit + 治理。
- **里程碑完成當日**：保留完整 log 與產物狀態。

---

## 7. 後續優化（非阻塞）

目前已提供單一總入口：

- `pnpm run quality:full`（已包裝 Phase 0~6）
- `pnpm run quality:full:ci`（已包裝 Phase 1~6，供 CI 使用）

若需除錯或定位故障，再依本文件 Phase 順序拆開單步執行。

---

## 8. 實測操作手冊（照表執行）

### 8.1 前置檢查

在 repo 根目錄執行：

- `pnpm -v`
- `flutter --version`
- `docker version`

說明：

- 若本機不需 Docker 測試，可跳過 Docker 版本檢查。
- 若 `clean:deep` 遇到 Docker daemon 未啟動，會略過 Docker cache prune，不影響後續測試主流程。

### 8.2 一鍵全量（本地）

- `pnpm run quality:full`

完成條件：

- 指令結束碼為 0。
- 無任一步驟 fail。
- `wiki:check` 與 `turbo:verify` 均成功。

### 8.3 一鍵全量（CI）

- `pnpm run quality:full:ci`

使用時機：

- CI runner 或不希望先做 `clean:deep` 的場景。

### 8.4 失敗時處理

1. 停在失敗步驟，不可直接往下跑。
2. 修正後從該步驟重跑，必要時重跑整個 `quality:full`。
3. 若有影響產物（coverage/wiki）的修正，必須重跑 `coverage:verify`、`wiki:generate`、`wiki:check`。

---

## 9. 測試結果回報模板（建議貼在 PR）

```text
[PLAN30 Full Run Report]
Date: YYYY-MM-DD
Operator: <name>
Branch/Commit: <branch> / <sha>

Command:
- pnpm run quality:full

Result:
- Phase 0 Clean: PASS/FAIL
- Phase 1 Install: PASS/FAIL
- Phase 2 BFF verify: PASS/FAIL
- Phase 3 Mobile verify: PASS/FAIL
- Phase 4 Integration: PASS/FAIL
- Phase 5 Coverage + Wiki: PASS/FAIL
- Phase 6 Governance: PASS/FAIL

Artifacts:
- Coverage summary: <path or key metric>
- Wiki check: PASS/FAIL

Notes:
- <issues/fixes>
```

---

## 10. 指令速查

- 本地全量：`pnpm run quality:full`
- CI 全量：`pnpm run quality:full:ci`
- 僅重跑 wiki：`pnpm run wiki:generate && pnpm run wiki:check`
- 僅重跑 coverage：`pnpm run coverage:verify`
