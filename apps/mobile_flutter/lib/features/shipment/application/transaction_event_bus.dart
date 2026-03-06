import 'dart:async';

class TransactionEvent {
  const TransactionEvent({required this.trackingNo});
  final String trackingNo;
}

class TransactionEventBus {
  TransactionEventBus._();
  static final TransactionEventBus instance = TransactionEventBus._();

  final StreamController<TransactionEvent> _controller =
      StreamController<TransactionEvent>.broadcast();

  Stream<TransactionEvent> get stream => _controller.stream;

  void emit(TransactionEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }
}
