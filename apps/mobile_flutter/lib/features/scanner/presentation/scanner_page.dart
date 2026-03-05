import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hdd_scan_kit/hdd_scan_kit.dart';

typedef ScannerViewBuilder = Widget Function(
  BuildContext context,
  ValueChanged<Object> onEngineCode,
);

const String scannerHintText = '請將條碼或 QR Code 對準掃描框';
const Key scannerCloseButtonKey = Key('scanner_close_button');
const Key scannerToolRowKey = Key('scanner_tool_row');
const Key scannerFlashButtonKey = Key('scanner_flash_button');
const Key scannerKeypadButtonKey = Key('scanner_keypad_button');
const Key scannerSettingButtonKey = Key('scanner_setting_button');
const Key scannerFrameOverlayKey = Key('scanner_frame_overlay');
const Key scannerFrameWindowKey = Key('scanner_frame_window');

String scannerTitleFor(String scanType) => '掃描：$scanType';

enum ScannerCodeMode {
  all,
  oneDimensional,
  twoDimensional,
}

String scannerCodeModeLabel(ScannerCodeMode mode) {
  switch (mode) {
    case ScannerCodeMode.oneDimensional:
      return '1D';
    case ScannerCodeMode.twoDimensional:
      return '2D';
    case ScannerCodeMode.all:
      return 'All';
  }
}

ScanFrameMode scanFrameModeFor(ScannerCodeMode mode) {
  if (mode == ScannerCodeMode.oneDimensional) {
    return ScanFrameMode.oneDimensional;
  }
  return ScanFrameMode.twoDimensional;
}

Rect legacyScanFrameRect(Size size, ScanFrameMode mode) {
  return scanFrameRect(size, mode);
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
  static const Color _legacyHeaderColor = Color(0xFFFC5000);

  final ScanSessionController _controller = ScanSessionController();
  StreamSubscription<ScanEvent>? _eventSubscription;
  bool _isCompleted = false;
  bool _torchOn = false;
  ScannerCodeMode _scanMode = ScannerCodeMode.all;
  late ScanRequest _request;

  @override
  void initState() {
    super.initState();
    _scanMode = _defaultScanMode(widget.scanType);
    _request = _buildRequest();
    _eventSubscription = _controller.events.listen(_onScanEvent);
    _controller.start(_request);
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onScanEvent(ScanEvent event) {
    if (event is! ScanSuccessEvent) {
      return;
    }
    _completeWith(event.result.value);
  }

  void _completeWith(String value) {
    if (_isCompleted) {
      return;
    }
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _isCompleted = true;
    _controller.stop();
    Navigator.of(context).pop(trimmed);
  }

  ScanRequest _buildRequest() {
    final ScanMode mode = _toScanMode(_scanMode);
    final Set<ScanSymbology> allowedSymbologies =
        _allowedSymbologiesFor(widget.scanType, _scanMode);

    return ScanRequest(
      scanType: widget.scanType,
      mode: mode,
      allowedSymbologies: allowedSymbologies,
      dedupWindowMs: 800,
      sessionId: '${widget.scanType}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<void> _toggleTorch() async {
    final bool torchOn = await _controller.toggleTorch();
    if (!mounted) {
      return;
    }
    setState(() {
      _torchOn = torchOn;
    });
  }

  Future<void> _openManualInputPad() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HddManualInputSheet(),
    );
    if (!mounted || result == null) {
      return;
    }
    _controller.submitManualInput(result);
  }

  Future<void> _openScanModeSettings() async {
    ScannerCodeMode selectedMode = _scanMode;
    final ScannerCodeMode? nextMode = await showDialog<ScannerCodeMode>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('掃描模式'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ChoiceChip(
                    label: const Text('全部（1D + 2D）'),
                    selected: selectedMode == ScannerCodeMode.all,
                    onSelected: (_) {
                      setDialogState(() {
                        selectedMode = ScannerCodeMode.all;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('一維條碼'),
                    selected: selectedMode == ScannerCodeMode.oneDimensional,
                    onSelected: (_) {
                      setDialogState(() {
                        selectedMode = ScannerCodeMode.oneDimensional;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('二維條碼'),
                    selected: selectedMode == ScannerCodeMode.twoDimensional,
                    onSelected: (_) {
                      setDialogState(() {
                        selectedMode = ScannerCodeMode.twoDimensional;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(selectedMode),
              child: const Text('確定'),
            ),
          ],
        );
      },
    );

    if (!mounted || nextMode == null) {
      return;
    }
    setState(() {
      _scanMode = nextMode;
      _request = _buildRequest();
    });
    _controller.start(_request);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          HddScannerView(
            controller: _controller,
            request: _request,
            overlayKey: scannerFrameOverlayKey,
            windowKey: scannerFrameWindowKey,
            engineViewBuilder: widget.scannerViewBuilder,
          ),
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
          Positioned(
            left: 20,
            right: 20,
            bottom: 120,
            child: Column(
              children: <Widget>[
                const Text(
                  scannerHintText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      'Mode: ${scannerCodeModeLabel(_scanMode)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: HddScannerToolbar(
                torchOn: _torchOn,
                onToggleTorch: _toggleTorch,
                onManualInput: _openManualInputPad,
                onOpenSettings: _openScanModeSettings,
                toolRowKey: scannerToolRowKey,
                flashButtonKey: scannerFlashButtonKey,
                keypadButtonKey: scannerKeypadButtonKey,
                settingButtonKey: scannerSettingButtonKey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

ScannerCodeMode _defaultScanMode(String scanType) {
  final String normalized = scanType.trim().toLowerCase();
  if (normalized.contains('qr')) {
    return ScannerCodeMode.twoDimensional;
  }
  if (normalized.contains('1d') || normalized.contains('barcode')) {
    return ScannerCodeMode.oneDimensional;
  }
  return ScannerCodeMode.all;
}

Set<ScanSymbology> _allowedSymbologiesFor(
  String scanType,
  ScannerCodeMode mode,
) {
  final String normalized = scanType.trim().toLowerCase();
  if (normalized.isEmpty || normalized == 'default') {
    return legacyEquivalentSymbologies;
  }
  if (mode == ScannerCodeMode.twoDimensional) {
    return <ScanSymbology>{
      ScanSymbology.qrCode,
      ScanSymbology.pdf417,
      ScanSymbology.dataMatrix,
      ScanSymbology.aztec,
    };
  }
  if (mode == ScannerCodeMode.oneDimensional) {
    return <ScanSymbology>{
      ScanSymbology.code39,
      ScanSymbology.code128,
      ScanSymbology.ean13,
      ScanSymbology.ean8,
      ScanSymbology.upca,
      ScanSymbology.upce,
    };
  }
  return legacyEquivalentSymbologies;
}

ScanMode _toScanMode(ScannerCodeMode mode) {
  switch (mode) {
    case ScannerCodeMode.oneDimensional:
      return ScanMode.oneDimensional;
    case ScannerCodeMode.twoDimensional:
      return ScanMode.twoDimensional;
    case ScannerCodeMode.all:
      return ScanMode.all;
  }
}
