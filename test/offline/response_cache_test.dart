import 'dart:convert';
import 'dart:io';

import 'package:clube_do_salao/core/app_exception.dart';
import 'package:clube_do_salao/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/fake_response_cache.dart';

void main() {
  test(
    'GET com sucesso fica em cache e uma falha de rede depois no mesmo caminho retorna o valor cacheado',
    () async {
      var callCount = 0;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          callCount++;
          if (callCount == 1) {
            return http.Response(jsonEncode({'value': 42}), 200);
          }
          throw const SocketException('offline (simulado em teste)');
        }),
      );
      client.attachResponseCache(FakeResponseCache());

      final first = await client.get('/data');
      expect(first, {'value': 42});

      final second = await client.get('/data');
      expect(second, {'value': 42});
      expect(callCount, 2, reason: 'a segunda chamada deve tentar a rede antes de cair no cache');
    },
  );

  test(
    'GET offline em caminho nunca buscado antes continua lancando ApiException normalmente',
    () async {
      final client = ApiClient(
        httpClient: MockClient(
          (request) async => throw const SocketException('offline (simulado em teste)'),
        ),
      );
      client.attachResponseCache(FakeResponseCache());

      expect(client.get('/never-fetched'), throwsA(isA<ApiException>()));
    },
  );

  test('sem cache anexado, comportamento continua identico ao de hoje', () async {
    final client = ApiClient(
      httpClient: MockClient(
        (request) async => throw const SocketException('offline (simulado em teste)'),
      ),
    );

    expect(client.get('/data'), throwsA(isA<ApiException>()));
  });
}
