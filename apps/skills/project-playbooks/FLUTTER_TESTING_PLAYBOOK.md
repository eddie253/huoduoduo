# FLUTTER TESTING PLAYBOOK

- 索引：[SKILL_INDEX.md](../SKILL_INDEX.md)
- 模板：[PLAYBOOK_TEMPLATE.md](../templates/PLAYBOOK_TEMPLATE.md)

## 適用範圍
- `apps/mobile_flutter`
- scanner、routing、bridge 相關回歸測試

## 測試分層
1. Unit：domain/application（例如 scan session controller）
2. Widget：單頁互動與 pop 行為
3. Integration：關鍵流程（登入、掃碼、返回）

## 標準命令（PowerShell）
```powershell
cd apps/mobile_flutter/packages/scan_kit_core; flutter pub get; flutter test --coverage
cd apps/mobile_flutter; flutter pub get; flutter test --coverage
cd apps/mobile_flutter; flutter test lib/features/scanner/presentation/scanner_page_test.dart
```

## 驗收要點
- 掃碼成功只 pop 一次
- 取消掃碼回傳 `scanner_cancelled`
- WebView bridge 掃碼契約不變
