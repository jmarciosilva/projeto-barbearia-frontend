import 'package:clube_do_salao/services/token_storage.dart';

/// Armazenamento de token em memoria, usado no lugar do
/// `flutter_secure_storage` (que depende de platform channels) nos testes.
class FakeTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> delete() async => _token = null;
}
