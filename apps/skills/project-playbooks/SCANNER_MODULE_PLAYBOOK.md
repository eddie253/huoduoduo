# SCANNER MODULE PLAYBOOK

- 索引：[SKILL_INDEX.md](../SKILL_INDEX.md)
- 模板：[PLAYBOOK_TEMPLATE.md](../templates/PLAYBOOK_TEMPLATE.md)

## 適用範圍
- `apps/mobile_flutter/packages/scan_kit_core`
- 一維/二維掃碼行為與 UI

## Symbology Policy
- 1D 重點：`codabar`, `code39`, `code93`, `code128`, `itf`, `ean13`, `ean8`, `upca`, `upce`
- 2D 重點：`qrCode`, `pdf417`, `dataMatrix`, `aztec`
- dedup window 預設 `800ms`

## UI/UX 規範
- 手動輸入鍵盤數字可視性優先（大按鍵）
- 掃描框需可調（S/M/L）
- 一維框比例與二維框比例分離

## 測試命令
```powershell
cd apps/mobile_flutter/packages/scan_kit_core; flutter test
cd apps/mobile_flutter; flutter test lib/features/scanner/presentation/scanner_page_test.dart
```

## 回歸重點
- 掃碼成功只完成一次
- 手動輸入空值不得送出
- route 契約與 bridge 契約保持相容
