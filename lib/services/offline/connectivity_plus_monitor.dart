import 'package:clube_do_salao/services/offline/connectivity_monitor.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityPlusMonitor implements ConnectivityMonitor {
  ConnectivityPlusMonitor() : _connectivity = Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<bool> get onOnlineChanged =>
      _connectivity.onConnectivityChanged.map(_isOnline);

  @override
  Future<bool> probe() async => _isOnline(await _connectivity.checkConnectivity());

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
