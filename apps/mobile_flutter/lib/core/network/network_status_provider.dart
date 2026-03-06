import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkStatusNotifier extends AsyncNotifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  Future<bool> build() async {
    final initial = await Connectivity().checkConnectivity();
    final isOnline = _isOnline(initial);

    _sub?.cancel();
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      state = AsyncData(_isOnline(results));
    });

    ref.onDispose(() => _sub?.cancel());
    return isOnline;
  }

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}

final networkStatusProvider =
    AsyncNotifierProvider<NetworkStatusNotifier, bool>(
  NetworkStatusNotifier.new,
);
