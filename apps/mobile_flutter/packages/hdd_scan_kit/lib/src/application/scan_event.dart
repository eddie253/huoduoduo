import 'package:meta/meta.dart';

import '../domain/scan_models.dart';

@immutable
sealed class ScanEvent {
  const ScanEvent(this.timestamp);

  final DateTime timestamp;
}

class ScanStartedEvent extends ScanEvent {
  const ScanStartedEvent({
    required this.request,
    required DateTime timestamp,
  }) : super(timestamp);

  final ScanRequest request;
}

class ScanSuccessEvent extends ScanEvent {
  const ScanSuccessEvent({
    required this.result,
    required DateTime timestamp,
  }) : super(timestamp);

  final ScanResult result;
}

class ScanFailureEvent extends ScanEvent {
  const ScanFailureEvent({
    required this.failure,
    required DateTime timestamp,
  }) : super(timestamp);

  final ScanFailure failure;
}

class ScanStoppedEvent extends ScanEvent {
  const ScanStoppedEvent({required DateTime timestamp}) : super(timestamp);
}
