/// Controla alteracoes locais de estado com commit e rollback explicitos.
///
/// No mobile, nao existe transacao de banco nesta fase. Este helper cumpre o
/// mesmo papel conceitual para estado de tela: guarda o valor anterior, aplica
/// um candidato e permite confirmar ou desfazer a mudanca se algo falhar.
class AppStateTransaction<T> {
  AppStateTransaction(this._snapshot);

  final T _snapshot;
  T? _candidate;
  bool _closed = false;

  /// Prepara o novo valor, mas ainda nao considera a alteracao confirmada.
  void stage(T candidate) {
    _ensureOpen();
    _candidate = candidate;
  }

  /// Confirma a alteracao preparada.
  T commit() {
    _ensureOpen();
    _closed = true;

    return _candidate ?? _snapshot;
  }

  /// Desfaz a alteracao e devolve o valor original.
  T rollback() {
    _ensureOpen();
    _closed = true;

    return _snapshot;
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('Transacao de estado ja finalizada.');
    }
  }
}
