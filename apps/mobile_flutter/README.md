# mobile_flutter

Flutter client for the Wave 2 migration baseline.

## Included baseline

- Riverpod state management
- go_router navigation
- Dio API client
- Secure token storage
- WebView shell using `flutter_inappwebview`
- Legacy-compatible JS bridge adapter (`window.android.*`)

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
