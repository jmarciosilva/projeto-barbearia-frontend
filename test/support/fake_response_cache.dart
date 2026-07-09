import 'package:clube_do_salao/services/offline/response_cache.dart';

/// Cache de respostas em memoria, usado no lugar do `sqflite` (que depende
/// de platform channels) nos testes.
class FakeResponseCache implements ResponseCache {
  final Map<String, dynamic> _entries = {};

  @override
  Future<void> write(String key, dynamic body) async => _entries[key] = body;

  @override
  Future<dynamic> read(String key) async => _entries[key];

  @override
  Future<void> clear() async => _entries.clear();
}
