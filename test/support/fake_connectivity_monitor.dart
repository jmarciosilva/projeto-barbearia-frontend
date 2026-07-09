import 'dart:async';

import 'package:clube_do_salao/services/offline/connectivity_monitor.dart';

/// Monitor de conectividade controlavel manualmente pelos testes, no lugar
/// do `connectivity_plus` (que depende de platform channels).
class FakeConnectivityMonitor implements ConnectivityMonitor {
  FakeConnectivityMonitor({bool online = true}) : _online = online;

  bool _online;
  final _controller = StreamController<bool>.broadcast();

  @override
  Stream<bool> get onOnlineChanged => _controller.stream;

  @override
  Future<bool> probe() async => _online;

  /// Simula a conexao caindo/voltando, disparando `onOnlineChanged` — usado
  /// pelos testes pra acionar o flush automatico da fila.
  void setOnline(bool online) {
    _online = online;
    _controller.add(online);
  }
}
