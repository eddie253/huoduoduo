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
| `openfile(url)` | Open file/download flow (legacy had partial implementation) | Returns `BRIDGE_PERMISSION_DENIED` placeholder | Deferred |
| `open_IMG_Scanner(type)` | Open scanner | Returns `{ ok: true, action: "scanner_requested" }` | Deferred native wiring |
| `openMsgExit(msg)` | Show message dialog and allow logout | Shows dialog and returns `{ ok: true, action: "dialog_shown" }` | Compatible baseline |
| `cfs_sign()` | Open signature screen | Returns `{ ok: true, action: "signature_requested" }` | Deferred native wiring |
| `APPEvent(kind, result)` | Dispatch multiple native events (map, dial, close, contract, etc.) | Returns `{ ok: true, action: "app_event_received" }` | Deferred event-specific wiring |

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
