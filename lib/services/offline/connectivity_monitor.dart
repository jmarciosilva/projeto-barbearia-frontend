/// Deteccao proativa de conectividade — usada so como dica para tentar
/// sincronizar mais cedo e para pintar o indicador de status na barra
/// superior. NUNCA e a fonte de verdade sobre se um request vai funcionar:
/// a fila sempre tenta a chamada HTTP real; uma falha real de rede
/// (`SocketException`, ver `ApiClient`) e o unico criterio que decide se
/// algo entra na fila.
abstract class ConnectivityMonitor {
  Stream<bool> get onOnlineChanged;

  Future<bool> probe();
}
