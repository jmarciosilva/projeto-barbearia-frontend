/// Cache local de respostas de leitura (`GET`), usado como fallback quando
/// a rede falha e ja existe uma resposta anterior salva para o mesmo
/// caminho. `key` e sempre a URL completa (path + query string) do
/// request — dois `GET`s com query diferente sao entradas diferentes.
abstract class ResponseCache {
  Future<void> write(String key, dynamic body);

  /// Retorna `null` quando nao ha nada salvo para `key`.
  Future<dynamic> read(String key);

  /// Limpa tudo — chamado no logout para um dispositivo reaproveitado por
  /// outra conta/tenant nao herdar dados em cache da sessao anterior.
  Future<void> clear();
}
