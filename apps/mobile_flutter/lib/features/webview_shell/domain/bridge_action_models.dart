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
    for (final item in AppEventKind.values) {
      if (item.value == normalized) {
        return item;
      }
    }
    return AppEventKind.unknown;
  }
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
