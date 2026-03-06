import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

typedef SignatureFileWriter = Future<void> Function(File file, List<int> bytes);

class SignatureViewModel extends ChangeNotifier {
  bool _isSaving = false;

  bool get isSaving => _isSaving;

  Future<({String filePath, String fileName, String mimeType})?> save({
    required Future<List<int>?> Function() exportBytes,
    DateTime Function()? now,
    SignatureFileWriter? writeBytes,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      final bytes = await exportBytes();
      if (bytes == null || bytes.isEmpty) {
        throw const FormatException('Signature bytes are empty');
      }
      final timestamp = (now ?? DateTime.now).call().millisecondsSinceEpoch;
      final fileName = 'signature_$timestamp.png';
      final filePath = p.join(Directory.systemTemp.path, fileName);
      final output = File(filePath);
      if (writeBytes != null) {
        await writeBytes(output, bytes);
      } else {
        await output.writeAsBytes(bytes, flush: true);
      }
      return (filePath: filePath, fileName: fileName, mimeType: 'image/png');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
