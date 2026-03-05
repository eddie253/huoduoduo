import 'package:flutter/material.dart';

class HddManualInputSheet extends StatefulWidget {
  const HddManualInputSheet({
    super.key,
    this.titleText = '手動輸入',
    this.placeholderText = '請輸入條碼',
    this.clearText = '清除',
    this.cancelText = '取消',
    this.confirmText = '確定',
  });

  final String titleText;
  final String placeholderText;
  final String clearText;
  final String cancelText;
  final String confirmText;

  @override
  State<HddManualInputSheet> createState() => _HddManualInputSheetState();
}

class _HddManualInputSheetState extends State<HddManualInputSheet> {
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
            Text(
              widget.titleText,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
                _value.isEmpty ? widget.placeholderText : _value,
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
                for (final String key in const <String>[
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
                    child: Text(widget.clearText),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(widget.cancelText),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _value.trim().isEmpty
                        ? null
                        : () => Navigator.of(context).pop(_value.trim()),
                    child: Text(widget.confirmText),
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
