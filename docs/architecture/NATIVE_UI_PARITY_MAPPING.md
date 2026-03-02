# Native UI Parity Mapping (Legacy -> Flutter) (PLAN14 + PLAN15)

## Status Legend
1. `done`
2. `deferred`
3. `out_of_scope`

## Mapping

| Legacy Screen ID | Flutter Route / Feature | Status | Gap Type | Notes |
|---|---|---|---|---|
| `NAT-HOME-TOOLBAR` | `/webview` + shell navigation | deferred | UI/behavior | Owner: Mobile UI, Target Wave: 16, Risk: low (navigation usable, visual parity pending). |
| `NAT-MENU-RESERVATION` | `/webview` reservation pages | deferred | UI | Owner: Mobile UI, Target Wave: 16, Risk: medium (legacy menu icon/layout parity pending). |
| `NAT-MENU-SHIPMENT` | `/shipment` + bridge routes | done | behavior/data | Queue upload/retry/dead-letter path is covered by tests and smoke flow. |
| `NAT-MENU-ARRIVAL` | `/shipment` + `/signature` + `/scanner` | deferred | behavior | Owner: Mobile Native Feature Team, Target Wave: 16, Risk: medium (multi-device scanner/signature parity pending). |
| `NAT-MENU-CURRENCY` | `/webview` + `/notifications` | deferred | UI | Owner: Mobile UI, Target Wave: 16, Risk: low (core entry works; legacy composition parity pending). |
| `NAT-WEBVIEW-SHELL` | `/webview` (`WebViewShellPage`) | done | - | bootstrap/cookie/allowlist integrated; unauthorized redirect and block paths covered. |
| `NAT-SCANNER` | `/scanner` (`ScannerPage`) | deferred | behavior | Owner: Mobile Native Feature Team, Target Wave: 16, Risk: medium (camera real-device variance). |
| `NAT-SIGNATURE` | `/signature` (`SignaturePage`) | deferred | behavior | Owner: Mobile Native Feature Team, Target Wave: 16, Risk: medium (file output/device-specific interaction parity). |
| `NAT-MAP-GOOGLE` | `/maps` + `APPEvent(map)` | deferred | behavior/permission | Owner: Mobile Native Feature Team, Target Wave: 16, Risk: medium (location permission UX on-device). |
| `NAT-MAP-EXTERNAL-URI` | `BridgeActionExecutor.launchExternal(...)` | done | - | External map URI handoff is wired and unit-tested. |
| `NAT-DIALER` | `APPEvent(dial)` -> `tel:` | done | - | Dial event dispatch is wired and validated in bridge tests. |
| `NAT-OPEN-FILE` | `openfile/contract` allowlist + https | done | - | Strict allowlist + HTTPS path and error branches are covered. |
| `NAT-UPLOAD-ERR-MSG` | `/shipment` queue state panel | deferred | UI | Owner: Mobile UI, Target Wave: 16, Risk: low (queue state shown; legacy visual parity pending). |
| `NAT-SETTING` | settings capability (to be expanded) | deferred | UI | Owner: Mobile UI, Target Wave: 17, Risk: low (minimal shell exists). |
| `NAT-LOGOUT-CONFIRM` | logout + session cleanup | done | - | token/cookie/storage/cache cleanup is in place and covered. |

## Explicit Out-of-Scope

| Legacy Screen ID | Flutter Route / Feature | Status | Reason |
|---|---|---|---|
| `maphwo.MapsActivity` | N/A | out_of_scope | Excluded by PLAN14 decision to avoid dual map-engine parity risk. |
