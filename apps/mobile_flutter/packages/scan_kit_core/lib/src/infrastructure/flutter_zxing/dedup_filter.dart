class DedupFilter {
  DedupFilter({required this.windowMs});

  final int windowMs;

  bool shouldEmit(String value, DateTime now) {
    final int nowMs = now.millisecondsSinceEpoch;
    final int? previous = _valueTimestampMs[value];
    if (previous != null && nowMs - previous < windowMs) {
      return false;
    }
    _valueTimestampMs[value] = nowMs;
    return true;
  }

  final Map<String, int> _valueTimestampMs = <String, int>{};
}
