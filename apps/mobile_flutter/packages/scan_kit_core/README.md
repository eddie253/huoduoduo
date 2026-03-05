# scan_kit_core

Reusable scanner module for HDD Flutter apps.

## Features

- `flutter_zxing`-based scan engine adapter (`ZxingEngineAdapter`)
- Domain-first scan request/result/failure models
- Scan session controller with dedup and mode/symbology filtering
- Reusable scanner UI components:
  - `HddScannerView`
  - `HddScannerToolbar`
  - `HddManualInputSheet`
  - `ScanFrameOverlay`

## Install

```yaml
dependencies:
  scan_kit_core:
    path: packages/scan_kit_core
```

## Basic Usage

```dart
final controller = ScanSessionController();

controller.start(
  const ScanRequest(
    scanType: 'default',
    mode: ScanMode.all,
    allowedSymbologies: legacyEquivalentSymbologies,
  ),
);

final sub = controller.events.listen((event) {
  if (event is ScanSuccessEvent) {
    final value = event.result.value;
    // handle value
  }
});
```

## Notes

- This package does not include voice playback logic.
- Keep bridge contract in app layer unchanged (`open_IMG_Scanner(type)`).

