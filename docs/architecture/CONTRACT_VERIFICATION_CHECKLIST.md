# Contract Verification Checklist

## API contract

1. [ ] OpenAPI path list matches controllers.
2. [ ] `POST` endpoints return expected status code (`200` where specified).
3. [ ] Unauthorized behavior matches contract (`/bootstrap/webview` -> `401` without token).
4. [ ] Error object shape matches OpenAPI schema (`code`, `message`).

Commands:

```bash
npm run bff:route-diff
npm run bff:test -- --runInBand
```

## SOAP mapping contract

1. [ ] `login -> GetLogin` mapping verified.
2. [ ] `shipment -> GetShipment_elf/GetShipment` fallback verified.
3. [ ] `reservation mode=standard|bulk` mapping verified.
4. [ ] `push/register -> UpdateRegID` mapping verified.

Reference:

1. `contracts/legacy/soap-mapping-v1.md`
2. `apps/bff_gateway/src/adapters/soap/legacy-soap.client.ts`

## Bridge contract

1. [ ] 8 methods are accepted by adapter layer.
2. [ ] Unsupported method returns `BRIDGE_UNSUPPORTED_METHOD`.
3. [ ] Invalid payload returns `BRIDGE_INVALID_PAYLOAD`.
4. [ ] Permission denied path returns `BRIDGE_PERMISSION_DENIED`.
5. [ ] Runtime protection returns `BRIDGE_RUNTIME_ERROR`.

Reference:

1. `contracts/bridge/js-bridge-v1.md`
2. `contracts/legacy/bridge-matrix-v1.md`

## Error-code normalization

1. [ ] SOAP timeout/network -> `LEGACY_TIMEOUT` (`502`).
2. [ ] SOAP malformed/protocol -> `LEGACY_BAD_RESPONSE` (`502`).
3. [ ] SOAP business error string -> `LEGACY_BUSINESS_ERROR` (`422`).

Reference:

1. `contracts/legacy/error-code-mapping-v1.md`

## CI final gate

1. [ ] `npm run bff:verify`
2. [ ] `flutter analyze`
3. [ ] `flutter test`
4. [ ] `flutter build apk --debug`
5. [ ] `flutter build ios --no-codesign` (macOS runner)
