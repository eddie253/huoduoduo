# hdd_scan_kit

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
  hdd_scan_kit:
    path: packages/hdd_scan_kit
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
