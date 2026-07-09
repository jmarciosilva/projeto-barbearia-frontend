import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clube_do_salao/core/app_exception.dart';
import 'package:clube_do_salao/services/offline/queue_sink.dart';
import 'package:clube_do_salao/services/offline/response_cache.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Cliente HTTP fino para a API do Clube do Salao.
///
/// Resolve a base URL por plataforma: o emulador Android usa `10.0.2.2` para
/// alcancar o `localhost` da maquina host; iOS/desktop usam `localhost` direto.
/// Ver `backend/docs/api.md` para o contrato completo dos endpoints.
class ApiClient {
  ApiClient({String? token, http.Client? httpClient})
    : _token = token,
      _httpClient = httpClient ?? http.Client();

  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }

    return 'http://localhost:8000/api';
  }

  final http.Client _httpClient;
  String? _token;
  QueueSink? _queueSink;
  ResponseCache? _responseCache;

  void updateToken(String? token) {
    _token = token;
  }

  /// Usado por `MutationQueue` para evitar tentar sincronizar antes do
  /// token ser restaurado na abertura do app (evita marcar item como
  /// falho por um 401 que na verdade e so uma corrida de inicializacao).
  bool get hasToken => _token != null;

  /// Liga a fila de sincronizacao offline (`MutationQueue`), atraves da
  /// interface minima `QueueSink` para nao criar dependencia circular.
  /// Chamado por `AuthSession` logo apos a construcao, mesmo padrao ja usado
  /// por `updateToken`.
  void attachQueueSink(QueueSink sink) => _queueSink = sink;

  /// Liga o cache local de respostas `GET`. Ver `attachQueueSink`.
  void attachResponseCache(ResponseCache cache) => _responseCache = cache;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  /// Tenta a rede primeiro; em sucesso, atualiza o cache local. Numa falha
  /// de conexao (nao um erro do servidor), cai para a ultima resposta em
  /// cache do mesmo caminho, se existir — senao comporta-se como antes.
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);

    try {
      final result = await _send(() => _httpClient.get(uri, headers: _headers));
      unawaited(_responseCache?.write(uri.toString(), result));
      return result;
    } on ApiException catch (error) {
      if (error.statusCode == null) {
        final cached = await _responseCache?.read(uri.toString());
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) {
    final uri = Uri.parse('$baseUrl$path');

    return _send(
      () =>
          _httpClient.post(uri, headers: _headers, body: jsonEncode(body ?? {})),
    );
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) {
    final uri = Uri.parse('$baseUrl$path');

    return _send(
      () => _httpClient.patch(
        uri,
        headers: _headers,
        body: jsonEncode(body ?? {}),
      ),
    );
  }

  Future<dynamic> delete(String path) {
    final uri = Uri.parse('$baseUrl$path');

    return _send(() => _httpClient.delete(uri, headers: _headers));
  }

  /// Variante de `post` para mutacoes seguras de enfileirar offline (ver
  /// roadmap: cadastro de cliente, edicao de perfil, adiantamento, catalogo,
  /// planos, conclusao de atendimento e confirmacao de pagamento — nunca
  /// criacao de agendamento nem atribuicao de fila de espera, que reservam
  /// um horario e nao tem uma boa resolucao automatica de conflito).
  /// `description` e o texto amigavel mostrado na tela de sincronizacao
  /// pendente caso o envio falhe por falta de conexao.
  Future<dynamic> postQueueable(
    String path, {
    Map<String, dynamic>? body,
    required String description,
  }) => _sendQueueable(
    'POST',
    path,
    body ?? {},
    description,
    () => post(path, body: body),
  );

  /// Ver `postQueueable`.
  Future<dynamic> patchQueueable(
    String path, {
    Map<String, dynamic>? body,
    required String description,
  }) => _sendQueueable(
    'PATCH',
    path,
    body ?? {},
    description,
    () => patch(path, body: body),
  );

  Future<dynamic> _sendQueueable(
    String method,
    String path,
    Map<String, dynamic> body,
    String description,
    Future<dynamic> Function() send,
  ) async {
    try {
      return await send();
    } on ApiException catch (error) {
      if (error.statusCode == null && _queueSink != null) {
        await _queueSink!.enqueue(
          method: method,
          path: path,
          body: body,
          description: description,
        );
        throw QueuedForSyncException(description);
      }
      rethrow;
    }
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    late final http.Response response;

    try {
      response = await request().timeout(const Duration(seconds: 15));
    } on SocketException {
      throw const ApiException(
        'Nao foi possivel conectar ao servidor. Verifique sua conexao.',
      );
    } on TimeoutException {
      throw const ApiException('O servidor demorou para responder.');
    }

    final hasBody = response.body.isNotEmpty;
    final decoded = hasBody ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw _toException(response.statusCode, decoded);
  }

  ApiException _toException(int statusCode, dynamic decoded) {
    final map = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    final serverMessage = map['message'] as String?;

    if (map['error'] == 'validation_error') {
      final errors = map['errors'] as Map<String, dynamic>?;
      final firstError = errors?.values.firstOrNull;
      final detail = firstError is List && firstError.isNotEmpty
          ? firstError.first as String
          : null;

      return ApiException(
        detail ?? serverMessage ?? 'Dados invalidos.',
        statusCode: statusCode,
      );
    }

    return ApiException(
      serverMessage ?? 'Nao foi possivel completar a operacao.',
      technicalMessage: 'HTTP $statusCode: $decoded',
      statusCode: statusCode,
    );
  }
}
