import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scan_kit_core/scan_kit_core.dart';

import '../application/scanner_view_model.dart';
import '../data/scan_audit_repository.dart';
import '../domain/scan_audit_entry.dart';

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

class _ScannerSettingResult {
  const _ScannerSettingResult({
    required this.mode,
    required this.frameSize,
  });

  final ScannerCodeMode mode;
  final ScannerFrameSize frameSize;
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

Rect legacyScanFrameRect(
  Size size,
  ScanFrameMode mode, {
  ScannerFrameSize frameSize = ScannerFrameSize.medium,
}) {
  return scanFrameRect(size, mode, frameSize: _toFrameSize(frameSize));
}

class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({
    super.key,
    this.scanType = 'default',
    this.scannerViewBuilder,
  });

  final String scanType;
  final ScannerViewBuilder? scannerViewBuilder;

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  static const Color _legacyHeaderColor = Color(0xFFFC5000);

  final ScanSessionController _controller = ScanSessionController();
  StreamSubscription<ScanEvent>? _eventSubscription;
  late final ScannerViewModel _viewModel;
  late ScanRequest _request;

  @override
  void initState() {
    super.initState();
    _viewModel = ScannerViewModel(scanType: widget.scanType);
    _viewModel.addListener(() {
      if (mounted) setState(() {});
    });
    _request = _viewModel.buildRequest();
    _eventSubscription = _controller.events.listen(_onScanEvent);
    _controller.start(_request);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _eventSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onScanEvent(ScanEvent event) {
    if (event is! ScanSuccessEvent) {
      return;
    }
    final String? result = _viewModel.tryComplete(event.result.value);
    if (result == null) {
      return;
    }
    _logAudit(event.result);
    _controller.stop();
    Navigator.of(context).pop(result);
  }

  void _logAudit(ScanResult result) {
    ref.read(scanAuditRepositoryProvider.future).then((repo) {
      repo.insert(ScanAuditEntry.fromResult(result));
    }).ignore();
  }

  Future<void> _toggleTorch() async {
    final bool torchOn = await _controller.toggleTorch();
    if (!mounted) {
      return;
    }
    _viewModel.setTorchOn(torchOn);
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
    ScannerCodeMode selectedMode = _viewModel.scanMode;
    ScannerFrameSize selectedFrameSize = _viewModel.frameSize;
    final _ScannerSettingResult? result =
        await showDialog<_ScannerSettingResult>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('掃描設定'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  ChoiceChip(
                    label: const Text('1D + 2D'),
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
                    label: const Text('二維碼'),
                    selected: selectedMode == ScannerCodeMode.twoDimensional,
                    onSelected: (_) {
                      setDialogState(() {
                        selectedMode = ScannerCodeMode.twoDimensional;
                      });
                    },
                  ),
                  const SizedBox(width: 9999, height: 2),
                  ChoiceChip(
                    label: const Text('框小'),
                    selected: selectedFrameSize == ScannerFrameSize.compact,
                    onSelected: (_) {
                      setDialogState(() {
                        selectedFrameSize = ScannerFrameSize.compact;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('框中'),
                    selected: selectedFrameSize == ScannerFrameSize.medium,
                    onSelected: (_) {
                      setDialogState(() {
                        selectedFrameSize = ScannerFrameSize.medium;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('框大'),
                    selected: selectedFrameSize == ScannerFrameSize.large,
                    onSelected: (_) {
                      setDialogState(() {
                        selectedFrameSize = ScannerFrameSize.large;
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
              onPressed: () => Navigator.of(context).pop(
                _ScannerSettingResult(
                  mode: selectedMode,
                  frameSize: selectedFrameSize,
                ),
              ),
              child: const Text('確認'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }
    _viewModel.applySettings(result.mode, result.frameSize);
    setState(() {
      _request = _viewModel.buildRequest();
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
            frameSize: _toFrameSize(_viewModel.frameSize),
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
                      'Mode: ${scannerCodeModeLabel(_viewModel.scanMode)} / Frame: ${_viewModel.frameSize.name}',
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
                torchOn: _viewModel.torchOn,
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

ScanFrameSize _toFrameSize(ScannerFrameSize size) {
  switch (size) {
    case ScannerFrameSize.compact:
      return ScanFrameSize.compact;
    case ScannerFrameSize.medium:
      return ScanFrameSize.medium;
    case ScannerFrameSize.large:
      return ScanFrameSize.large;
  }
}
