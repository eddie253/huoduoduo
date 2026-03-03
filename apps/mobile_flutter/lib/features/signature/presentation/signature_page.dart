import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:signature/signature.dart';

typedef SignatureFileWriter = Future<void> Function(File file, List<int> bytes);

class SignaturePage extends StatefulWidget {
  const SignaturePage({
    super.key,
    this.controller,
    this.now,
    this.writeBytes,
  });

  final SignatureController? controller;
  final DateTime Function()? now;
  final SignatureFileWriter? writeBytes;

  @override
  State<SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage> {
  late final SignatureController _controller;
  late final bool _ownsController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        SignatureController(
          penStrokeWidth: 2,
          penColor: Colors.black,
          exportBackgroundColor: Colors.white,
        );
    _ownsController = widget.controller == null;
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveSignature() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign first.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final bytes = await _controller.toPngBytes();
      if (bytes == null || bytes.isEmpty) {
        throw const FormatException('Signature bytes are empty');
      }

      final timestamp =
          (widget.now ?? DateTime.now).call().millisecondsSinceEpoch;
      final fileName = 'signature_$timestamp.png';
      final filePath = p.join(Directory.systemTemp.path, fileName);
      final output = File(filePath);
      final writer = widget.writeBytes;
      if (writer != null) {
        await writer(output, bytes);
      } else {
        await output.writeAsBytes(bytes, flush: true);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(<String, dynamic>{
        'filePath': filePath,
        'fileName': fileName,
        'mimeType': 'image/png',
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save signature: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Signature'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border:
                    Border.all(color: colors.primary.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Signature(
                controller: _controller,
                backgroundColor: colors.surface,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () {
                            _controller.clear();
                          },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveSignature,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
