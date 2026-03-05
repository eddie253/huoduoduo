# apps/skills 使用說明（PLAN22）

## 目的
此目錄提供 Flutter 開發知識治理，採「上游唯讀鏡像 + 專案落地指引」雙層結構。

## 結構
- [flutter-skills/](./flutter-skills/)：上游 <https://github.com/flutter/skills.git> 鏡像（唯讀參考）
- [project-playbooks/](./project-playbooks/)：本專案可執行落地文件
- [templates/](./templates/)：文件模板

## 治理規範
- 不直接修改 `flutter-skills/` 內上游內容。
- 客製流程一律寫在 `project-playbooks/`。
- 更新上游時，必填 [flutter-skills/UPSTREAM_DIFF_LOG.md](./flutter-skills/UPSTREAM_DIFF_LOG.md)。

## 更新節奏
- 建議雙週一次；至少每月一次。

## 更新流程（PowerShell）
```powershell
robocopy C:\Users\EDDIE\.codex\references\flutter-skills apps\skills\flutter-skills /E
```

## 驗收清單
1. `apps/skills` 結構與固定文件存在
2. [UPSTREAM_VERSION.md](./flutter-skills/UPSTREAM_VERSION.md) 含來源、commit、更新日期
3. [SKILL_INDEX.md](./SKILL_INDEX.md) 映射至少 4 項
4. [project-playbooks](./project-playbooks/) 每份至少 1 組可重跑命令

## 責任分工
- `apps/mobile_flutter` 團隊：維護 `project-playbooks/`
- Repo 管理者：維護上游同步與 diff 記錄
