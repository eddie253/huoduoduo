class BridgeActionResult {
  const BridgeActionResult({
    required this.ok,
    required this.action,
    this.data = const <String, dynamic>{},
  });

  final bool ok;
  final String action;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'ok': ok,
      'action': action,
      if (data.isNotEmpty) 'data': data,
    };
  }
}

enum AppEventKind {
  map('map'),
  dial('dial'),
  close('close'),
  contract('contract'),
  unknown('unknown');

  const AppEventKind(this.value);

  final String value;

  static AppEventKind fromRaw(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) {
      return AppEventKind.unknown;
    }

    if (_mapAliases.contains(normalized)) {
      return AppEventKind.map;
    }
    if (_dialAliases.contains(normalized)) {
      return AppEventKind.dial;
    }
    if (_closeAliases.contains(normalized)) {
      return AppEventKind.close;
    }
    if (_contractAliases.contains(normalized)) {
      return AppEventKind.contract;
    }

    return AppEventKind.unknown;
  }

  static const Set<String> _mapAliases = <String>{
    'map',
    'gm\u5c0e\u822a',
    'gm\u5bfc\u822a',
    'gm\u5916\u90e8',
    '\u5c0e\u822a',
    '\u5bfc\u822a',
    '\u5730\u5716\u5b9a\u4f4d',
    '\u5730\u56fe\u5b9a\u4f4d',
    '\u5b9a\u4f4d\u55ae\u9ede\u898f\u5283',
    '\u5b9a\u4f4d\u5355\u70b9\u89c4\u5212',
    'navigation',
    'route',
  };

  static const Set<String> _dialAliases = <String>{
    'dial',
    'phone',
    'tel',
    '\u64a5\u865f',
    '\u62e8\u53f7',
    '\u624b\u6a5f',
    '\u624b\u673a',
    '\u96fb\u8a71',
    '\u7535\u8bdd',
  };

  static const Set<String> _closeAliases = <String>{
    'close',
    'back',
    'pre_page',
    '\u95dc\u9589',
    '\u5173\u95ed',
    '\u4e0a\u4e00\u9801',
    '\u4e0a\u4e00\u9875',
  };

  static const Set<String> _contractAliases = <String>{
    'contract',
    'agreement',
    '\u5408\u7d04',
    '\u5408\u7ea6',
  };
}

class ScannerResult {
  const ScannerResult({
    required this.value,
    required this.scanType,
  });

  final String value;
  final String scanType;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'value': value,
      'scanType': scanType,
    };
  }
}

class SignatureResult {
  const SignatureResult({
    required this.filePath,
    required this.fileName,
    required this.mimeType,
  });

  final String filePath;
  final String fileName;
  final String mimeType;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'filePath': filePath,
      'fileName': fileName,
      'mimeType': mimeType,
    };
  }
}
