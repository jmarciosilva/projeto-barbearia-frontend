import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clube_do_salao/core/app_exception.dart';
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

  void updateToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<dynamic> get(String path, {Map<String, String>? query}) {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);

    return _send(() => _httpClient.get(uri, headers: _headers));
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
