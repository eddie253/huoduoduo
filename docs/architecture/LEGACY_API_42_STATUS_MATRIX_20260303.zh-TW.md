# 舊 API 42 支狀態矩陣（PLAN24）

Doc ID: `HDD-LEGACY-42-MATRIX`
Version: `v1.1`
Owner: `Architecture Lead`
Last Updated: 2026-03-05
Review Status: In Review
CN/EN Pair Link: docs/architecture/LEGACY_API_42_STATUS_MATRIX_20260303.en.md






1. CN: `docs/architecture/LEGACY_API_42_STATUS_MATRIX_20260303.zh-TW.md`
2. EN: `docs/architecture/LEGACY_API_42_STATUS_MATRIX_20260303.en.md`

日期：2026-03-03（Asia/Taipei）

## 1. 定義
1. `implemented`：新 BFF 已有對應 API 與 SOAP 映射。
2. `waived`：依產品邊界由 legacy web（WebView）承接，本輪不擴張 native API。
3. `deferred`：尚未實作，保留後續里程碑處理。

## 2. 統計
1. implemented: `13`
2. waived: `17`
3. deferred: `12`
4. total: `42`

## 3. 矩陣

| # | Legacy SOAP Method | Legacy URL | 舊 Request 欄位 | 新 BFF Endpoint / 替代路徑 | Status | Reason | Owner | Target Milestone | Next Action | Waive 回收條件 |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `GetLogin` | `/Inquiry/didiservice.asmx` | `Account, Password, Kind` | `POST /v1/auth/login` | `implemented` | 登入主流程已上線 | BFF Lead | `P0` | 維持 contract 測試 | `-` |
| 2 | `UpdateRegID` | `/Inquiry/didiservice.asmx` | `DNUM, RegID, Kind, Version` | `POST /v1/push/register` | `implemented` | 推播註冊 API 已實作 | BFF Lead | `P1` | Flutter 接線排入 P1 | `-` |
| 3 | `DeleteRegID` | `/Inquiry/didiservice.asmx` | `Contract, RegID` | `-` | `deferred` | 未納入本輪登入收斂 | BFF Lead | `P4` | 評估是否補登出反註冊 API | `-` |
| 4 | `UpdateBank` | `/Inquiry/didiservice.asmx` | `DNUM, Code, Account` | `WebView: /app/currency/bank.aspx` | `waived` | 舊版即由 web 承接 | Mobile Lead | `P4 review` | 維持 webview 路徑 | 若 web 下線才改 native API |
| 5 | `AddOrder_elf` | `/Inquiry/didiservice.asmx` | `DNUM, TNUM` | `-` | `deferred` | 新 App 暫無 native 接單流程 | Product + BFF Lead | `P2` | 定義接單用例與安全規則 | `-` |
| 6 | `BackOrder` | `/Inquiry/didiservice.asmx` | `DNUM, TNUM` | `-` | `deferred` | 新 App 暫無 native 退單流程 | Product + BFF Lead | `P2` | 定義退單狀態機與錯誤碼 | `-` |
| 7 | `GetShipment` | `/Inquiry/didiservice.asmx` | `TNUM` | `GET /v1/shipments/{trackingNo} (fallback)` | `implemented` | 已作為 fallback | BFF Lead | `P0` | 保持 fallback 測試 | `-` |
| 8 | `GetShipment_elf` | `/Inquiry/didiservice.asmx` | `TNUM` | `GET /v1/shipments/{trackingNo} (primary)` | `implemented` | 查件主路徑已上線 | BFF Lead | `P0` | 維持契約穩定 | `-` |
| 9 | `GetShipment_Currency` | `/Inquiry/didiservice.asmx` | `OrderNum` | `WebView: /app/currency/*.aspx` | `waived` | 帳務查詢在 web 頁完整 | Mobile Lead | `P4 review` | 保持 web 承接 | BFF 提供等價頁面時再評估 |
| 10 | `UpdateArrivalErr_NEW` | `/Inquiry/didiservice.asmx` | `DNUM, TNUM, Image, Image_FN, Itude` | `POST /v1/shipments/{trackingNo}/exception` | `implemented` | 單筆異常上傳已上線 | BFF Lead | `P0` | 保持 upload 契約測試 | `-` |
| 11 | `UpdateArrivalErr_Multi_NEW` | `/Inquiry/didiservice.asmx` | `DNUM, TNUM, Image, Image_FN, Itude` | `-` | `deferred` | 批次上傳尚未需求確認 | Product + BFF Lead | `P2` | 先明確批次 UX 與重試策略 | `-` |
| 12 | `ClearArrival` | `/Inquiry/didiservice.asmx` | `DNUM, TNUM` | `-` | `deferred` | 清除簽收流程未納入 | Product Lead | `P3` | 確認是否保留舊行為 | `-` |
| 13 | `UpdateArrival` | `/Inquiry/didiservice.asmx` | `DNUM, TNUM, Image, Image_FN, Itude` | `POST /v1/shipments/{trackingNo}/delivery` | `implemented` | 單筆簽收上傳已上線 | BFF Lead | `P0` | 以測試守護 | `-` |
| 14 | `UpdateArrival_Multi` | `/Inquiry/didiservice.asmx` | `DNUM, TNUM, Image, Image_FN, Itude` | `-` | `deferred` | 批次簽收未納入 | Product + BFF Lead | `P2` | 待批次規格核定 | `-` |
| 15 | `Alr_Order` | `/Inquiry/didiservice.asmx` | `DNUM` | `-` | `deferred` | 舊原生清單未對應新原生頁 | Mobile Lead | `P3` | 決定是否改 webview 承接 | `-` |
| 16 | `Alr_Shipment` | `/Inquiry/didiservice.asmx` | `DD, DNUM` | `-` | `deferred` | 已送達清單未對應 | Mobile Lead | `P3` | 盤點舊版使用頻率 | `-` |
| 17 | `CreatePath` | `/Inquiry/didiservice.asmx` | `StartLatLng, EndLatLng, DNUM` | `-` | `deferred` | 地圖路徑目前 out-of-scope | Product Lead | `P4` | 需求重評再決策 | `-` |
| 18 | `CheckedArrivalErr` | `/Inquiry/didiservice.asmx` | `TNUM, Itude` | `-` | `deferred` | 前置檢查未實作 | BFF Lead | `P2` | 先補資料規則文件 | `-` |
| 19 | `GetDriverCurrency` | `/Inquiry/didiservice.asmx` | `DD, DNUM` | `WebView: /app/currency/day_cy.aspx` | `waived` | 日帳務已由 web 提供 | Mobile Lead | `P4 review` | 維持 web 路徑 | BFF 需提供等價報表 API 才重啟 |
| 20 | `GetDriverCurrencyMonth` | `/Inquiry/didiservice.asmx` | `DD, DNUM` | `WebView: /app/currency/month_cy.aspx` | `waived` | 月帳務已由 web 提供 | Mobile Lead | `P4 review` | 維持 web 路徑 | 同上 |
| 21 | `GetDriverBalance` | `/Inquiry/didiservice.asmx` | `DNUM` | `WebView: /app/currency/wda.aspx` | `waived` | 餘額顯示在 web 現有流程 | Mobile Lead | `P4 review` | 不擴張 native | 需離線需求才重啟 |
| 22 | `ApplyWithDrawal` | `/Inquiry/didiservice.asmx` | `DNUM, Money` | `WebView: /app/currency/wda.aspx` | `waived` | 提款流程由 web 承接 | Product Lead | `P4 review` | 維持 web | 有法規/簽核需求才重啟 |
| 23 | `GetDeposit_Head` | `/Inquiry/didiservice.asmx` | `StartDate, EndDate, DNUM` | `WebView: /app/currency/virtual.aspx` | `waived` | 押金摘要在 web | Mobile Lead | `P4 review` | 維持 web | 若 web 下線才開 API |
| 24 | `GetDeposit_Body` | `/Inquiry/didiservice.asmx` | `TNUM, Addr, DNUM` | `WebView: /app/currency/virtual.aspx` | `waived` | 押金明細在 web | Mobile Lead | `P4 review` | 維持 web | 同上 |
| 25 | `GetARV_ZIP` | `/Inquiry/didiservice.asmx` | `(none)` | `WebView: /app/rvt/df_area.aspx` | `waived` | 預約區域頁由 web 承接 | Mobile Lead | `P4 review` | 維持 web | 若預約改全原生再重啟 |
| 26 | `GetARV` | `/Inquiry/didiservice.asmx` | `ZIP, DNUM` | `WebView: /app/rvt/ge.aspx` | `waived` | 可預約清單在 web | Mobile Lead | `P4 review` | 維持 web | 同上 |
| 27 | `GetARVed` | `/Inquiry/didiservice.asmx` | `DNUM` | `GET /v1/reservations?mode=standard` | `implemented` | API 已實作 | BFF Lead | `P1` | 後續決定 Flutter 是否接線 | `-` |
| 28 | `UpdateARV` | `/Inquiry/didiservice.asmx` | `NUMs, Addr, DNUM` | `POST /v1/reservations?mode=standard` | `implemented` | API 已實作 | BFF Lead | `P1` | 保持測試、待 UI 接線 | `-` |
| 29 | `RemoveARV` | `/Inquiry/didiservice.asmx` | `NUMs, Addr, DNUM` | `DELETE /v1/reservations/{id}?mode=standard&address=...` | `implemented` | API 已實作 | BFF Lead | `P1` | 保持測試、待 UI 接線 | `-` |
| 30 | `GetAreaCode` | `/Inquiry/didiservice.asmx` | `DNUM` | `WebView: /app/rvt/df_area.aspx` | `waived` | 區域代碼由 web 解決 | Mobile Lead | `P4 review` | 維持 web | 預約頁原生化才重啟 |
| 31 | `GetArrived` | `/Inquiry/didiservice.asmx` | `DNUM` | `WebView: /app/inq/arv.aspx` | `waived` | 到倉清單由 web 提供 | Mobile Lead | `P4 review` | 維持 web | 若 web 移除才重啟 |
| 32 | `GetBARV` | `/Inquiry/didiservice.asmx` | `ZIP, DNUM` | `WebView: /app/rvt/bh.aspx` | `waived` | 大貨預約清單在 web | Mobile Lead | `P4 review` | 維持 web | 預約改原生時重啟 |
| 33 | `GetBARVed` | `/Inquiry/didiservice.asmx` | `DNUM` | `GET /v1/reservations?mode=bulk` | `implemented` | API 已實作 | BFF Lead | `P1` | 待 Flutter 接線決策 | `-` |
| 34 | `UpdateBARV` | `/Inquiry/didiservice.asmx` | `NUM, Addr, FEE, DNUM` | `POST /v1/reservations?mode=bulk` | `implemented` | API 已實作 | BFF Lead | `P1` | 待 Flutter 接線決策 | `-` |
| 35 | `RemoveBARV` | `/Inquiry/didiservice.asmx` | `NUM, Addr, DNUM` | `DELETE /v1/reservations/{id}?mode=bulk&address=...` | `implemented` | API 已實作 | BFF Lead | `P1` | 待 Flutter 接線決策 | `-` |
| 36 | `GetPxymate` | `/Inquiry/didiservice.asmx` | `Area` | `WebView: /app/pxy/mate.aspx` | `waived` | 代理功能在 web | Mobile Lead | `P4 review` | 維持 `/proxy-menu` -> web | 有原生代理頁需求才重啟 |
| 37 | `SearchKPI` | `/Inquiry/didiservice.asmx` | `Year, Month, Area` | `WebView: /app/pxy/kpi.aspx` | `waived` | KPI 查詢在 web | Mobile Lead | `P4 review` | 維持 web | KPI 原生報表需求才重啟 |
| 38 | `GetKPI` | `/Inquiry/didiservice.asmx` | `Year, Month, Area` | `WebView: /app/pxy/kpi.aspx` | `waived` | KPI 月資料在 web | Mobile Lead | `P4 review` | 維持 web | 同上 |
| 39 | `GetKPI_dis` | `/Inquiry/didiservice.asmx` | `DD, Area` | `WebView: /app/pxy/kpi.aspx` | `waived` | KPI 日明細在 web | Mobile Lead | `P4 review` | 維持 web | 同上 |
| 40 | `GetSystemDate` | `/Inquiry/didiservice.asmx` | `format` | `-` | `deferred` | 新系統多用 server time header | BFF Lead | `P4` | 若有硬需求再補 | `-` |
| 41 | `GetVersion` | `/Inquiry/didiservice.asmx` | `Name` | `-` | `deferred` | 版本檢查改用發版機制 | Mobile Lead | `P4` | 定義是否要版本 API | `-` |
| 42 | `GetBulletin` | `/Inquiry/didiservice.asmx` | `(none)` | `GET /v1/bootstrap/bulletin` | `implemented` | 公告 API 已上線 | BFF Lead | `P0` | 持續驗證資料來源 | `-` |

## 4. 備註
1. 本矩陣母體為舊 Android `network/*.java` 掃描出的 42 個 SOAP method。
2. 所有列均已具備 `status/reason/owner/target milestone`，符合 P0 治理要求。
3. `waived` 項有明確回收條件；條件成立前保持 webview 路徑。

