/// Excecao base do aplicativo.
///
/// Usamos uma classe propria para separar mensagens tecnicas de mensagens
/// seguras para exibicao ao usuario final.
class AppException implements Exception {
  const AppException(this.userMessage, {this.technicalMessage});

  final String userMessage;
  final String? technicalMessage;

  @override
  String toString() => technicalMessage ?? userMessage;
}

/// Erro usado quando a API retorna uma resposta invalida ou inesperada.
class ApiException extends AppException {
  const ApiException(
    super.userMessage, {
    super.technicalMessage,
    this.statusCode,
  });

  final int? statusCode;
}

/// Lancada quando uma mutacao "queueable" nao alcanca o servidor por falta
/// de conexao: em vez de falhar, foi salva localmente para reenvio
/// automatico assim que a internet voltar. Quem chama deve tratar isso como
/// um sucesso local, nao como um erro (ver `ApiClient.postQueueable`).
class QueuedForSyncException extends AppException {
  const QueuedForSyncException(this.description)
    : super(
        '$description Sem conexão agora — será enviado automaticamente quando a internet voltar.',
      );

  final String description;
}
