# Wave 3 / Wave 4 Foundation Evidence (PLAN10 update)

## Scope

This evidence file captures PLAN10 implementation closure on top of PLAN9 foundation.

1. Bridge deferred methods are executable.
2. Native capability pages are no longer placeholders.
3. Shipment upload queue supports retry and dead-letter transitions.
4. Existing BFF contract and no-store behavior remain unchanged.

## Verification Commands

1. `npm run bff:verify`
2. `flutter analyze`
3. `flutter test`
4. `flutter build apk --debug`

## Bridge Evidence

1. `openfile(url)` enforces HTTPS + host allowlist.
2. `open_IMG_Scanner(type)` routes to scanner page and returns scan payload.
3. `cfs_sign()` routes to signature page and returns PNG file metadata.
4. `APPEvent(kind,result)` supports:
1. map
2. dial
3. close
4. contract

## Queue Evidence

1. `uploadDelivery` / `uploadException` enqueue and attempt immediate upload.
2. upload failure increments retry counter and keeps failed state.
3. failed item crossing retry cap moves to `dead_letter`.
4. startup maintenance executes:
1. cleanup uploaded records older than retention.
2. move over-limit failed records to dead letter.

## UAT Smoke (masked summary)

1. login: PASS
2. bootstrap/webview: PASS
3. refresh: PASS
4. shipment (`907563299214`): PASS
5. logout: PASS

## Notes

1. OpenAPI canonical remains `contracts/openapi/huoduoduo-v1.openapi.yaml`.
2. No BFF endpoint path/schema changes in PLAN10.
3. iOS validation remains a Mac gate (`flutter build ios --no-codesign` + real device smoke).
