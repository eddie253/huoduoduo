import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mobile_flutter/core/navigation/map_navigation_preflight_port.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

export 'package:mobile_flutter/core/navigation/map_navigation_preflight_port.dart';

abstract class LocationAccessPort {
  Future<ServiceStatus> serviceStatus();

  Future<PermissionStatus> permissionStatus();

  Future<PermissionStatus> requestPermission();
}

class PermissionHandlerLocationAccessPort implements LocationAccessPort {
  const PermissionHandlerLocationAccessPort();

  @override
  Future<ServiceStatus> serviceStatus() {
    return Permission.locationWhenInUse.serviceStatus;
  }

  @override
  Future<PermissionStatus> permissionStatus() {
    return Permission.locationWhenInUse.status;
  }

  @override
  Future<PermissionStatus> requestPermission() {
    return Permission.locationWhenInUse.request();
  }
}

abstract class GoogleMapsAvailabilityPort {
  Future<bool> isAvailable();
}

class UrlLauncherGoogleMapsAvailabilityPort
    implements GoogleMapsAvailabilityPort {
  const UrlLauncherGoogleMapsAvailabilityPort();

  static final Uri _navigationProbe =
      Uri.parse('google.navigation:q=25.0330,121.5654');
  static final Uri _deepLinkProbe =
      Uri.parse('comgooglemaps://?q=25.0330,121.5654');

  @override
  Future<bool> isAvailable() async {
    try {
      if (await canLaunchUrl(_navigationProbe)) {
        return true;
      }
      if (await canLaunchUrl(_deepLinkProbe)) {
        return true;
      }
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
    return false;
  }
}

enum GoogleAccountState {
  configured,
  missing,
  unknown,
}

abstract class GoogleAccountPort {
  Future<GoogleAccountState> state();
}

class MethodChannelGoogleAccountPort implements GoogleAccountPort {
  const MethodChannelGoogleAccountPort();

  static const MethodChannel _channel =
      MethodChannel('com.example.mobile_flutter/google_account');

  @override
  Future<GoogleAccountState> state() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return GoogleAccountState.unknown;
    }
    try {
      final hasGoogleAccount =
          await _channel.invokeMethod<bool>('hasGoogleAccount');
      if (hasGoogleAccount == true) {
        return GoogleAccountState.configured;
      }
      if (hasGoogleAccount == false) {
        return GoogleAccountState.missing;
      }
      return GoogleAccountState.unknown;
    } on PlatformException {
      return GoogleAccountState.unknown;
    } on MissingPluginException {
      return GoogleAccountState.unknown;
    }
  }
}

class DefaultMapNavigationPreflightService
    implements MapNavigationPreflightPort {
  const DefaultMapNavigationPreflightService({
    LocationAccessPort locationAccessPort =
        const PermissionHandlerLocationAccessPort(),
    GoogleMapsAvailabilityPort mapsAvailabilityPort =
        const UrlLauncherGoogleMapsAvailabilityPort(),
    GoogleAccountPort googleAccountPort =
        const MethodChannelGoogleAccountPort(),
    this.requireGoogleAccountOnAndroid = true,
    this.blockWhenGoogleAccountUnverified = false,
    this.blockWhenGoogleMapsUnavailable = false,
  })  : _locationAccessPort = locationAccessPort,
        _mapsAvailabilityPort = mapsAvailabilityPort,
        _googleAccountPort = googleAccountPort;

  final LocationAccessPort _locationAccessPort;
  final GoogleMapsAvailabilityPort _mapsAvailabilityPort;
  final GoogleAccountPort _googleAccountPort;
  final bool requireGoogleAccountOnAndroid;
  final bool blockWhenGoogleAccountUnverified;
  final bool blockWhenGoogleMapsUnavailable;

  @override
  Future<MapNavigationPreflightResult> ensureReady() async {
    final ServiceStatus serviceStatus;
    try {
      serviceStatus = await _locationAccessPort.serviceStatus();
    } on PlatformException {
      return const MapNavigationPreflightResult.block(
        reason: MapNavigationBlockReason.locationServiceDisabled,
        message: 'Unable to read location service state.',
      );
    } on MissingPluginException {
      return const MapNavigationPreflightResult.block(
        reason: MapNavigationBlockReason.locationServiceDisabled,
        message: 'Unable to read location service state.',
      );
    }
    if (!serviceStatus.isEnabled) {
      return const MapNavigationPreflightResult.block(
        reason: MapNavigationBlockReason.locationServiceDisabled,
        message:
            'Location is turned off. Please enable location service and try again.',
      );
    }

    PermissionStatus permissionStatus;
    try {
      permissionStatus = await _locationAccessPort.permissionStatus();
    } on PlatformException {
      return const MapNavigationPreflightResult.block(
        reason: MapNavigationBlockReason.locationPermissionDenied,
        message: 'Unable to read location permission.',
      );
    } on MissingPluginException {
      return const MapNavigationPreflightResult.block(
        reason: MapNavigationBlockReason.locationPermissionDenied,
        message: 'Unable to read location permission.',
      );
    }
    if (!(permissionStatus.isGranted || permissionStatus.isLimited)) {
      if (permissionStatus.isDenied || permissionStatus.isRestricted) {
        try {
          permissionStatus = await _locationAccessPort.requestPermission();
        } on PlatformException {
          return const MapNavigationPreflightResult.block(
            reason: MapNavigationBlockReason.locationPermissionDenied,
            message: 'Location permission request failed.',
          );
        } on MissingPluginException {
          return const MapNavigationPreflightResult.block(
            reason: MapNavigationBlockReason.locationPermissionDenied,
            message: 'Location permission request failed.',
          );
        }
      }
    }
    if (!(permissionStatus.isGranted || permissionStatus.isLimited)) {
      return const MapNavigationPreflightResult.block(
        reason: MapNavigationBlockReason.locationPermissionDenied,
        message:
            'Location permission is required for navigation. Please allow location access in system settings.',
      );
    }

    final bool mapsAvailable = await _mapsAvailabilityPort.isAvailable();
    if (!mapsAvailable) {
      if (!blockWhenGoogleMapsUnavailable) {
        return const MapNavigationPreflightResult.allow();
      }
      return const MapNavigationPreflightResult.block(
        reason: MapNavigationBlockReason.googleMapsUnavailable,
        message: 'Google Maps app is unavailable on this device.',
      );
    }

    final bool shouldCheckGoogleAccount = !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        requireGoogleAccountOnAndroid;
    if (!shouldCheckGoogleAccount) {
      return const MapNavigationPreflightResult.allow();
    }

    final GoogleAccountState accountState = await _googleAccountPort.state();
    if (accountState == GoogleAccountState.missing) {
      if (!blockWhenGoogleAccountUnverified) {
        return const MapNavigationPreflightResult.allow();
      }
      return const MapNavigationPreflightResult.block(
        reason: MapNavigationBlockReason.googleAccountMissing,
        message:
            'Google account is not signed in on this device. Sign in to Google first.',
      );
    }
    if (accountState == GoogleAccountState.unknown) {
      if (!blockWhenGoogleAccountUnverified) {
        return const MapNavigationPreflightResult.allow();
      }
      return const MapNavigationPreflightResult.block(
        reason: MapNavigationBlockReason.googleAccountUnknown,
        message:
            'Unable to verify Google account state. Sign in to Google first.',
      );
    }

    return const MapNavigationPreflightResult.allow();
  }
}
