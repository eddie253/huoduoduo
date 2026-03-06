# mobile_flutter

Flutter client for Wave 2 -> Wave 4 migration.

## Included baseline

- Riverpod state management
- go_router navigation
- Dio API client
- Secure token storage
- WebView shell (`flutter_inappwebview`) with bridge adapter (`window.android.*`)
- Native bridge actions: open file, scanner, signature, app events (map/dial/close/contract)
- Local media queue (SQLite metadata only) with retry/dead-letter policy

## Local media queue policy

1. SQLite stores only media metadata and upload state (`trackingNo/filePath/fileName/status/retryCount`).
2. Tokens/passwords/secrets are forbidden in local SQLite metadata.
3. Real credentials remain in secure storage only.

## Local validation

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

## Coverage

```bash
flutter test --coverage
```

Monorepo helper commands (from repo root):

```bash
npm run mobile:test:coverage
npm run mobile:coverage:check
```

`npm run mobile:coverage:check` enforces Flutter line coverage >= 65.

## CI automation

- Jenkins：維持原本的 mobile verify & apk build（依 repo root scripts）。
- GitHub Actions：`.github/workflows/mobile-flutter-tests.yml` 在 push / PR 變動 `apps/mobile_flutter/**` 時會自動跑 `flutter analyze` 與 `flutter test`。

Coverage artifacts are generated in:

- `apps/mobile_flutter/coverage/lcov.info` (raw)
- `reports/coverage/mobile/lcov.info` (collected)

## Unit / Widget test coverage (PLAN23)

New test files added to raise line coverage above 65%:

| Test file | Source covered |
|-----------|---------------|
| `test/app/theme/app_theme_preset_test.dart` | `lib/app/theme/app_theme_preset.dart` – `fromStorageKey` all branches, round-trip, color properties |
| `test/app/theme/theme_preference_store_test.dart` | `lib/app/theme/theme_preference_store.dart` + `AppThemePrefs` – read/write/copyWith |
| `test/core/storage/token_storage_test.dart` | `lib/core/storage/token_storage.dart` – saveTokens, read, clear (method-channel mock) |
| `test/features/webview_shell/presentation/webview_shell_page_test.dart` | `lib/features/webview_shell/presentation/webview_shell_page.dart` – scaffold, bottom bar tabs, back-button opacity, settings button |

> Widget tests for `WebViewShellPage` suppress `MissingPluginException` from `InAppWebView` / `CookieManager`
> platform channels (mocked via `setMockMethodCallHandler`) and are safe to run in headless CI.

## Android real-device smoke

```bash
flutter run -d <android-device-id> --dart-define=API_BASE_URL=http://<bff-host>:3000/v1
```

## Android integration test: login -> webview

1. Create local env file (not tracked by git):

```bash
Copy-Item .env.local.example .env.local
```

2. Fill `.env.local` with `UAT_ACCOUNT` and `UAT_PASSWORD`.
3. Ensure BFF is running and emulator/device is online.
4. Run from repo root:

```bash
npm run mobile:test:login-it
```

Optional device target:

```bash
powershell -ExecutionPolicy Bypass -File .\scripts\run-mobile-login-it.ps1 -DeviceId emulator-5554
```

Manual flow:

1. Login with UAT account.
2. Verify app routes to `/webview` and loads bootstrap URL.
3. Trigger bridge methods from web pages:
1. `openfile`
2. `open_IMG_Scanner`
3. `cfs_sign`
4. `APPEvent` map/dial/close/contract
4. Open shipment page and run delivery/exception upload.
5. Retry failed queue and verify dead-letter behavior.
6. Logout and verify web session cleared.

## iOS build and smoke (Mac required)

```bash
flutter build ios --no-codesign
flutter run -d <ios-device-id> --dart-define=API_BASE_URL=http://<bff-host>:3000/v1
```

## Windows + Mac split workflow

1. Windows phase:
1. implement shared Dart code
2. run `flutter analyze`, `flutter test`, `flutter build apk --debug`
2. Mac phase:
1. run `flutter build ios --no-codesign`
2. configure signing in Xcode
3. run iOS real-device smoke

## iOS permission checklist (Mac stage)

1. Camera usage description
2. Photo library usage description
3. Location usage description (if map workflow requires)
