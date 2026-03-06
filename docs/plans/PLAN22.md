# PLAN22 — `apps/skills` Flutter Skills 導入與治理方案

## 摘要
將上游 `flutter/skills` 導入到本專案 `apps/skills`，採「上游唯讀鏡像 + 專案可執行指引」雙層結構，避免污染產品程式碼，並建立可重跑、可比對、可審核的更新流程。此方案不改動 App runtime 行為，只新增知識資產與治理流程。

## 目標與成功標準
1. 目標
- 在 repo 內建立可長期維運的 Flutter 技能知識區，支援 mobile_flutter 開發決策（測試、路由、WebView/PlatformView、快取、效能）。
2. 成功標準
- `apps/skills/flutter-skills/` 可追溯上游來源與版本。
- `apps/skills/project-playbooks/` 有可直接套用於本專案的落地文件。
- 有固定更新指令與驗證清單，任何人可重跑。

## 範圍
1. In Scope
- 目錄規劃、文件模板、上游同步流程、版本追蹤與驗收清單。
- 針對本專案產出首批 4 份落地 playbook（testing、routing、webview/cache、scanner）。
2. Out of Scope
- 直接修改 Flutter SDK 或上游 skills 內容。
- 直接變更 mobile_flutter 功能程式碼（本方案僅治理與知識資產）。

## 目錄與檔案規格（決策完成）
1. 固定目錄
- `apps/skills/flutter-skills/`：上游鏡像（唯讀）
- `apps/skills/project-playbooks/`：專案落地指南
- `apps/skills/templates/`：文件模板
2. 固定文件
- `apps/skills/README.md`
- `apps/skills/SKILL_INDEX.md`
- `apps/skills/project-playbooks/README.md`
- `apps/skills/project-playbooks/FLUTTER_TESTING_PLAYBOOK.md`
- `apps/skills/project-playbooks/ROUTING_NAVIGATION_PLAYBOOK.md`
- `apps/skills/project-playbooks/WEBVIEW_CACHE_LIFECYCLE_PLAYBOOK.md`
- `apps/skills/project-playbooks/SCANNER_MODULE_PLAYBOOK.md`
- `apps/skills/flutter-skills/UPSTREAM_VERSION.md`
- `apps/skills/flutter-skills/UPSTREAM_DIFF_LOG.md`

## 介面與型別/契約異動
1. Runtime API
- 無 runtime API 變更（`mobile_flutter`、`bff_gateway` 行為不變）。
2. Repo 介面
- 新增知識契約：
  - `SKILL_INDEX.md`：列出「上游 skill -> 專案落地文件」映射。
  - `UPSTREAM_VERSION.md`：記錄上游來源 URL、commit hash、同步日期。
  - `UPSTREAM_DIFF_LOG.md`：記錄每次升級差異摘要與影響評估。

## 實作步驟（可交付給執行者）
1. Phase A — 結構定版
- 確認 `apps/skills` 目錄結構符合本方案。
- 建立 `README.md`、`SKILL_INDEX.md`、`templates` 骨架。
2. Phase B — 上游鏡像導入
- 將 `C:\Users\EDDIE\.codex\references\flutter-skills` 同步到 `apps/skills/flutter-skills/`。
- 產生 `UPSTREAM_VERSION.md`（含來源 URL + commit hash）。
3. Phase C — 專案落地萃取
- 由上游 skills 萃取為 4 份專案 playbook（僅保留可執行規範）：
  - 測試（unit/widget/integration + coverage 命令）
  - 路由（go_router + nested flow + pop result 防呆）
  - WebView/Cache（生命週期與資料一致性）
  - Scanner（symbology policy、去重、UI/UX、一維/二維模式）
4. Phase D — 治理與更新流程
- 在 `apps/skills/README.md` 定義更新節奏（建議雙週或月更）。
- 明訂 PR 檢查：若更新上游，必填 `UPSTREAM_DIFF_LOG.md`。
5. Phase E — 驗收證據
- 產出一次完整驗收紀錄（命令、結果、日期、責任人）。

## 測試與驗收情境
1. 文件完整性
- 所有固定文件存在且可開啟。
- `SKILL_INDEX.md` 映射至少覆蓋 4 個高價值技能。
2. 可追溯性
- `UPSTREAM_VERSION.md` 有 URL、commit、日期。
- `UPSTREAM_DIFF_LOG.md` 有本次變更摘要。
3. 可執行性
- 每份 playbook 至少有 1 組可重跑命令（PowerShell）。
4. 非功能驗收
- 不影響 `apps/mobile_flutter` 既有測試與建置流程。

## 建議命令（驗收用）
1. 結構檢查
- `Get-ChildItem -Recurse apps\skills`
2. 文件檢查
- `rg -n "來源|commit|更新日期|驗收" apps/skills`
3. 產品不回歸（抽樣）
- `cd apps/mobile_flutter; flutter analyze`
- `cd apps/mobile_flutter; flutter test lib/features/scanner/presentation/scanner_page_test.dart`

## 風險與對策
1. 風險：上游更新過快，專案文件過時
- 對策：固定週期同步 + `UPSTREAM_DIFF_LOG.md` 強制記錄
2. 風險：上游內容過泛，不適配你們物流場景
- 對策：落地文件只保留「本專案可執行」內容
3. 風險：團隊直接改上游鏡像導致不可比對
- 對策：`flutter-skills/` 唯讀約定；客製只寫在 `project-playbooks/`

## 假設與預設
1. 預設以中文為主、英文關鍵詞保留（符合現行治理）。
2. 預設不將 `flutter-skills` 當成可直接執行的 Codex skill，而是參考知識來源。
3. 預設由 `apps/mobile_flutter` 團隊維護 `project-playbooks`，由 repo 管理者維護上游同步紀錄。
4. 預設方案編號固定為 `PLAN22`，後續修訂採 `PLAN22-R1/R2`。
