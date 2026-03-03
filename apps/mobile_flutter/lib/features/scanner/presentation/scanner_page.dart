import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

typedef ScannerViewBuilder = Widget Function(
  MobileScannerController controller,
  ValueChanged<String> onDetectedValue,
);

const String scannerHintText = 'Point the camera to barcode or QR code';
const Key scannerCloseButtonKey = Key('scanner_close_button');
const Key scannerToolRowKey = Key('scanner_tool_row');

String scannerTitleFor(String scanType) => 'Scanner ($scanType)';

String firstNonEmptyBarcodeValue(BarcodeCapture capture) {
  return capture.barcodes
      .map((barcode) => barcode.rawValue ?? '')
      .firstWhere((item) => item.trim().isNotEmpty, orElse: () => '')
      .trim();
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({
    super.key,
    this.scanType = 'default',
    this.scannerViewBuilder,
  });

  final String scanType;
  final ScannerViewBuilder? scannerViewBuilder;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  static const Color _legacyHeaderColor = Color(0xFFFF5F00);
  static const Color _legacyToolBackdropColor = Color(0x8C000000);

  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _isCompleted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _completeWith(String value) {
    if (_isCompleted) {
      return;
    }
    _isCompleted = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final scannerView =
        (widget.scannerViewBuilder ?? _defaultScannerViewBuilder)(
      _controller,
      (String value) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          _completeWith(trimmed);
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          scannerView,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ColoredBox(
              color: _legacyHeaderColor,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 40,
                  child: Stack(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          key: scannerCloseButtonKey,
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          tooltip: 'Close scanner',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Center(
                        child: Text(
                          scannerTitleFor(widget.scanType),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 20,
            right: 20,
            bottom: 120,
            child: Text(
              scannerHintText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: Row(
                key: scannerToolRowKey,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _LegacyToolIcon(icon: Icons.flashlight_on_outlined),
                  SizedBox(width: 20),
                  _LegacyToolIcon(icon: Icons.edit_outlined),
                  SizedBox(width: 20),
                  _LegacyToolIcon(icon: Icons.photo_library_outlined),
                  SizedBox(width: 20),
                  _LegacyToolIcon(icon: Icons.reply_outlined),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultScannerViewBuilder(
    MobileScannerController controller,
    ValueChanged<String> onDetectedValue,
  ) {
    return MobileScanner(
      controller: controller,
      onDetect: (BarcodeCapture capture) {
        final value = firstNonEmptyBarcodeValue(capture);
        if (value.isNotEmpty) {
          onDetectedValue(value);
        }
      },
    );
  }
}

class _LegacyToolIcon extends StatelessWidget {
  const _LegacyToolIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        color: _ScannerPageState._legacyToolBackdropColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}
