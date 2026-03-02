# Native UI Parity Mapping (Legacy -> Flutter) (PLAN14)

## Status Legend
1. `done`
2. `in_progress`
3. `deferred`
4. `out_of_scope`

## Mapping

| Legacy Screen ID | Flutter Route / Feature | Status | Gap Type | Notes |
|---|---|---|---|---|
| `NAT-HOME-TOOLBAR` | `/webview` + shell navigation | in_progress | UI/behavior | Flutter is webview-first; menu parity visuals still being refined. |
| `NAT-MENU-RESERVATION` | `/webview` reservation pages | in_progress | UI | Main business flow is web content; native entry UX still aligning. |
| `NAT-MENU-SHIPMENT` | `/shipment` + bridge routes | in_progress | behavior/data | Queue foundation exists; interaction parity still converging. |
| `NAT-MENU-ARRIVAL` | `/shipment` + `/signature` + `/scanner` | in_progress | behavior | Arrival paths need more 1:1 behavior checks. |
| `NAT-MENU-CURRENCY` | `/webview` + `/notifications` | in_progress | UI | Core actions remain web-hosted; native shell entry keeps improving. |
| `NAT-WEBVIEW-SHELL` | `/webview` (`WebViewShellPage`) | done | - | bootstrap/cookie/allowlist already integrated. |
| `NAT-SCANNER` | `/scanner` (`ScannerPage`) | in_progress | behavior | Scanner return path is wired; more device scenarios pending. |
| `NAT-SIGNATURE` | `/signature` (`SignaturePage`) | in_progress | behavior | Signature canvas + PNG output is available. |
| `NAT-MAP-GOOGLE` | `/maps` + `APPEvent(map)` | in_progress | behavior/permission | Google map path only in PLAN14. |
| `NAT-MAP-EXTERNAL-URI` | `BridgeActionExecutor.launchExternal(...)` | done | - | External map URI handoff is wired. |
| `NAT-DIALER` | `APPEvent(dial)` -> `tel:` | done | - | Dial event dispatch is wired. |
| `NAT-OPEN-FILE` | `openfile/contract` allowlist + https | in_progress | security/behavior | Continue validating strict block on non-allowlist URLs. |
| `NAT-UPLOAD-ERR-MSG` | `/shipment` queue state panel | in_progress | UI | Queue state panel replaces legacy error page behavior. |
| `NAT-SETTING` | settings capability (to be expanded) | deferred | UI | Minimal shell exists; feature depth deferred. |
| `NAT-LOGOUT-CONFIRM` | logout + session cleanup | done | - | token/cookie/storage/cache cleanup is in place. |

## Explicit Out-of-Scope

| Legacy Screen ID | Flutter Route / Feature | Status | Reason |
|---|---|---|---|
| `maphwo.MapsActivity` | N/A | out_of_scope | Excluded by PLAN14 decision to avoid dual map-engine parity risk. |
