enum MapNavigationBlockReason {
  locationServiceDisabled,
  locationPermissionDenied,
  googleMapsUnavailable,
  googleAccountMissing,
  googleAccountUnknown,
}

class MapNavigationPreflightResult {
  const MapNavigationPreflightResult._({
    required this.allowed,
    this.reason,
    this.message,
  });

  const MapNavigationPreflightResult.allow()
      : this._(
          allowed: true,
        );

  const MapNavigationPreflightResult.block({
    required MapNavigationBlockReason reason,
    required String message,
  }) : this._(
          allowed: false,
          reason: reason,
          message: message,
        );

  final bool allowed;
  final MapNavigationBlockReason? reason;
  final String? message;
}

abstract class MapNavigationPreflightPort {
  Future<MapNavigationPreflightResult> ensureReady();
}
