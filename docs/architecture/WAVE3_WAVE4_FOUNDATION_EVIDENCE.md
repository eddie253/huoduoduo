# Wave 3 / Wave 4 Foundation Evidence

## Scope

This evidence file captures PLAN9 foundation delivery:

1. Wave 3 contract-verifiable controls.
2. Wave 4 foundation implementation for WebView cache/session and local media queue orchestration.

## Evidence Checklist

1. CI checks:
1. `npm run bff:verify`
2. `flutter analyze`
3. `flutter test`
4. `flutter build apk --debug`
2. BFF no-store headers:
1. `POST /v1/auth/login`
2. `POST /v1/auth/refresh`
3. `POST /v1/auth/logout`
4. `GET /v1/bootstrap/webview`
5. `GET/POST /v1/shipments*`, `GET/POST/DELETE /v1/reservations*`, `POST /v1/push/register`
3. Flutter bridge tests:
1. 8 methods accepted with expected behavior.
2. 4 standard bridge errors verified.
4. Local media queue tests:
1. schema/index creation
2. enqueue -> failed/uploaded transitions
3. sensitive metadata rejection
4. orchestrator success/failure state mapping

## UAT Smoke (masked summary)

1. login: PASS
2. bootstrap/webview: PASS
3. refresh: PASS
4. shipment (`907563299214`): PASS
5. logout: PASS

## Notes

1. Credential values are masked and never committed.
2. iOS compile/real-device evidence remains in Mac stage gate.
