import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/features/webview_shell/application/map_navigation_preflight_service.dart';
import 'package:permission_handler/permission_handler.dart';

const MethodChannel _permissionChannel =
    MethodChannel('flutter.baseflow.com/permissions/methods');
const MethodChannel _googleAccountChannel =
    MethodChannel('com.example.mobile_flutter/google_account');
const MethodChannel _urlLauncherChannel =
    MethodChannel('plugins.flutter.io/url_launcher');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_permissionChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_googleAccountChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_urlLauncherChannel, null);
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_permissionChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_googleAccountChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_urlLauncherChannel, null);
  });

  test('blocks when location service is disabled', () async {
    final result = await _createService(
      locationAccessPort: _FakeLocationAccessPort(
        serviceStatusValue: ServiceStatus.disabled,
        permissionStatusValue: PermissionStatus.granted,
      ),
    ).ensureReady();

    expect(result.allowed, isFalse);
    expect(result.reason, MapNavigationBlockReason.locationServiceDisabled);
  });

  test('blocks when location service status throws platform exception',
      () async {
    final result = await _createService(
      locationAccessPort: _FakeLocationAccessPort(
        serviceStatusValue: ServiceStatus.enabled,
        permissionStatusValue: PermissionStatus.granted,
        serviceStatusError: PlatformException(code: 'service_status_failed'),
      ),
    ).ensureReady();

    expect(result.allowed, isFalse);
    expect(result.reason, MapNavigationBlockReason.locationServiceDisabled);
    expect(result.message, 'Unable to read location service state.');
  });

  test('blocks when location service status throws missing plugin', () async {
    final result = await _createService(
      locationAccessPort: _FakeLocationAccessPort(
        serviceStatusValue: ServiceStatus.enabled,
        permissionStatusValue: PermissionStatus.granted,
        serviceStatusError: MissingPluginException(),
      ),
    ).ensureReady();

    expect(result.allowed, isFalse);
    expect(result.reason, MapNavigationBlockReason.locationServiceDisabled);
    expect(result.message, 'Unable to read location service state.');
  });

  test('blocks when location permission status throws missing plugin',
      () async {
    final result = await _createService(
      locationAccessPort: _FakeLocationAccessPort(
        serviceStatusValue: ServiceStatus.enabled,
        permissionStatusValue: PermissionStatus.granted,
        permissionStatusError: MissingPluginException(),
      ),
    ).ensureReady();

    expect(result.allowed, isFalse);
    expect(result.reason, MapNavigationBlockReason.locationPermissionDenied);
    expect(result.message, 'Unable to read location permission.');
  });

  test('requests location permission and allows when granted', () async {
    final locationPort = _FakeLocationAccessPort(
      serviceStatusValue: ServiceStatus.enabled,
      permissionStatusValue: PermissionStatus.denied,
      requestResult: PermissionStatus.granted,
    );
    final result = await _createService(
      locationAccessPort: locationPort,
    ).ensureReady();

    expect(result.allowed, isTrue);
    expect(locationPort.requestCalled, isTrue);
  });

  test('blocks when request permission throws platform exception', () async {
    final locationPort = _FakeLocationAccessPort(
      serviceStatusValue: ServiceStatus.enabled,
      permissionStatusValue: PermissionStatus.denied,
      requestPermissionError: PlatformException(code: 'request_failed'),
    );
    final result = await _createService(
      locationAccessPort: locationPort,
    ).ensureReady();

    expect(result.allowed, isFalse);
    expect(locationPort.requestCalled, isTrue);
    expect(result.reason, MapNavigationBlockReason.locationPermissionDenied);
    expect(result.message, 'Location permission request failed.');
  });

  test('blocks when request permission throws missing plugin', () async {
    final locationPort = _FakeLocationAccessPort(
      serviceStatusValue: ServiceStatus.enabled,
      permissionStatusValue: PermissionStatus.denied,
      requestPermissionError: MissingPluginException(),
    );
    final result = await _createService(
      locationAccessPort: locationPort,
    ).ensureReady();

    expect(result.allowed, isFalse);
    expect(locationPort.requestCalled, isTrue);
    expect(result.reason, MapNavigationBlockReason.locationPermissionDenied);
    expect(result.message, 'Location permission request failed.');
  });

  test('blocks when permission remains permanently denied', () async {
    final result = await _createService(
      locationAccessPort: _FakeLocationAccessPort(
        serviceStatusValue: ServiceStatus.enabled,
        permissionStatusValue: PermissionStatus.permanentlyDenied,
      ),
    ).ensureReady();

    expect(result.allowed, isFalse);
    expect(result.reason, MapNavigationBlockReason.locationPermissionDenied);
    expect(result.message, 'Location permission is required for navigation.');
  });

  test('blocks when google maps app is unavailable', () async {
    final result = await _createService(
      mapsAvailabilityPort:
          const _FakeGoogleMapsAvailabilityPort(available: false),
    ).ensureReady();

    expect(result.allowed, isFalse);
    expect(result.reason, MapNavigationBlockReason.googleMapsUnavailable);
  });

  test('blocks when Google account is missing on Android', () async {
    final result = await _createService(
      googleAccountPort: const _FakeGoogleAccountPort(
        stateValue: GoogleAccountState.missing,
      ),
      requireGoogleAccountOnAndroid: true,
    ).ensureReady();

    expect(result.allowed, isFalse);
    expect(result.reason, MapNavigationBlockReason.googleAccountMissing);
  });

  test('blocks when Google account state is unknown on Android', () async {
    final result = await _createService(
      googleAccountPort: const _FakeGoogleAccountPort(
        stateValue: GoogleAccountState.unknown,
      ),
      requireGoogleAccountOnAndroid: true,
    ).ensureReady();

    expect(result.allowed, isFalse);
    expect(result.reason, MapNavigationBlockReason.googleAccountUnknown);
  });

  test('allows when Google account is configured on Android', () async {
    final result = await _createService(
      googleAccountPort: const _FakeGoogleAccountPort(
        stateValue: GoogleAccountState.configured,
      ),
      requireGoogleAccountOnAndroid: true,
    ).ensureReady();

    expect(result.allowed, isTrue);
  });

  test('allows when Google account check is disabled', () async {
    final result = await _createService(
      googleAccountPort: const _FakeGoogleAccountPort(
        stateValue: GoogleAccountState.missing,
      ),
      requireGoogleAccountOnAndroid: false,
    ).ensureReady();

    expect(result.allowed, isTrue);
  });

  test('permission handler location access port maps channel responses',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_permissionChannel, (MethodCall call) async {
      switch (call.method) {
        case 'checkServiceStatus':
          return 1;
        case 'checkPermissionStatus':
          return 1;
        case 'requestPermissions':
          return <int, int>{
            Permission.locationWhenInUse.value: 1,
          };
        default:
          return null;
      }
    });

    const port = PermissionHandlerLocationAccessPort();
    expect(await port.serviceStatus(), ServiceStatus.enabled);
    expect(await port.permissionStatus(), PermissionStatus.granted);
    expect(await port.requestPermission(), PermissionStatus.granted);
  });

  test('url launcher google maps availability is true on first probe',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_urlLauncherChannel, (MethodCall call) async {
      if (call.method == 'canLaunch') {
        return true;
      }
      return null;
    });

    const port = UrlLauncherGoogleMapsAvailabilityPort();
    expect(await port.isAvailable(), isTrue);
  });

  test('url launcher google maps availability checks second probe', () async {
    var canLaunchCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_urlLauncherChannel, (MethodCall call) async {
      if (call.method == 'canLaunch') {
        canLaunchCount++;
        return canLaunchCount == 2;
      }
      return null;
    });

    const port = UrlLauncherGoogleMapsAvailabilityPort();
    expect(await port.isAvailable(), isTrue);
  });

  test('url launcher google maps availability handles platform exception',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_urlLauncherChannel, (MethodCall call) async {
      if (call.method == 'canLaunch') {
        throw PlatformException(code: 'probe_failed');
      }
      return null;
    });

    const port = UrlLauncherGoogleMapsAvailabilityPort();
    expect(await port.isAvailable(), isFalse);
  });

  test('url launcher google maps availability handles missing plugin',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_urlLauncherChannel, (MethodCall call) async {
      if (call.method == 'canLaunch') {
        throw MissingPluginException();
      }
      return null;
    });

    const port = UrlLauncherGoogleMapsAvailabilityPort();
    expect(await port.isAvailable(), isFalse);
  });

  test('method channel google account port handles configured account',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_googleAccountChannel,
            (MethodCall call) async {
      if (call.method == 'hasGoogleAccount') {
        return true;
      }
      return null;
    });

    const port = MethodChannelGoogleAccountPort();
    expect(await port.state(), GoogleAccountState.configured);
  });

  test('method channel google account port handles missing account', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_googleAccountChannel,
            (MethodCall call) async {
      if (call.method == 'hasGoogleAccount') {
        return false;
      }
      return null;
    });

    const port = MethodChannelGoogleAccountPort();
    expect(await port.state(), GoogleAccountState.missing);
  });

  test('method channel google account port handles unknown account state',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_googleAccountChannel,
            (MethodCall call) async {
      if (call.method == 'hasGoogleAccount') {
        return null;
      }
      return null;
    });

    const port = MethodChannelGoogleAccountPort();
    expect(await port.state(), GoogleAccountState.unknown);
  });

  test('method channel google account port handles platform exception',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_googleAccountChannel,
            (MethodCall call) async {
      if (call.method == 'hasGoogleAccount') {
        throw PlatformException(code: 'channel_failure');
      }
      return null;
    });

    const port = MethodChannelGoogleAccountPort();
    expect(await port.state(), GoogleAccountState.unknown);
  });

  test('method channel google account port handles missing plugin', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_googleAccountChannel,
            (MethodCall call) async {
      if (call.method == 'hasGoogleAccount') {
        throw MissingPluginException();
      }
      return null;
    });

    const port = MethodChannelGoogleAccountPort();
    expect(await port.state(), GoogleAccountState.unknown);
  });

  test('method channel google account port is unknown on non-android',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    const port = MethodChannelGoogleAccountPort();
    expect(await port.state(), GoogleAccountState.unknown);
  });
}

DefaultMapNavigationPreflightService _createService({
  LocationAccessPort? locationAccessPort,
  GoogleMapsAvailabilityPort? mapsAvailabilityPort,
  GoogleAccountPort? googleAccountPort,
  bool requireGoogleAccountOnAndroid = false,
}) {
  return DefaultMapNavigationPreflightService(
    locationAccessPort: locationAccessPort ??
        _FakeLocationAccessPort(
          serviceStatusValue: ServiceStatus.enabled,
          permissionStatusValue: PermissionStatus.granted,
        ),
    mapsAvailabilityPort: mapsAvailabilityPort ??
        const _FakeGoogleMapsAvailabilityPort(available: true),
    googleAccountPort: googleAccountPort ??
        const _FakeGoogleAccountPort(
          stateValue: GoogleAccountState.configured,
        ),
    requireGoogleAccountOnAndroid: requireGoogleAccountOnAndroid,
  );
}

class _FakeLocationAccessPort implements LocationAccessPort {
  _FakeLocationAccessPort({
    required this.serviceStatusValue,
    required this.permissionStatusValue,
    this.requestResult = PermissionStatus.denied,
    this.serviceStatusError,
    this.permissionStatusError,
    this.requestPermissionError,
  });

  final ServiceStatus serviceStatusValue;
  PermissionStatus permissionStatusValue;
  final PermissionStatus requestResult;
  final Object? serviceStatusError;
  final Object? permissionStatusError;
  final Object? requestPermissionError;
  bool requestCalled = false;

  @override
  Future<PermissionStatus> permissionStatus() async {
    final error = permissionStatusError;
    if (error != null) {
      throw error;
    }
    return permissionStatusValue;
  }

  @override
  Future<PermissionStatus> requestPermission() async {
    requestCalled = true;
    final error = requestPermissionError;
    if (error != null) {
      throw error;
    }
    permissionStatusValue = requestResult;
    return requestResult;
  }

  @override
  Future<ServiceStatus> serviceStatus() async {
    final error = serviceStatusError;
    if (error != null) {
      throw error;
    }
    return serviceStatusValue;
  }
}

class _FakeGoogleMapsAvailabilityPort implements GoogleMapsAvailabilityPort {
  const _FakeGoogleMapsAvailabilityPort({
    required this.available,
  });

  final bool available;

  @override
  Future<bool> isAvailable() async {
    return available;
  }
}

class _FakeGoogleAccountPort implements GoogleAccountPort {
  const _FakeGoogleAccountPort({
    required this.stateValue,
  });

  final GoogleAccountState stateValue;

  @override
  Future<GoogleAccountState> state() async {
    return stateValue;
  }
}
