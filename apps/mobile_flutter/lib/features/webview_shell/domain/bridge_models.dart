enum BridgeErrorCode {
  invalidPayload('BRIDGE_INVALID_PAYLOAD'),
  unsupportedMethod('BRIDGE_UNSUPPORTED_METHOD'),
  permissionDenied('BRIDGE_PERMISSION_DENIED'),
  runtimeError('BRIDGE_RUNTIME_ERROR');

  const BridgeErrorCode(this.code);
  final String code;
}

class BridgeMessage {
  final String id;
  final String version;
  final String method;
  final Map<String, dynamic> params;
  final int timestamp;

  const BridgeMessage({
    required this.id,
    required this.version,
    required this.method,
    required this.params,
    required this.timestamp
  });

  factory BridgeMessage.fromDynamic(dynamic value) {
    if (value is! Map) {
      throw const FormatException('Payload must be a map');
    }
    final map = value.cast<Object?, Object?>();
    final paramsDynamic = map['params'];
    final params = paramsDynamic is Map ? paramsDynamic.cast<String, dynamic>() : <String, dynamic>{};
    return BridgeMessage(
      id: (map['id'] ?? '').toString(),
      version: (map['version'] ?? '1.0').toString(),
      method: (map['method'] ?? '').toString(),
      params: params,
      timestamp: (map['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch
    );
  }
}
