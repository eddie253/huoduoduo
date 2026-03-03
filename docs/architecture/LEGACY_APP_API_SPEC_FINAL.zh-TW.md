# 舊版 APP API 規格書（完成版）

Doc ID: `HDD-LEGACY-API-SPEC`
Version: `v1.1`
Owner: `Architecture Lead`
Last Updated: `2026-03-03`
Review Status: `Draft for management review`
CN/EN Pair Link:
1. CN: `docs/architecture/LEGACY_APP_API_SPEC_FINAL.zh-TW.md`
2. EN: `docs/architecture/LEGACY_APP_API_SPEC_FINAL.en.md`

## 1. 文件目的

1. 這份文件是「舊 Android APP 已上線版本」的 API 呼叫規格總表。
2. 重點是回答兩件事：
   1. 舊 APP 打哪個網址？
   2. 每支 API 送哪些欄位？
3. 本文件是 as-is 盤點，不代表新 APP 已全部實作。

## 2. 舊 APP 後端連線基準


| 項目                         | 值                                                      | 程式來源                 |
| ---------------------------- | ------------------------------------------------------- | ------------------------ |
| API Host                     | `https://old.huoduoduo.com.tw/`                         | `MainActivity.API_Host`  |
| SOAP Namespace               | `https://driver.huoduoduo.com.tw/`                      | `MainActivity.NAMESPACE` |
| SOAP Endpoint                | `https://old.huoduoduo.com.tw/Inquiry/didiservice.asmx` | `WebService.URL`         |
| 註冊/重設密碼網頁 Host       | `https://old.huoduoduo.com.tw/register/`                | `MainActivity.awv_host`  |
| WebView 預設入口（舊版註解） | `https://app.elf.com.tw/cn/entrust.aspx?IDCompany=S1`   | `AppWebView`             |

## 3. 傳輸規格（舊 APP）

1. 通訊類型：SOAP（ksoap2）。
2. 呼叫格式：`SOAPAction = Namespace + MethodName`。
3. 所有方法最終都走同一個 SOAP URL（`didiservice.asmx`）。
4. 回傳型態：`String`（多數為 JSON 字串；失敗常回 `Error-...` 字串）。

## 4. API 清單（舊 APP 全量）

### 4.1 帳號/裝置/銀行（`ds001User`）


| Method        | 用途（白話） | Request 欄位                       |
| ------------- | ------------ | ---------------------------------- |
| `GetLogin`    | 登入驗證     | `Account`, `Password`, `Kind`      |
| `UpdateRegID` | 註冊推播裝置 | `DNUM`, `RegID`, `Kind`, `Version` |
| `DeleteRegID` | 解除推播裝置 | `Contract`, `RegID`                |
| `UpdateBank`  | 更新銀行資料 | `DNUM`, `Code`, `Account`          |

### 4.2 貨件核心（`ds002貨件`）


| Method                       | 用途（白話）         | Request 欄位                                 |
| ---------------------------- | -------------------- | -------------------------------------------- |
| `AddOrder_elf`               | 接單                 | `DNUM`, `TNUM`                               |
| `BackOrder`                  | 退單                 | `DNUM`, `TNUM`                               |
| `GetShipment`                | 查單（一般）         | `TNUM`                                       |
| `GetShipment_elf`            | 查單（優先路徑）     | `TNUM`                                       |
| `GetShipment_Currency`       | 依應付編號查單       | `OrderNum`                                   |
| `UpdateArrivalErr_NEW`       | 上傳送達異常（單筆） | `DNUM`, `TNUM`, `Image`, `Image_FN`, `Itude` |
| `UpdateArrivalErr_Multi_NEW` | 上傳送達異常（多筆） | `DNUM`, `TNUM`, `Image`, `Image_FN`, `Itude` |
| `ClearArrival`               | 清除簽收狀態         | `DNUM`, `TNUM`                               |
| `UpdateArrival`              | 上傳送達簽收（單筆） | `DNUM`, `TNUM`, `Image`, `Image_FN`, `Itude` |
| `UpdateArrival_Multi`        | 上傳送達簽收（多筆） | `DNUM`, `TNUM`, `Image`, `Image_FN`, `Itude` |
| `Alr_Order`                  | 已接單未送達清單     | `DNUM`                                       |
| `Alr_Shipment`               | 已送達清單           | `DD`, `DNUM`                                 |
| `CreatePath`                 | 路徑規劃資料         | `StartLatLng`, `EndLatLng`, `DNUM`           |
| `CheckedArrivalErr`          | 檢查異常是否可上傳   | `TNUM`, `Itude`                              |

補充：

1. `Itude` 在舊版是經緯度字串，格式常見為 `lat,lng`。
2. `Image` 為 Base64 圖片字串，`Image_FN` 為檔名。

### 4.3 帳務/提款/押金（`ds003帳戶明細`）


| Method                   | 用途（白話）   | Request 欄位                   |
| ------------------------ | -------------- | ------------------------------ |
| `GetDriverCurrency`      | 帳戶明細（日） | `DD`, `DNUM`                   |
| `GetDriverCurrencyMonth` | 帳戶明細（月） | `DD`, `DNUM`                   |
| `GetDriverBalance`       | 餘額           | `DNUM`                         |
| `ApplyWithDrawal`        | 申請提現       | `DNUM`, `Money`                |
| `GetDeposit_Head`        | 押金主檔       | `StartDate`, `EndDate`, `DNUM` |
| `GetDeposit_Body`        | 押金明細       | `TNUM`, `Addr`, `DNUM`         |

### 4.4 預約貨件（`ds004預約貨件`）


| Method        | 用途（白話）         | Request 欄位                 |
| ------------- | -------------------- | ---------------------------- |
| `GetARV_ZIP`  | 查可預約區域         | 無                           |
| `GetARV`      | 查可預約貨件（一般） | `ZIP`, `DNUM`                |
| `GetARVed`    | 查已預約貨件（一般） | `DNUM`                       |
| `UpdateARV`   | 建立預約（一般）     | `NUMs`, `Addr`, `DNUM`       |
| `RemoveARV`   | 取消預約（一般）     | `NUMs`, `Addr`, `DNUM`       |
| `GetAreaCode` | 取得區域代號         | `DNUM`                       |
| `GetArrived`  | 到倉貨件             | `DNUM`                       |
| `GetBARV`     | 查可預約貨件（大貨） | `ZIP`, `DNUM`                |
| `GetBARVed`   | 查已預約貨件（大貨） | `DNUM`                       |
| `UpdateBARV`  | 建立預約（大貨）     | `NUM`, `Addr`, `FEE`, `DNUM` |
| `RemoveBARV`  | 取消預約（大貨）     | `NUM`, `Addr`, `DNUM`        |

### 4.5 代理/KPI（`ds005代理`）


| Method       | 用途（白話）     | Request 欄位            |
| ------------ | ---------------- | ----------------------- |
| `GetPxymate` | 代理組員清單     | `Area`                  |
| `SearchKPI`  | KPI 查詢條件搜索 | `Year`, `Month`, `Area` |
| `GetKPI`     | KPI 月資料       | `Year`, `Month`, `Area` |
| `GetKPI_dis` | KPI 日明細       | `DD`, `Area`            |

### 4.6 系統共用（`WebService`）


| Method          | 用途（白話） | Request 欄位 |
| --------------- | ------------ | ------------ |
| `GetSystemDate` | 取系統日期   | `format`     |
| `GetVersion`    | 取版本資訊   | `Name`       |
| `GetBulletin`   | 取公告       | 無           |

## 5. 統計摘要（給主管看）

1. 舊 APP SOAP 方法總數：`42`。
2. 所有 SOAP 都走同一個 URL：`/Inquiry/didiservice.asmx`。
3. 高頻欄位：
   1. `DNUM`（契約編號）
   2. `TNUM`（查件貨號）
   3. `Image` / `Image_FN` / `Itude`（簽收或異常上傳）

## 6. 舊 APP Web 頁面入口（非 SOAP，但實際有呼叫）

Base：

1. `https://old.huoduoduo.com.tw/app/`

主要入口路徑：

1. Reservation：`rvt/ge.aspx`, `rvt/ge_c.aspx`, `rvt/bh.aspx`, `rvt/bh_c.aspx`, `inq/strg.aspx`, `rvt/df_area.aspx`, `inq/dep.aspx`
2. Shipment：`inq/dtl.aspx`
3. Arrival：`inq/arv.aspx`
4. Currency：`currency/wda.aspx`, `currency/bifm.aspx`, `currency/bank.aspx`, `currency/day_cy.aspx`, `currency/month_cy.aspx`, `currency/virtual.aspx`
5. Proxy：`pxy/mate.aspx`, `pxy/kpi.aspx`
6. 其他註冊流程：`register.aspx`, `register_resetpwd.aspx`, `register_driver_id.aspx`, `register_driver_car.aspx`, `cfs/cfs_sign.aspx`

## 7. 外部服務（補充）

1. TGOS 地址轉座標：`http://addr.tgos.tw/addrws/v40/GeoQueryAddr.asmx`
2. Google Maps Directions/Places API（地圖規劃）

## 8. 資料來源（程式檔）

1. `app/src/main/java/network/*.java`
2. `app/src/main/java/didi/app/express/MainActivity.java`
3. `app/src/main/java/didi/app/express/AppWebView.java`
4. `app/src/main/java/didi/app/express/Menu_GridView*.java`
5. `app/src/main/java/controls/CheckData.java`
