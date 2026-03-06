import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/shipment_models.dart';

class ShipmentConfirmationNotifier
    extends Notifier<Map<String, ShipmentDetail>> {
  @override
  Map<String, ShipmentDetail> build() => const <String, ShipmentDetail>{};

  void confirm(String trackingNo, ShipmentDetail detail) {
    state = <String, ShipmentDetail>{...state, trackingNo: detail};
  }

  void clear(String trackingNo) {
    final updated = Map<String, ShipmentDetail>.from(state);
    updated.remove(trackingNo);
    state = Map<String, ShipmentDetail>.unmodifiable(updated);
  }
}

final shipmentConfirmationProvider =
    NotifierProvider<ShipmentConfirmationNotifier, Map<String, ShipmentDetail>>(
  ShipmentConfirmationNotifier.new,
);
