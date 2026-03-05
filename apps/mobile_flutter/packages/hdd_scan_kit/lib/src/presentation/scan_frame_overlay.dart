import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/scan_models.dart';

enum ScanFrameMode {
  oneDimensional,
  twoDimensional,
}

ScanFrameMode scanFrameModeFor(ScanMode mode) {
  if (mode == ScanMode.oneDimensional) {
    return ScanFrameMode.oneDimensional;
  }
  return ScanFrameMode.twoDimensional;
}

Rect scanFrameRect(Size size, ScanFrameMode mode) {
  final double width = math.min(size.width * 0.78, 360);
  final double height =
      mode == ScanFrameMode.oneDimensional ? math.max(84, width * 0.28) : width;
  final double topBias = size.height * 0.08;
  final double left = (size.width - width) / 2;
  final double top = ((size.height - height) / 2 - topBias)
      .clamp(72.0, size.height - height - 24);
  return Rect.fromLTWH(left, top, width, height);
}

class ScanFrameOverlay extends StatelessWidget {
  const ScanFrameOverlay({
    super.key,
    required this.mode,
    this.windowKey,
  });

  final ScanFrameMode mode;
  final Key? windowKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        final Rect frameRect = scanFrameRect(size, mode);
        final RRect frameRRect =
            RRect.fromRectAndRadius(frameRect, const Radius.circular(14));

        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(
                painter: _ScanMaskPainter(frameRRect: frameRRect),
              ),
            ),
            Positioned.fromRect(
              rect: frameRect,
              child: Container(
                key: windowKey,
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

class _ScanMaskPainter extends CustomPainter {
  const _ScanMaskPainter({required this.frameRRect});

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
  bool shouldRepaint(covariant _ScanMaskPainter oldDelegate) {
    return oldDelegate.frameRRect != frameRRect;
  }
}
