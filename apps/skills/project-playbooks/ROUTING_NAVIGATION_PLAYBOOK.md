# ROUTING NAVIGATION PLAYBOOK

- 索引：[SKILL_INDEX.md](../SKILL_INDEX.md)
- 模板：[PLAYBOOK_TEMPLATE.md](../templates/PLAYBOOK_TEMPLATE.md)

## 適用範圍
- `go_router` 導航
- `/scanner` push/pop + result 返回
- 底部 tab 與返回鍵一致性

## 設計原則
- 單一來源導航狀態（避免雙路徑更新）
- `Navigator.canPop` 防止誤退出
- pop 時只回傳一次結果

## 檢查清單
1. 頁面返回後資料刷新策略一致
2. 不允許「多按一次返回才更新」
3. nested flow 不污染根導航堆疊

## 驗收命令
```powershell
cd apps/mobile_flutter; flutter test lib/features/scanner/presentation/scanner_page_test.dart
cd apps/mobile_flutter; flutter analyze
```
