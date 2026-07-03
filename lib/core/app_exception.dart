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
