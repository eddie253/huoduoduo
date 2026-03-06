class ShipmentDetail {
  final String trackingNo;
  final String status;

  const ShipmentDetail({required this.trackingNo, required this.status});

  factory ShipmentDetail.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'trackingNo': final String trackingNo, 'status': final String status} =>
        ShipmentDetail(trackingNo: trackingNo, status: status),
      _ => throw const FormatException(
          'ShipmentDetail: missing required field'),
    };
  }
}
