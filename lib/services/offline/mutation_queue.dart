import 'dart:async';

import 'package:clube_do_salao/core/app_exception.dart';
import 'package:clube_do_salao/services/api_client.dart';
import 'package:clube_do_salao/services/offline/connectivity_monitor.dart';
import 'package:clube_do_salao/services/offline/mutation_queue_storage.dart';
import 'package:clube_do_salao/services/offline/queue_sink.dart';
import 'package:clube_do_salao/services/offline/queued_mutation.dart';
import 'package:flutter/widgets.dart';

/// Orquestra a fila de mutacoes offline: recebe itens de `ApiClient` (via
/// `QueueSink`), persiste, e tenta reenviar quando a conexao volta (sinal de
/// `ConnectivityMonitor`), quando o app volta ao primeiro plano, ou por um
/// timer periodico de seguranca. Reenvio sempre passa por `apiClient.post`/
/// `patch` (as variantes nao-queueable), entao nunca reenfileira a si mesmo.
class MutationQueue extends ChangeNotifier
    with WidgetsBindingObserver
    implements QueueSink {
  MutationQueue({
    required ApiClient apiClient,
    required MutationQueueStorage storage,
    required ConnectivityMonitor connectivityMonitor,
  }) : _apiClient = apiClient,
       _storage = storage,
       _connectivityMonitor = connectivityMonitor;

  final ApiClient _apiClient;
  final MutationQueueStorage _storage;
  final ConnectivityMonitor _connectivityMonitor;

  final List<QueuedMutation> _items = [];
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _safetyTimer;
  bool _isFlushing = false;
  bool _isInitialized = false;

  bool isOnline = true;

  List<QueuedMutation> get items => List.unmodifiable(_items);

  int get pendingCount =>
      _items.where((item) => item.status == QueuedMutationStatus.pending).length;

  /// Carrega o estado persistido e liga os 3 gatilhos de flush (conexao
  /// voltando, app retomado, timer periodico de seguranca). Chamado uma vez
  /// por `AuthSession`, apos restaurar ou criar a sessao.
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _items.addAll(await _storage.all());
    notifyListeners();

    isOnline = await _connectivityMonitor.probe();

    WidgetsBinding.instance.addObserver(this);

    _connectivitySubscription = _connectivityMonitor.onOnlineChanged.listen((
      online,
    ) {
      isOnline = online;
      notifyListeners();
      if (online) unawaited(flush());
    });

    _safetyTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(flush()),
    );

    unawaited(flush());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(flush());
    }
  }

  @override
  Future<void> enqueue({
    required String method,
    required String path,
    required Map<String, dynamic> body,
    required String description,
  }) async {
    final id = await _storage.add(
      method: method,
      path: path,
      body: body,
      description: description,
    );

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

    notifyListeners();
  }

  /// Reenvia os itens pendentes em ordem estrita de criacao (FIFO global,
  /// sem particionar por tipo — nao ha caso real de conflito entre tipos
  /// diferentes de mutacao nesta v1). Uma falha de rede para o lote inteiro
  /// (nada mais vai funcionar agora); uma rejeicao real do servidor (ex:
  /// validacao) marca so aquele item como falho e segue pros proximos.
  Future<void> flush() async {
    if (_isFlushing || !_apiClient.hasToken) return;
    _isFlushing = true;

    try {
      final pending = _items
          .where((item) => item.status == QueuedMutationStatus.pending)
          .toList();

      for (final item in pending) {
        try {
          await _replay(item);
          await _storage.remove(item.id);
          _items.removeWhere((i) => i.id == item.id);
          notifyListeners();
        } on ApiException catch (error) {
          if (error.statusCode == null) {
            // Falha de conexao: os proximos itens tambem vao falhar por
            // rede, entao para o lote inteiro em vez de tentar todos.
            return;
          }

          await _storage.markFailed(item.id, error.userMessage);
          final index = _items.indexWhere((i) => i.id == item.id);
          if (index != -1) {
            _items[index] = _items[index].copyWith(
              status: QueuedMutationStatus.failed,
              lastError: error.userMessage,
            );
          }
          notifyListeners();
        }
      }
    } finally {
      _isFlushing = false;
    }
  }

  /// Descarta um item com falha permanente — usado pela tela de
  /// sincronizacao pendente. So faz sentido para itens `failed`; o dono
  /// refaz a acao manualmente quando online.
  Future<void> discard(int id) async {
    await _storage.remove(id);
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  Future<dynamic> _replay(QueuedMutation item) {
    return switch (item.method) {
      'POST' => _apiClient.post(item.path, body: item.body),
      'PATCH' => _apiClient.patch(item.path, body: item.body),
      _ => throw StateError('Metodo de fila desconhecido: ${item.method}'),
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _safetyTimer?.cancel();
    super.dispose();
  }
}
