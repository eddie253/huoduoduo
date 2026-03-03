import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum MobileNetworkGeneration {
  g2,
  g3,
  g4,
  g5,
  unknown,
}

enum NetworkAlertType {
  none,
  weakSignal,
  offline,
}

MobileNetworkGeneration parseMobileNetworkGeneration(String? raw) {
  switch (raw?.toLowerCase()) {
    case '2g':
      return MobileNetworkGeneration.g2;
    case '3g':
      return MobileNetworkGeneration.g3;
    case '4g':
      return MobileNetworkGeneration.g4;
    case '5g':
      return MobileNetworkGeneration.g5;
    default:
      return MobileNetworkGeneration.unknown;
  }
}

NetworkAlertType decideNetworkAlert({
  required List<ConnectivityResult> connectivityResults,
  required MobileNetworkGeneration mobileGeneration,
}) {
  final Set<ConnectivityResult> transports = connectivityResults.toSet();
  final bool hasTransport =
      transports.any((item) => item != ConnectivityResult.none);
  if (!hasTransport) {
    return NetworkAlertType.offline;
  }

  if (transports.contains(ConnectivityResult.wifi) ||
      transports.contains(ConnectivityResult.ethernet)) {
    return NetworkAlertType.none;
  }

  if (transports.contains(ConnectivityResult.mobile)) {
    if (mobileGeneration == MobileNetworkGeneration.g2 ||
        mobileGeneration == MobileNetworkGeneration.g3) {
      return NetworkAlertType.weakSignal;
    }
    return NetworkAlertType.none;
  }

  return NetworkAlertType.none;
}

abstract class ConnectivityStatusPort {
  Future<List<ConnectivityResult>> checkConnectivity();

  Stream<List<ConnectivityResult>> onConnectivityChanged();
}

class ConnectivityPlusStatusPort implements ConnectivityStatusPort {
  ConnectivityPlusStatusPort({
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    final dynamic result = await _connectivity.checkConnectivity();
    return _normalizeConnectivityResult(result);
  }

  @override
  Stream<List<ConnectivityResult>> onConnectivityChanged() {
    return _connectivity.onConnectivityChanged
        .map<List<ConnectivityResult>>(_normalizeConnectivityResult);
  }
}

List<ConnectivityResult> _normalizeConnectivityResult(dynamic raw) {
  if (raw is List<ConnectivityResult>) {
    return raw;
  }
  if (raw is ConnectivityResult) {
    return <ConnectivityResult>[raw];
  }
  return const <ConnectivityResult>[ConnectivityResult.none];
}

abstract class MobileNetworkGenerationPort {
  Future<MobileNetworkGeneration> currentGeneration();
}

class MethodChannelMobileNetworkGenerationPort
    implements MobileNetworkGenerationPort {
  const MethodChannelMobileNetworkGenerationPort();

  static const MethodChannel _channel =
      MethodChannel('com.example.mobile_flutter/network_signal');

  @override
  Future<MobileNetworkGeneration> currentGeneration() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return MobileNetworkGeneration.unknown;
    }
    try {
      final generation =
          await _channel.invokeMethod<String>('getMobileNetworkGeneration');
      return parseMobileNetworkGeneration(generation);
    } on PlatformException {
      return MobileNetworkGeneration.unknown;
    } on MissingPluginException {
      return MobileNetworkGeneration.unknown;
    }
  }
}

class NetworkSignalAlertHost extends StatefulWidget {
  const NetworkSignalAlertHost({
    super.key,
    required this.child,
    ConnectivityStatusPort? connectivityStatusPort,
    MobileNetworkGenerationPort? mobileNetworkGenerationPort,
  })  : _connectivityStatusPort =
            connectivityStatusPort ?? const _DefaultConnectivityStatusPort(),
        _mobileNetworkGenerationPort = mobileNetworkGenerationPort ??
            const MethodChannelMobileNetworkGenerationPort();

  final Widget child;
  final ConnectivityStatusPort _connectivityStatusPort;
  final MobileNetworkGenerationPort _mobileNetworkGenerationPort;

  @override
  State<NetworkSignalAlertHost> createState() => _NetworkSignalAlertHostState();
}

class _NetworkSignalAlertHostState extends State<NetworkSignalAlertHost>
    with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _dialogVisible = false;
  NetworkAlertType _lastShownAlert = NetworkAlertType.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connectivitySub = widget._connectivityStatusPort
        .onConnectivityChanged()
        .listen(_handleConnectivityChange);
    unawaited(_checkAndAlert());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_connectivitySub?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkAndAlert());
    }
  }

  Future<void> _handleConnectivityChange(
    List<ConnectivityResult> results,
  ) async {
    final alert = await _resolveAlert(results);
    _handleAlert(alert);
  }

  Future<void> _checkAndAlert() async {
    final current = await widget._connectivityStatusPort.checkConnectivity();
    final alert = await _resolveAlert(current);
    _handleAlert(alert);
  }

  Future<NetworkAlertType> _resolveAlert(
    List<ConnectivityResult> results,
  ) async {
    MobileNetworkGeneration generation = MobileNetworkGeneration.unknown;
    if (results.contains(ConnectivityResult.mobile)) {
      generation =
          await widget._mobileNetworkGenerationPort.currentGeneration();
    }
    return decideNetworkAlert(
      connectivityResults: results,
      mobileGeneration: generation,
    );
  }

  void _handleAlert(NetworkAlertType alert) {
    if (!mounted) {
      return;
    }
    if (alert == NetworkAlertType.none) {
      _lastShownAlert = NetworkAlertType.none;
      return;
    }
    if (_dialogVisible || _lastShownAlert == alert) {
      return;
    }
    _lastShownAlert = alert;
    _dialogVisible = true;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('網路提醒'),
            content: Text(
              alert == NetworkAlertType.offline
                  ? '當前無網路訊號'
                  : '目前手機訊號較差，請將手機持往訊號較好的地方',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('確定'),
              ),
            ],
          );
        },
      ).whenComplete(() {
        _dialogVisible = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _DefaultConnectivityStatusPort implements ConnectivityStatusPort {
  const _DefaultConnectivityStatusPort();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() {
    return ConnectivityPlusStatusPort().checkConnectivity();
  }

  @override
  Stream<List<ConnectivityResult>> onConnectivityChanged() {
    return ConnectivityPlusStatusPort().onConnectivityChanged();
  }
}
