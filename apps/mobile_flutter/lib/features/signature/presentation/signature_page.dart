import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../application/signature_view_model.dart';

export '../application/signature_view_model.dart' show SignatureFileWriter;

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
  late final SignatureViewModel _viewModel;

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
    _viewModel = SignatureViewModel();
    _viewModel.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
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

    try {
      final result = await _viewModel.save(
        exportBytes: () async => await _controller.toPngBytes(),
        now: widget.now,
        writeBytes: widget.writeBytes,
      );
      if (!mounted || result == null) {
        return;
      }
      Navigator.of(context).pop(<String, dynamic>{
        'filePath': result.filePath,
        'fileName': result.fileName,
        'mimeType': result.mimeType,
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save signature: $error')),
      );
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
                    onPressed: _viewModel.isSaving
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
                    onPressed: _viewModel.isSaving ? null : _saveSignature,
                    icon: _viewModel.isSaving
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
