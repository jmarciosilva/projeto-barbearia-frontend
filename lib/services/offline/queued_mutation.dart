enum QueuedMutationStatus { pending, failed }

/// Uma mutacao (POST/PATCH) que falhou por falta de conexao e esta salva
/// localmente para reenvio automatico. `id` e atribuido pelo storage na
/// criacao (autoincrement) e usado para marcar como falha ou descartar.
class QueuedMutation {
  const QueuedMutation({
    required this.id,
    required this.method,
    required this.path,
    required this.body,
    required this.description,
    required this.createdAt,
    this.status = QueuedMutationStatus.pending,
    this.lastError,
  });

  final int id;
  final String method;
  final String path;
  final Map<String, dynamic> body;
  final String description;
  final DateTime createdAt;
  final QueuedMutationStatus status;
  final String? lastError;

  QueuedMutation copyWith({
    QueuedMutationStatus? status,
    String? lastError,
  }) {
    return QueuedMutation(
      id: id,
      method: method,
      path: path,
      body: body,
      description: description,
      createdAt: createdAt,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
    );
  }
}
