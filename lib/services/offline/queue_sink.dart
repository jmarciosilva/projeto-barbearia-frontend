/// Interface minima que `ApiClient` conhece para enfileirar uma mutacao que
/// falhou por falta de conexao. Mantida separada de `MutationQueue` (que
/// implementa esta interface) para `ApiClient` nunca importar nada de
/// `mutation_queue.dart` — evita dependencia circular, ja que `MutationQueue`
/// precisa de uma referencia a `ApiClient` para reenviar a fila depois.
abstract class QueueSink {
  Future<void> enqueue({
    required String method,
    required String path,
    required Map<String, dynamic> body,
    required String description,
  });
}
