import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/core/network/network_signal_alert_host.dart';

void main() {
  test('offline alert when there is no active transport', () {
    final alert = decideNetworkAlert(
      connectivityResults: const <ConnectivityResult>[ConnectivityResult.none],
      mobileGeneration: MobileNetworkGeneration.unknown,
    );

    expect(alert, NetworkAlertType.offline);
  });

  test('weak signal alert when cellular generation is 2g or 3g', () {
    final alert2g = decideNetworkAlert(
      connectivityResults: const <ConnectivityResult>[
        ConnectivityResult.mobile
      ],
      mobileGeneration: MobileNetworkGeneration.g2,
    );
    final alert3g = decideNetworkAlert(
      connectivityResults: const <ConnectivityResult>[
        ConnectivityResult.mobile
      ],
      mobileGeneration: MobileNetworkGeneration.g3,
    );

    expect(alert2g, NetworkAlertType.weakSignal);
    expect(alert3g, NetworkAlertType.weakSignal);
  });

  test('no alert on wifi or fast cellular generation', () {
    final wifi = decideNetworkAlert(
      connectivityResults: const <ConnectivityResult>[ConnectivityResult.wifi],
      mobileGeneration: MobileNetworkGeneration.unknown,
    );
    final mobile4g = decideNetworkAlert(
      connectivityResults: const <ConnectivityResult>[
        ConnectivityResult.mobile
      ],
      mobileGeneration: MobileNetworkGeneration.g4,
    );
    final mobile5g = decideNetworkAlert(
      connectivityResults: const <ConnectivityResult>[
        ConnectivityResult.mobile
      ],
      mobileGeneration: MobileNetworkGeneration.g5,
    );

    expect(wifi, NetworkAlertType.none);
    expect(mobile4g, NetworkAlertType.none);
    expect(mobile5g, NetworkAlertType.none);
  });

  test('parse mobile generation from raw value', () {
    expect(parseMobileNetworkGeneration('2g'), MobileNetworkGeneration.g2);
    expect(parseMobileNetworkGeneration('3G'), MobileNetworkGeneration.g3);
    expect(parseMobileNetworkGeneration('4g'), MobileNetworkGeneration.g4);
    expect(parseMobileNetworkGeneration('5g'), MobileNetworkGeneration.g5);
    expect(
      parseMobileNetworkGeneration('something_else'),
      MobileNetworkGeneration.unknown,
    );
    expect(parseMobileNetworkGeneration(null), MobileNetworkGeneration.unknown);
  });

  test('method channel generation port returns unknown in non-android tests',
      () async {
    const port = MethodChannelMobileNetworkGenerationPort();

    final result = await port.currentGeneration();

    expect(result, MobileNetworkGeneration.unknown);
  });

  testWidgets('shows offline dialog from initial connectivity check',
      (WidgetTester tester) async {
    final connectivityPort = _FakeConnectivityStatusPort(
      initialCheckResults: const <ConnectivityResult>[ConnectivityResult.none],
    );
    addTearDown(connectivityPort.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: NetworkSignalAlertHost(
          connectivityStatusPort: connectivityPort,
          mobileNetworkGenerationPort: _FakeMobileNetworkGenerationPort(
            MobileNetworkGeneration.unknown,
          ),
          child: const Scaffold(body: Text('Host Child')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('網路提醒'), findsOneWidget);
    expect(find.text('當前無網路訊號'), findsOneWidget);

    await tester.tap(find.text('確定'));
    await tester.pumpAndSettle();
    expect(find.text('網路提醒'), findsNothing);
  });

  testWidgets('deduplicates same alert until reset by no-alert state',
      (WidgetTester tester) async {
    final connectivityPort = _FakeConnectivityStatusPort(
      initialCheckResults: const <ConnectivityResult>[ConnectivityResult.wifi],
    );
    final generationPort = _FakeMobileNetworkGenerationPort(
      MobileNetworkGeneration.g3,
    );
    addTearDown(connectivityPort.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: NetworkSignalAlertHost(
          connectivityStatusPort: connectivityPort,
          mobileNetworkGenerationPort: generationPort,
          child: const Scaffold(body: Text('Host Child')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('網路提醒'), findsNothing);
    expect(generationPort.callCount, 0);

    connectivityPort.emit(const <ConnectivityResult>[ConnectivityResult.mobile]);
    await tester.pumpAndSettle();
    expect(find.text('網路提醒'), findsOneWidget);
    expect(find.text('目前手機訊號較差，請將手機持往訊號較好的地方'), findsOneWidget);
    expect(generationPort.callCount, 1);

    await tester.tap(find.text('確定'));
    await tester.pumpAndSettle();

    connectivityPort.emit(const <ConnectivityResult>[ConnectivityResult.mobile]);
    await tester.pumpAndSettle();
    expect(find.text('網路提醒'), findsNothing);
    expect(generationPort.callCount, 2);

    connectivityPort.emit(const <ConnectivityResult>[ConnectivityResult.wifi]);
    await tester.pumpAndSettle();
    connectivityPort.emit(const <ConnectivityResult>[ConnectivityResult.mobile]);
    await tester.pumpAndSettle();
    expect(find.text('網路提醒'), findsOneWidget);
    expect(generationPort.callCount, 3);
  });

  testWidgets('checks connectivity again when app is resumed',
      (WidgetTester tester) async {
    final connectivityPort = _FakeConnectivityStatusPort(
      initialCheckResults: const <ConnectivityResult>[ConnectivityResult.wifi],
    );
    addTearDown(connectivityPort.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: NetworkSignalAlertHost(
          connectivityStatusPort: connectivityPort,
          mobileNetworkGenerationPort: _FakeMobileNetworkGenerationPort(
            MobileNetworkGeneration.unknown,
          ),
          child: const Scaffold(body: Text('Host Child')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(connectivityPort.checkCount, 1);

    connectivityPort.initialCheckResults = const <ConnectivityResult>[
      ConnectivityResult.none,
    ];
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(connectivityPort.checkCount, greaterThanOrEqualTo(2));
    expect(find.text('當前無網路訊號'), findsOneWidget);
  });
}

class _FakeConnectivityStatusPort implements ConnectivityStatusPort {
  _FakeConnectivityStatusPort({
    required this.initialCheckResults,
  });

  List<ConnectivityResult> initialCheckResults;
  int checkCount = 0;
  final StreamController<List<ConnectivityResult>> _controller =
      StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    checkCount += 1;
    return initialCheckResults;
  }

  @override
  Stream<List<ConnectivityResult>> onConnectivityChanged() {
    return _controller.stream;
  }

  void emit(List<ConnectivityResult> results) {
    _controller.add(results);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

class _FakeMobileNetworkGenerationPort implements MobileNetworkGenerationPort {
  _FakeMobileNetworkGenerationPort(this.generation);

  final MobileNetworkGeneration generation;
  int callCount = 0;

  @override
  Future<MobileNetworkGeneration> currentGeneration() async {
    callCount += 1;
    return generation;
  }
}
