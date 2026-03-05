import 'package:flutter_zxing/flutter_zxing.dart';

import '../../domain/scan_models.dart';

class SymbologyMapper {
  const SymbologyMapper();

  ScanSymbology fromZxingFormat(int? format) {
    switch (format) {
      case Format.code39:
        return ScanSymbology.code39;
      case Format.code128:
        return ScanSymbology.code128;
      case Format.qrCode:
        return ScanSymbology.qrCode;
      case Format.ean13:
        return ScanSymbology.ean13;
      case Format.ean8:
        return ScanSymbology.ean8;
      case Format.upca:
        return ScanSymbology.upca;
      case Format.upce:
        return ScanSymbology.upce;
      case Format.pdf417:
        return ScanSymbology.pdf417;
      case Format.dataMatrix:
        return ScanSymbology.dataMatrix;
      case Format.aztec:
        return ScanSymbology.aztec;
      default:
        return ScanSymbology.unknown;
    }
  }

  int toZxingFormatMask(Set<ScanSymbology> symbologies, ScanMode mode) {
    if (symbologies.isEmpty && mode == ScanMode.all) {
      return Format.any;
    }

    int mask = Format.none;
    final Set<ScanSymbology> effective =
        symbologies.isEmpty ? _modeDefaults(mode) : symbologies;

    for (final ScanSymbology symbology in effective) {
      mask |= _symbologyToFormat(symbology);
    }
    return mask == Format.none ? Format.any : mask;
  }

  int _symbologyToFormat(ScanSymbology symbology) {
    switch (symbology) {
      case ScanSymbology.code39:
        return Format.code39;
      case ScanSymbology.code128:
        return Format.code128;
      case ScanSymbology.qrCode:
        return Format.qrCode;
      case ScanSymbology.ean13:
        return Format.ean13;
      case ScanSymbology.ean8:
        return Format.ean8;
      case ScanSymbology.upca:
        return Format.upca;
      case ScanSymbology.upce:
        return Format.upce;
      case ScanSymbology.pdf417:
        return Format.pdf417;
      case ScanSymbology.dataMatrix:
        return Format.dataMatrix;
      case ScanSymbology.aztec:
        return Format.aztec;
      case ScanSymbology.unknown:
        return Format.none;
    }
  }

  Set<ScanSymbology> _modeDefaults(ScanMode mode) {
    switch (mode) {
      case ScanMode.oneDimensional:
        return <ScanSymbology>{
          ScanSymbology.code39,
          ScanSymbology.code128,
          ScanSymbology.ean13,
          ScanSymbology.ean8,
          ScanSymbology.upca,
          ScanSymbology.upce,
        };
      case ScanMode.twoDimensional:
        return <ScanSymbology>{
          ScanSymbology.qrCode,
          ScanSymbology.pdf417,
          ScanSymbology.dataMatrix,
          ScanSymbology.aztec,
        };
      case ScanMode.all:
        return <ScanSymbology>{};
    }
  }
}
