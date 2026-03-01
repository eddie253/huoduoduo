# JS Bridge Matrix v1 (Legacy -> Flutter)

## Scope

Legacy bridge source:

1. `app/src/main/java/didi/app/express/AppWebView.java`

Current Flutter bridge source:

1. `apps/mobile_flutter/lib/features/webview_shell/application/js_bridge_service.dart`
2. `contracts/bridge/js-bridge-v1.md`

## Method parity matrix

| Legacy Method (`window.android.*`) | Legacy Behavior (Android) | Flutter v1 Behavior | Status |
|---|---|---|---|
| `error()` | Trigger app-side relogin flow | Returns `{ ok: true, action: "reload_requested" }` | Compatible baseline |
| `RefreshEnable(enable)` | Enable/disable swipe refresh | Returns `{ ok: true, action: "refresh_state_updated" }` | Compatible baseline |
| `redirect(page)` | Native redirect/page transition | Returns `{ ok: true, action: "redirect_received" }` | Compatible baseline |
| `openfile(url)` | Open file/download flow (legacy had partial implementation) | Validates HTTPS + allowlist host then opens external URL | Executable |
| `open_IMG_Scanner(type)` | Open scanner | Routes to scanner page and returns scanned value payload | Executable |
| `openMsgExit(msg)` | Show message dialog and allow logout | Shows dialog and returns `{ ok: true, action: "dialog_shown" }` | Compatible baseline |
| `cfs_sign()` | Open signature screen | Routes to signature page and returns PNG metadata payload | Executable |
| `APPEvent(kind, result)` | Dispatch multiple native events (map, dial, close, contract, etc.) | Event-specific handlers for map/dial/close/contract | Executable |

## Envelope

Flutter bridge accepts envelope:

```json
{
  "id": "unique-id",
  "version": "1.0",
  "method": "openfile",
  "params": { "url": "..." },
  "timestamp": 1730000000
}
```

## Standard bridge errors

1. `BRIDGE_INVALID_PAYLOAD`
2. `BRIDGE_UNSUPPORTED_METHOD`
3. `BRIDGE_PERMISSION_DENIED`
4. `BRIDGE_RUNTIME_ERROR`
