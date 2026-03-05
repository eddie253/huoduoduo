# WEBVIEW CACHE LIFECYCLE PLAYBOOK

- 索引：[SKILL_INDEX.md](../SKILL_INDEX.md)
- 模板：[PLAYBOOK_TEMPLATE.md](../templates/PLAYBOOK_TEMPLATE.md)

## 適用範圍
- `flutter_inappwebview`
- 預約/押金/接單頁資料一致性
- 前景/背景切換與重載策略

## 策略
1. 定義資料刷新時機：進頁、返回、手動刷新
2. 區分快取層：記憶體快取 / 持久化快取
3. 關鍵 API 回應必須有時間戳與來源

## 操作建議
- 避免每個按鈕都觸發全量重載
- 針對預約與押金明細做差異刷新

## 驗收命令
```powershell
cd apps/mobile_flutter; flutter analyze
cd apps/mobile_flutter; flutter test lib
```
