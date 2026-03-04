# E2E Smoke Runbook (Android + iOS)

Doc ID: HDD-DOCS-ARCHITECTURE-E2E-SMOKE-RUNBOOK
Version: v1.0
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: Draft
CN/EN Pair Link: N/A






## Preconditions

1. BFF reachable (`/v1/health` OK).
2. Redis available for token store.
3. UAT account prepared.
4. At least one valid tracking number (default manual: `907563299214`).

## API smoke (backend)

```bash
npm run bff:verify
powershell -ExecutionPolicy Bypass -File .\scripts\run-wave2-uat-smoke.ps1 -Account "<masked>" -Password "<masked>" -TrackingNo "907563299214"
```

Expected:

1. login PASS
2. bootstrap PASS
3. refresh PASS
4. shipment PASS
5. logout PASS

## Android smoke

```bash
cd apps/mobile_flutter
flutter analyze
flutter test
flutter build apk --debug
flutter run -d <android-device-id> --dart-define=API_BASE_URL=http://<bff-host>:3000/v1
```

Manual checks:

1. Login success.
2. Route enters WebView.
3. Whitelist navigation works and non-whitelist is blocked.
4. Shipment query path works with valid tracking number.
5. Logout completes and session is revoked.

## iOS smoke (Mac only)

```bash
cd apps/mobile_flutter
flutter analyze
flutter test
flutter build ios --no-codesign
flutter run -d <ios-device-id> --dart-define=API_BASE_URL=http://<bff-host>:3000/v1
```

Manual checks same as Android.

## Failure classification

1. `PASS`: all steps succeeded.
2. `BLOCKED`: prerequisite/data missing (for example no reservation tracking).
3. `FAIL`: implementation or environment defect.

## Evidence format

Record in wave evidence doc:

1. date/time
2. environment
3. commands executed
4. masked request/response summary
5. failure classification and reproduction steps

