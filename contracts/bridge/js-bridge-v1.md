# JS Bridge v1 Contract

## Purpose

Define a strict bridge contract between web pages and Flutter WebView shell while preserving
legacy calls from `window.android.*`.

## Transport

- Handler name: `bridge`
- Direction: Web page -> Flutter
- Envelope:

```json
{
  "id": "uuid-or-unique-string",
  "version": "1.0",
  "method": "openfile",
  "params": { "url": "..." },
  "timestamp": 1730000000
}
```

## Supported methods

1. `error()`
2. `RefreshEnable(enable: string)`
3. `redirect(page: string)`
4. `openfile(url: string)`
5. `open_IMG_Scanner(type: string)`
6. `openMsgExit(msg: string)`
7. `cfs_sign()`
8. `APPEvent(kind: string, result: string)`

## Standard error codes

1. `BRIDGE_INVALID_PAYLOAD`
2. `BRIDGE_UNSUPPORTED_METHOD`
3. `BRIDGE_PERMISSION_DENIED`
4. `BRIDGE_RUNTIME_ERROR`

## Security requirements

1. Allowed origin hosts must be explicit whitelist only.
2. Disallow mixed content and non-HTTPS navigations.
3. Never expose arbitrary JS evaluation API to web content.
4. Every bridge error should be logged with request id and method.

