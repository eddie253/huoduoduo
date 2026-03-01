# mobile_flutter

Flutter client for the Wave 2 migration baseline.

## Included baseline

- Riverpod state management
- go_router navigation
- Dio API client
- Secure token storage
- WebView shell using `flutter_inappwebview`
- Legacy-compatible JS bridge adapter (`window.android.*`)
- Local media queue skeleton (SQLite metadata only, no credential storage)

## Local media queue policy (Wave 4 prep)

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

## Android real-device smoke

```bash
flutter run -d <android-device-id> --dart-define=API_BASE_URL=http://<bff-host>:3000/v1
```

Manual flow:

1. Login with UAT account.
2. Verify app routes to `/webview` and loads bootstrap URL.
3. Verify shipment query with tracking no `907563299214`.
4. Logout and verify session is revoked in BFF logs.

## iOS build and smoke (Mac required)

```bash
flutter build ios --no-codesign
flutter run -d <ios-device-id> --dart-define=API_BASE_URL=http://<bff-host>:3000/v1
```

Manual flow is the same as Android core smoke.

## Windows + Mac split workflow

1. Windows phase:
1. implement shared Dart code
2. run `flutter analyze`, `flutter test`, `flutter build apk --debug`
2. Mac phase:
1. run `flutter build ios --no-codesign`
2. run iOS real-device smoke after signing setup
