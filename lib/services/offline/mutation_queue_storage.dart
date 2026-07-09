import 'package:clube_do_salao/services/offline/queued_mutation.dart';

/// Persistencia da fila de mutacoes pendentes. Implementacao real usa
/// `sqflite` (unico banco local do app); testes usam um fake em memoria —
/// mesmo padrao ja usado por `TokenStorage`/`OnboardingChecklistStorage`.
abstract class MutationQueueStorage {
  Future<int> add({
    required String method,
    required String path,
    required Map<String, dynamic> body,
    required String description,
  });

  /// Todos os itens, ordenados por `id` crescente (ordem de criacao) — usado
  /// tanto para carregar o estado inicial quanto para a tela de pendencias.
  Future<List<QueuedMutation>> all();

  Future<void> markFailed(int id, String errorMessage);

  Future<void> remove(int id);
}
