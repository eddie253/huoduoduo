# Native UI Parity Mapping (Legacy -> Flutter) (PLAN14 + PLAN15)

## Status Legend
1. `done`
2. `waived`
3. `deferred`
4. `out_of_scope`

## Mapping

| Legacy Screen ID | Flutter Route / Feature | Status | Gap Type | Notes |
|---|---|---|---|---|
| `NAT-HOME-TOOLBAR` | `/webview` + shell navigation | done | behavior | Legacy 4-section toolbar and back behavior are aligned in shell menu mapping. |
| `NAT-MENU-RESERVATION` | `/webview` reservation pages | done | behavior | Legacy reservation menu routes (`rvt/*`, `inq/*`) are centralized in `legacy_menu_mapping`. |
| `NAT-MENU-SHIPMENT` | `/shipment` + bridge routes | done | behavior/data | Queue upload/retry/dead-letter path is covered by tests and smoke flow. |
| `NAT-MENU-ARRIVAL` | `/shipment` + `/signature` + `/scanner` + `/arrival-upload-errors` | done | behavior | Arrival menu now maps to legacy actions, including upload error list entry. |
| `NAT-MENU-CURRENCY` | `/webview` + `/proxy-menu` + `/settings` | done | behavior | Currency menu now maps legacy wallet + proxy + settings + logout actions without notifications placeholder. |
| `NAT-WEBVIEW-SHELL` | `/webview` (`WebViewShellPage`) | done | - | bootstrap/cookie/allowlist integrated; unauthorized redirect and block paths covered. |
| `NAT-SCANNER` | `/scanner` (`ScannerPage`) | waived | real-device variance | Android real-device matrix (camera vendor variance) is tracked separately in UAT evidence. |
| `NAT-SIGNATURE` | `/signature` (`SignaturePage`) | waived | real-device variance | Signature gesture/file-output parity needs multi-device UAT capture before final close. |
| `NAT-MAP-GOOGLE` | `/maps` + `APPEvent(map)` | waived | permission/runtime | Map permission/app-switch evidence on Android real devices is waived to UAT checklist. |
| `NAT-MAP-EXTERNAL-URI` | `BridgeActionExecutor.launchExternal(...)` | done | - | External map URI handoff is wired and unit-tested. |
| `NAT-DIALER` | `APPEvent(dial)` -> `tel:` | done | - | Dial event dispatch is wired and validated in bridge tests. |
| `NAT-OPEN-FILE` | `openfile/contract` allowlist + https | done | - | Strict allowlist + HTTPS path and error branches are covered. |
| `NAT-UPLOAD-ERR-MSG` | `/arrival-upload-errors` | done | behavior | Legacy upload error list is now a dedicated page with per-item retry action. |
| `NAT-SETTING` | `/settings` (version-only) | done | behavior | Settings page is converged to legacy-minimal parity (version information only). |
| `NAT-LOGOUT-CONFIRM` | logout + session cleanup | done | - | token/cookie/storage/cache cleanup is in place and covered. |

## Explicit Out-of-Scope

| Legacy Screen ID | Flutter Route / Feature | Status | Reason |
|---|---|---|---|
| `maphwo.MapsActivity` | N/A | out_of_scope | Excluded by PLAN14 decision to avoid dual map-engine parity risk. |
