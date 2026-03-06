// ignore: depend_on_referenced_packages
import 'package:camera/camera.dart' show CameraController, FlashMode;
import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart' show Code, ReaderWidget;

import '../application/scan_session_controller.dart';
import '../domain/scan_models.dart';
import '../infrastructure/flutter_zxing/symbology_mapper.dart';
import 'scan_frame_overlay.dart';

typedef ScannerEngineViewBuilder = Widget Function(
  BuildContext context,
  ValueChanged<Object> onEngineCode,
);

class HddScannerView extends StatefulWidget {
  const HddScannerView({
    super.key,
    required this.controller,
    required this.request,
    this.frameSize = ScanFrameSize.medium,
    this.overlayKey,
    this.windowKey,
    this.engineViewBuilder,
  });

  final ScanSessionController controller;
  final ScanRequest request;
  final ScanFrameSize frameSize;
  final Key? overlayKey;
  final Key? windowKey;
  final ScannerEngineViewBuilder? engineViewBuilder;

  @override
  State<HddScannerView> createState() => _HddScannerViewState();
}

class _HddScannerViewState extends State<HddScannerView> {
  static const SymbologyMapper _mapper = SymbologyMapper();
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    widget.controller.bindTorchToggleHandler(_toggleTorch);
  }

  Future<bool> _toggleTorch() async {
    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return false;
    }
    try {
      final FlashMode nextMode = controller.value.flashMode == FlashMode.torch
          ? FlashMode.off
          : FlashMode.torch;
      await controller.setFlashMode(nextMode);
      return nextMode == FlashMode.torch;
    } catch (_) {
      return false;
    }
  }

  void _onEngineCode(Object code) {
    widget.controller.consumeEngineCode(code);
  }

  @override
  Widget build(BuildContext context) {
    final ScanFrameMode frameMode = scanFrameModeFor(widget.request.mode);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.engineViewBuilder?.call(context, _onEngineCode) ??
            ReaderWidget(
              codeFormat: _mapper.toZxingFormatMask(
                widget.request.allowedSymbologies,
                widget.request.mode,
              ),
              showFlashlight: false,
              showGallery: false,
              showToggleCamera: false,
              showScannerOverlay: false,
              scanDelay: Duration(milliseconds: widget.request.scanDelayMs),
              scanDelaySuccess:
                  Duration(milliseconds: widget.request.scanDelaySuccessMs),
              onControllerCreated:
                  (CameraController? controller, Exception? error) {
                if (error == null) {
                  _cameraController = controller;
                }
              },
              onScan: (Code code) => _onEngineCode(code),
            ),
        IgnorePointer(
          child: ScanFrameOverlay(
            key: widget.overlayKey,
            mode: frameMode,
            frameSize: widget.frameSize,
            windowKey: widget.windowKey,
          ),
        ),
      ],
    );
  }
}
