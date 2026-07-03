import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstrai onde o token de autenticacao e persistido, para permitir trocar
/// a implementacao real (`flutter_secure_storage`, que usa platform channels
/// indisponiveis em testes de widget) por uma versao em memoria nos testes.
abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage([this._storage = const FlutterSecureStorage()]);

  static const _key = 'auth_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}
