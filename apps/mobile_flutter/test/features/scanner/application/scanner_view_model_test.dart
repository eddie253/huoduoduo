import 'package:flutter_test/flutter_test.dart';
import 'package:scan_kit_core/scan_kit_core.dart' show ScanSymbology;

import 'package:mobile_flutter/features/scanner/application/scanner_view_model.dart';

void main() {
  group('ScannerViewModel.defaultScanMode', () {
    test('returns twoDimensional for qr scan type', () {
      expect(
        ScannerViewModel.defaultScanMode('qr'),
        ScannerCodeMode.twoDimensional,
      );
    });

    test('returns oneDimensional for barcode scan type', () {
      expect(
        ScannerViewModel.defaultScanMode('barcode'),
        ScannerCodeMode.oneDimensional,
      );
    });

    test('returns oneDimensional for 1d scan type', () {
      expect(
        ScannerViewModel.defaultScanMode('1d'),
        ScannerCodeMode.oneDimensional,
      );
    });

    test('returns all for default/unknown scan type', () {
      expect(ScannerViewModel.defaultScanMode('default'), ScannerCodeMode.all);
      expect(ScannerViewModel.defaultScanMode(''), ScannerCodeMode.all);
      expect(ScannerViewModel.defaultScanMode('shipment'), ScannerCodeMode.all);
    });
  });

  group('ScannerViewModel.allowedSymbologiesFor', () {
    test('returns 2D symbologies for twoDimensional mode on non-default type',
        () {
      final syms = ScannerViewModel.allowedSymbologiesFor(
          'qr', ScannerCodeMode.twoDimensional);
      expect(syms, contains(ScanSymbology.qrCode));
      expect(syms, contains(ScanSymbology.pdf417));
    });

    test('returns 1D symbologies for oneDimensional mode on non-default type',
        () {
      final syms = ScannerViewModel.allowedSymbologiesFor(
          'barcode', ScannerCodeMode.oneDimensional);
      expect(syms, contains(ScanSymbology.code128));
      expect(syms, contains(ScanSymbology.ean13));
    });
  });

  group('ScannerViewModel.buildRequest', () {
    test('returns ScanRequest with correct scanType', () {
      final vm = ScannerViewModel(scanType: 'qr');
      final req = vm.buildRequest();
      expect(req.scanType, 'qr');
      vm.dispose();
    });

    test('initial scanMode for qr is twoDimensional', () {
      final vm = ScannerViewModel(scanType: 'qr');
      expect(vm.scanMode, ScannerCodeMode.twoDimensional);
      vm.dispose();
    });

    test('initial frameSize is medium', () {
      final vm = ScannerViewModel(scanType: 'qr');
      expect(vm.frameSize, ScannerFrameSize.medium);
      vm.dispose();
    });
  });

  group('ScannerViewModel.tryComplete', () {
    late ScannerViewModel vm;

    setUp(() => vm = ScannerViewModel(scanType: 'shipment'));
    tearDown(() => vm.dispose());

    test('returns trimmed value on first call', () {
      expect(vm.tryComplete('  CODE-123  '), 'CODE-123');
    });

    test('returns null for empty/whitespace value', () {
      expect(vm.tryComplete(''), isNull);
      expect(vm.tryComplete('   '), isNull);
    });

    test('returns null on duplicate call after completion', () {
      vm.tryComplete('CODE-123');
      expect(vm.tryComplete('CODE-456'), isNull);
    });

    test('isCompleted is true after successful completion', () {
      expect(vm.isCompleted, isFalse);
      vm.tryComplete('CODE-123');
      expect(vm.isCompleted, isTrue);
    });
  });

  group('ScannerViewModel.applySettings', () {
    test('updates scanMode and frameSize and notifies', () {
      final vm = ScannerViewModel(scanType: 'default');
      int notifyCount = 0;
      vm.addListener(() => notifyCount++);

      vm.applySettings(ScannerCodeMode.oneDimensional, ScannerFrameSize.large);

      expect(vm.scanMode, ScannerCodeMode.oneDimensional);
      expect(vm.frameSize, ScannerFrameSize.large);
      expect(notifyCount, 1);
      vm.dispose();
    });

    test('resets isCompleted flag when settings change', () {
      final vm = ScannerViewModel(scanType: 'default');
      vm.tryComplete('CODE-123');
      expect(vm.isCompleted, isTrue);

      vm.applySettings(ScannerCodeMode.all, ScannerFrameSize.medium);
      expect(vm.isCompleted, isFalse);
      vm.dispose();
    });
  });

  group('ScannerViewModel.setTorchOn', () {
    test('updates torchOn and notifies', () {
      final vm = ScannerViewModel(scanType: 'default');
      int notifyCount = 0;
      vm.addListener(() => notifyCount++);

      expect(vm.torchOn, isFalse);
      vm.setTorchOn(true);
      expect(vm.torchOn, isTrue);
      expect(notifyCount, 1);
      vm.dispose();
    });
  });
}
