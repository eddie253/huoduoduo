import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

typedef ScannerViewBuilder = Widget Function(
  MobileScannerController controller,
  ValueChanged<String> onDetectedValue,
);

const String scannerHintText = '請將條碼或 QR Code 對準掃描框';
const Key scannerCloseButtonKey = Key('scanner_close_button');
const Key scannerToolRowKey = Key('scanner_tool_row');
const Key scannerFlashButtonKey = Key('scanner_flash_button');
const Key scannerKeypadButtonKey = Key('scanner_keypad_button');
const Key scannerSettingButtonKey = Key('scanner_setting_button');
const Key scannerFrameOverlayKey = Key('scanner_frame_overlay');
const Key scannerFrameWindowKey = Key('scanner_frame_window');

String scannerTitleFor(String scanType) => '掃描器（$scanType）';

enum ScanFrameMode {
  oneDimensional,
  twoDimensional,
}

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

const Set<BarcodeFormat> _twoDimensionalFormats = <BarcodeFormat>{
  BarcodeFormat.qrCode,
  BarcodeFormat.dataMatrix,
  BarcodeFormat.pdf417,
  BarcodeFormat.aztec,
};

bool isBarcodeAllowedForMode({
  required BarcodeFormat format,
  required ScannerCodeMode mode,
}) {
  if (mode == ScannerCodeMode.all ||
      format == BarcodeFormat.unknown ||
      format == BarcodeFormat.all) {
    return true;
  }
  final bool isTwoDimensional = _twoDimensionalFormats.contains(format);
  if (mode == ScannerCodeMode.twoDimensional) {
    return isTwoDimensional;
  }
  return !isTwoDimensional;
}

String firstNonEmptyBarcodeValueForMode(
  BarcodeCapture capture,
  ScannerCodeMode mode,
) {
  return capture.barcodes
      .where(
        (barcode) => isBarcodeAllowedForMode(
          format: barcode.format,
          mode: mode,
        ),
      )
      .map((barcode) => barcode.rawValue ?? '')
      .firstWhere((item) => item.trim().isNotEmpty, orElse: () => '')
      .trim();
}

String firstNonEmptyBarcodeValue(BarcodeCapture capture) {
  return firstNonEmptyBarcodeValueForMode(capture, ScannerCodeMode.all);
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
  bool _torchOn = false;
  ScannerCodeMode _scanMode = ScannerCodeMode.all;

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

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (!mounted) {
        return;
      }
      setState(() {
        _torchOn = !_torchOn;
      });
    } catch (_) {
      // Ignore torch errors on devices that do not support flashlight.
    }
  }

  Future<void> _openManualInputPad() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const _ManualInputPad();
      },
    );
    if (!mounted || result == null) {
      return;
    }
    final trimmed = result.trim();
    if (trimmed.isNotEmpty) {
      _completeWith(trimmed);
    }
  }

  Future<void> _openScanModeSettings() async {
    ScannerCodeMode selectedMode = _scanMode;
    final ScannerCodeMode? nextMode = await showDialog<ScannerCodeMode>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('掃描設定'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      ChoiceChip(
                        label: const Text('一維條碼 + 二維條碼'),
                        selected: selectedMode == ScannerCodeMode.all,
                        onSelected: (_) {
                          setDialogState(() {
                            selectedMode = ScannerCodeMode.all;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('一維條碼'),
                        selected:
                            selectedMode == ScannerCodeMode.oneDimensional,
                        onSelected: (_) {
                          setDialogState(() {
                            selectedMode = ScannerCodeMode.oneDimensional;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('二維條碼'),
                        selected:
                            selectedMode == ScannerCodeMode.twoDimensional,
                        onSelected: (_) {
                          setDialogState(() {
                            selectedMode = ScannerCodeMode.twoDimensional;
                          });
                        },
                      ),
                    ],
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
              child: const Text('確認'),
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
    });
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
          Positioned.fill(
            child: IgnorePointer(
              child: LegacyScanFrameOverlay(
                key: scannerFrameOverlayKey,
                mode: scanFrameModeFor(_scanMode),
              ),
            ),
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
          const Positioned(
            left: 20,
            right: 20,
            bottom: 120,
            child: Column(
              children: <Widget>[
                Text(
                  scannerHintText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 8),
                _ModeBadge(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: Row(
                key: scannerToolRowKey,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _LegacyToolIconButton(
                    buttonKey: scannerFlashButtonKey,
                    icon: _torchOn
                        ? Icons.flashlight_off_outlined
                        : Icons.flashlight_on_outlined,
                    onPressed: _toggleTorch,
                  ),
                  const SizedBox(width: 20),
                  _LegacyToolIconButton(
                    buttonKey: scannerKeypadButtonKey,
                    icon: Icons.dialpad_outlined,
                    onPressed: _openManualInputPad,
                  ),
                  const SizedBox(width: 20),
                  _LegacyToolIconButton(
                    buttonKey: scannerSettingButtonKey,
                    icon: Icons.settings_outlined,
                    onPressed: _openScanModeSettings,
                  ),
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
        final value = firstNonEmptyBarcodeValueForMode(capture, _scanMode);
        if (value.isNotEmpty) {
          onDetectedValue(value);
        }
      },
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_ScannerPageState>();
    final mode = state?._scanMode ?? ScannerCodeMode.all;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text(
          'Mode: ${scannerCodeModeLabel(mode)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LegacyToolIconButton extends StatelessWidget {
  const _LegacyToolIconButton({
    required this.buttonKey,
    required this.icon,
    required this.onPressed,
  });

  final Key buttonKey;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: buttonKey,
      borderRadius: BorderRadius.circular(999),
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          color: _ScannerPageState._legacyToolBackdropColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

class _ManualInputPad extends StatefulWidget {
  const _ManualInputPad();

  @override
  State<_ManualInputPad> createState() => _ManualInputPadState();
}

class _ManualInputPadState extends State<_ManualInputPad> {
  String _value = '';

  void _append(String value) {
    setState(() {
      _value += value;
    });
  }

  void _backspace() {
    if (_value.isEmpty) {
      return;
    }
    setState(() {
      _value = _value.substring(0, _value.length - 1);
    });
  }

  void _clear() {
    setState(() {
      _value = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              '手動輸入',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Text(
                _value.isEmpty ? '請輸入單號' : _value,
                style: TextStyle(
                  fontSize: 18,
                  color: _value.isEmpty
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.9,
              children: <Widget>[
                for (final key in const <String>[
                  '1',
                  '2',
                  '3',
                  '4',
                  '5',
                  '6',
                  '7',
                  '8',
                  '9',
                  '.',
                  '0',
                ])
                  FilledButton(
                    // Keep default system feedback behavior.
                    onPressed: () => _append(key),
                    child: Text(key),
                  ),
                FilledButton.tonal(
                  onPressed: _backspace,
                  child: const Icon(Icons.backspace_outlined),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clear,
                    child: const Text('清除'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _value.trim().isEmpty
                        ? null
                        : () => Navigator.of(context).pop(_value.trim()),
                    child: const Text('送出'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LegacyScanFrameOverlay extends StatelessWidget {
  const LegacyScanFrameOverlay({
    super.key,
    required this.mode,
  });

  final ScanFrameMode mode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        final Rect frameRect = legacyScanFrameRect(size, mode);
        final RRect frameRRect =
            RRect.fromRectAndRadius(frameRect, const Radius.circular(14));

        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(
                painter: _LegacyScanMaskPainter(frameRRect: frameRRect),
              ),
            ),
            Positioned.fromRect(
              rect: frameRect,
              child: Container(
                key: scannerFrameWindowKey,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white, width: 2.2),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

Rect legacyScanFrameRect(Size size, ScanFrameMode mode) {
  final double width = math.min(size.width * 0.78, 360);
  final double height =
      mode == ScanFrameMode.oneDimensional ? math.max(84, width * 0.28) : width;
  final double topBias = size.height * 0.08;
  final double left = (size.width - width) / 2;
  final double top = ((size.height - height) / 2 - topBias)
      .clamp(72.0, size.height - height - 24);

  return Rect.fromLTWH(left, top, width, height);
}

class _LegacyScanMaskPainter extends CustomPainter {
  const _LegacyScanMaskPainter({required this.frameRRect});

  final RRect frameRRect;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    canvas.saveLayer(bounds, Paint());
    canvas.drawRect(
      bounds,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    canvas.drawRRect(
      frameRRect,
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LegacyScanMaskPainter oldDelegate) {
    return oldDelegate.frameRRect != frameRRect;
  }
}
