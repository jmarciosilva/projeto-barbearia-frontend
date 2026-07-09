import 'package:clube_do_salao/services/offline/mutation_queue_storage.dart';
import 'package:clube_do_salao/services/offline/queued_mutation.dart';

/// Fila de mutacoes em memoria, usada no lugar do `sqflite` (que depende de
/// platform channels) nos testes.
class FakeMutationQueueStorage implements MutationQueueStorage {
  final List<QueuedMutation> _items = [];
  int _nextId = 1;

  @override
  Future<int> add({
    required String method,
    required String path,
    required Map<String, dynamic> body,
    required String description,
  }) async {
    final id = _nextId++;
    _items.add(
      QueuedMutation(
        id: id,
        method: method,
        path: path,
        body: body,
        description: description,
        createdAt: DateTime.now(),
      ),
    );
    return id;
  }

  @override
  Future<List<QueuedMutation>> all() async => List.unmodifiable(_items);

  @override
  Future<void> markFailed(int id, String errorMessage) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _items[index] = _items[index].copyWith(
      status: QueuedMutationStatus.failed,
      lastError: errorMessage,
    );
  }

  @override
  Future<void> remove(int id) async {
    _items.removeWhere((item) => item.id == id);
  }
}
