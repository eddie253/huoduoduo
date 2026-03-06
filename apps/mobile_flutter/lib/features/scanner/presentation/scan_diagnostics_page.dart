import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/scan_audit_repository.dart';
import '../domain/scan_audit_entry.dart';

class ScanDiagnosticsPage extends ConsumerStatefulWidget {
  const ScanDiagnosticsPage({super.key});

  @override
  ConsumerState<ScanDiagnosticsPage> createState() =>
      _ScanDiagnosticsPageState();
}

class _ScanDiagnosticsPageState extends ConsumerState<ScanDiagnosticsPage> {
  List<ScanAuditEntry> _entries = <ScanAuditEntry>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = await ref.read(scanAuditRepositoryProvider.future);
    final entries = await repo.queryRecent(limit: 200);
    if (mounted) {
      setState(() {
        _entries = entries;
        _loading = false;
      });
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('清除記錄'),
        content: const Text('確定要清除所有掃描記錄？'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('清除')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final repo = await ref.read(scanAuditRepositoryProvider.future);
    await repo.clearAll();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final int shortCount =
        _entries.where((e) => e.symbology == 'code128' && e.length < 10).length;
    final double avgMs = _entries.isEmpty
        ? 0
        : _entries
                .where((e) => e.durationMs != null)
                .fold<int>(0, (s, e) => s + e.durationMs!) /
            (_entries.where((e) => e.durationMs != null).length.clamp(1, 9999));

    return Scaffold(
      appBar: AppBar(
        title: const Text('條碼掃描記錄'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新整理',
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清除',
            onPressed: _clearAll,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(child: Text('尚無掃描記錄'))
              : Column(
                  children: <Widget>[
                    _SummaryBanner(
                      total: _entries.length,
                      shortCount: shortCount,
                      avgDecodeMs: avgMs,
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: _entries.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, i) =>
                            _AuditEntryTile(entry: _entries[i]),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({
    required this.total,
    required this.shortCount,
    required this.avgDecodeMs,
  });

  final int total;
  final int shortCount;
  final double avgDecodeMs;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: <Widget>[
            _statChip('總計', '$total', colors.primary),
            const SizedBox(width: 12),
            _statChip(
              '截短 (<10)',
              '$shortCount',
              shortCount > 0 ? colors.error : colors.secondary,
            ),
            const SizedBox(width: 12),
            _statChip(
              '均解碼',
              '${avgDecodeMs.toStringAsFixed(0)} ms',
              colors.tertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: <Widget>[
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 16, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _AuditEntryTile extends StatelessWidget {
  const _AuditEntryTile({required this.entry});

  final ScanAuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isShort = entry.symbology == 'code128' && entry.length < 10;
    final bool isFast =
        entry.durationMs != null && entry.durationMs! < 2;

    final timeStr =
        '${entry.scannedAt.hour.toString().padLeft(2, '0')}:'
        '${entry.scannedAt.minute.toString().padLeft(2, '0')}:'
        '${entry.scannedAt.second.toString().padLeft(2, '0')}';

    return ListTile(
      dense: true,
      title: Text(
        entry.rawValue,
        style: TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
          color: isShort ? colors.error : null,
        ),
      ),
      subtitle: Row(
        children: <Widget>[
          _badge(entry.symbology, colors.primaryContainer),
          const SizedBox(width: 4),
          _badge('${entry.length} chars',
              isShort ? colors.errorContainer : colors.secondaryContainer),
          if (entry.durationMs != null) ...<Widget>[
            const SizedBox(width: 4),
            _badge(
              '${entry.durationMs} ms',
              isFast ? Colors.orange.shade100 : colors.tertiaryContainer,
            ),
          ],
          const SizedBox(width: 4),
          _badge(entry.source, colors.surfaceContainerHighest),
        ],
      ),
      trailing: Text(timeStr,
          style: const TextStyle(fontSize: 11, color: Colors.grey)),
      leading: Icon(
        isShort ? Icons.warning_amber_rounded : Icons.check_circle_outline,
        color: isShort ? colors.error : colors.secondary,
        size: 20,
      ),
    );
  }

  Widget _badge(String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10)),
    );
  }
}
