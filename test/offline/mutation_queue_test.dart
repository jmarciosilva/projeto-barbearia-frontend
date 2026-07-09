import 'dart:convert';
import 'dart:io';

import 'package:clube_do_salao/core/app_exception.dart';
import 'package:clube_do_salao/services/api_client.dart';
import 'package:clube_do_salao/services/appointments_repository.dart';
import 'package:clube_do_salao/services/offline/mutation_queue.dart';
import 'package:clube_do_salao/services/offline/queued_mutation.dart';
import 'package:clube_do_salao/services/waitlist_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/fake_connectivity_monitor.dart';
import '../support/fake_mutation_queue_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<MutationQueue> buildQueue(ApiClient apiClient) async {
    apiClient.updateToken('token');
    final queue = MutationQueue(
      apiClient: apiClient,
      storage: FakeMutationQueueStorage(),
      connectivityMonitor: FakeConnectivityMonitor(),
    );
    apiClient.attachQueueSink(queue);
    await queue.init();
    return queue;
  }

  test(
    'mutacao offline vira QueuedForSyncException e fica pendente na fila',
    () async {
      final apiClient = ApiClient(
        httpClient: MockClient(
          (request) async => throw const SocketException('offline (teste)'),
        ),
      );
      final queue = await buildQueue(apiClient);
      addTearDown(queue.dispose);

      await expectLater(
        apiClient.postQueueable(
          '/clients',
          body: {'name': 'Ana'},
          description: "Cliente 'Ana' — cadastro",
        ),
        throwsA(isA<QueuedForSyncException>()),
      );

      expect(queue.pendingCount, 1);
      expect(queue.items.single.path, '/clients');
      expect(queue.items.single.status, QueuedMutationStatus.pending);
    },
  );

  test(
    'flush() apos reconectar reenvia via ApiClient.post e remove o item da fila',
    () async {
      var online = false;
      final apiClient = ApiClient(
        httpClient: MockClient((request) async {
          if (!online) throw const SocketException('offline (teste)');
          return http.Response(jsonEncode({'id': 1}), 200);
        }),
      );
      final queue = await buildQueue(apiClient);
      addTearDown(queue.dispose);

      await expectLater(
        apiClient.postQueueable(
          '/clients',
          body: {'name': 'Ana'},
          description: 'Cliente',
        ),
        throwsA(isA<QueuedForSyncException>()),
      );
      expect(queue.pendingCount, 1);

      online = true;
      await queue.flush();

      expect(queue.pendingCount, 0);
      expect(queue.items, isEmpty);
    },
  );

  test('erro de validacao do servidor nunca entra na fila', () async {
    final apiClient = ApiClient(
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'message': 'Dados invalidos.',
            'error': 'validation_error',
            'errors': {
              'name': ['Nome invalido.'],
            },
          }),
          422,
        ),
      ),
    );
    final queue = await buildQueue(apiClient);
    addTearDown(queue.dispose);

    await expectLater(
      apiClient.postQueueable(
        '/clients',
        body: {'name': ''},
        description: 'Cliente',
      ),
      throwsA(isA<ApiException>()),
    );

    expect(queue.pendingCount, 0);
  });

  test('flush respeita a ordem FIFO de criacao', () async {
    final callOrder = <String>[];
    var online = false;
    final apiClient = ApiClient(
      httpClient: MockClient((request) async {
        if (!online) throw const SocketException('offline (teste)');
        callOrder.add(request.url.path);
        return http.Response(jsonEncode({'ok': true}), 200);
      }),
    );
    final queue = await buildQueue(apiClient);
    addTearDown(queue.dispose);

    await expectLater(
      apiClient.postQueueable('/first', body: {}, description: 'Primeiro'),
      throwsA(isA<QueuedForSyncException>()),
    );
    await expectLater(
      apiClient.postQueueable('/second', body: {}, description: 'Segundo'),
      throwsA(isA<QueuedForSyncException>()),
    );

    online = true;
    await queue.flush();

    expect(callOrder, ['/api/first', '/api/second']);
  });

  test(
    'flush para o lote inteiro numa falha de rede no meio, sem marcar nada como falho',
    () async {
      final apiClient = ApiClient(
        httpClient: MockClient(
          (request) async => throw const SocketException('offline (teste)'),
        ),
      );
      final queue = await buildQueue(apiClient);
      addTearDown(queue.dispose);

      await expectLater(
        apiClient.postQueueable('/first', body: {}, description: 'Primeiro'),
        throwsA(isA<QueuedForSyncException>()),
      );
      await expectLater(
        apiClient.postQueueable('/second', body: {}, description: 'Segundo'),
        throwsA(isA<QueuedForSyncException>()),
      );

      await queue.flush(); // ainda offline

      expect(queue.pendingCount, 2);
      expect(
        queue.items.every(
          (item) => item.status == QueuedMutationStatus.pending,
        ),
        isTrue,
      );
    },
  );

  test(
    'flush marca so o item com falha de validacao e continua os outros',
    () async {
      var online = false;
      final apiClient = ApiClient(
        httpClient: MockClient((request) async {
          if (!online) throw const SocketException('offline (teste)');
          if (request.url.path.endsWith('/bad')) {
            return http.Response(
              jsonEncode({
                'message': 'Dados invalidos.',
                'error': 'validation_error',
                'errors': {
                  'name': ['invalido'],
                },
              }),
              422,
            );
          }
          return http.Response(jsonEncode({'ok': true}), 200);
        }),
      );
      final queue = await buildQueue(apiClient);
      addTearDown(queue.dispose);

      await expectLater(
        apiClient.postQueueable('/bad', body: {}, description: 'Ruim'),
        throwsA(isA<QueuedForSyncException>()),
      );
      await expectLater(
        apiClient.postQueueable('/good', body: {}, description: 'Bom'),
        throwsA(isA<QueuedForSyncException>()),
      );

      online = true;
      await queue.flush();

      expect(queue.pendingCount, 0);
      expect(queue.items, hasLength(1));
      expect(queue.items.single.status, QueuedMutationStatus.failed);
      expect(queue.items.single.path, '/bad');
    },
  );

  test(
    'criar agendamento offline continua lancando ApiException normal, nunca entra na fila',
    () async {
      final apiClient = ApiClient(
        httpClient: MockClient(
          (request) async => throw const SocketException('offline (teste)'),
        ),
      );
      final queue = await buildQueue(apiClient);
      addTearDown(queue.dispose);

      await expectLater(
        AppointmentsRepository(apiClient).create(
          clientId: 1,
          professionalId: 2,
          serviceId: 3,
          startsAt: DateTime(2026, 7, 10, 9),
        ),
        throwsA(
          allOf(isA<ApiException>(), isNot(isA<QueuedForSyncException>())),
        ),
      );

      expect(queue.pendingCount, 0);
    },
  );

  test(
    'atribuir horario da fila de espera offline continua lancando ApiException normal, nunca entra na fila',
    () async {
      final apiClient = ApiClient(
        httpClient: MockClient(
          (request) async => throw const SocketException('offline (teste)'),
        ),
      );
      final queue = await buildQueue(apiClient);
      addTearDown(queue.dispose);

      await expectLater(
        WaitlistRepository(
          apiClient,
        ).assign(id: 1, startsAt: DateTime(2026, 7, 10, 9)),
        throwsA(
          allOf(isA<ApiException>(), isNot(isA<QueuedForSyncException>())),
        ),
      );

      expect(queue.pendingCount, 0);
    },
  );
}
