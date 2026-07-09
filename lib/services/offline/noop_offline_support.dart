import 'package:clube_do_salao/services/offline/connectivity_monitor.dart';
import 'package:clube_do_salao/services/offline/mutation_queue_storage.dart';
import 'package:clube_do_salao/services/offline/queued_mutation.dart';
import 'package:clube_do_salao/services/offline/response_cache.dart';

/// Implementacoes sem efeito, usadas quando `sqflite`/`connectivity_plus`
/// nao estao disponiveis na plataforma (hoje: `kIsWeb`). O app se comporta
/// exatamente como antes desta feature nesses casos — sem cache, sem fila.
class NoopMutationQueueStorage implements MutationQueueStorage {
  const NoopMutationQueueStorage();

  @override
  Future<int> add({
    required String method,
    required String path,
    required Map<String, dynamic> body,
    required String description,
  }) async => 0;

  @override
  Future<List<QueuedMutation>> all() async => const [];

  @override
  Future<void> markFailed(int id, String errorMessage) async {}

  @override
  Future<void> remove(int id) async {}
}

class NoopResponseCache implements ResponseCache {
  const NoopResponseCache();

  @override
  Future<void> write(String key, dynamic body) async {}

  @override
  Future<dynamic> read(String key) async => null;

  @override
  Future<void> clear() async {}
}

class NoopConnectivityMonitor implements ConnectivityMonitor {
  const NoopConnectivityMonitor();

  @override
  Stream<bool> get onOnlineChanged => const Stream.empty();

  @override
  Future<bool> probe() async => true;
}
