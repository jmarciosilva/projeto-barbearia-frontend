import 'package:clube_do_salao/models/client_model.dart';
import 'package:clube_do_salao/services/api_client.dart';

class ClientsRepository {
  const ClientsRepository(this._client);

  final ApiClient _client;

  Future<List<ClientModel>> index() async {
    final response = await _client.get('/clients') as List<dynamic>;

    return response
        .map((json) => ClientModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Ficha do cliente logado (`GET /me/client`), com plano, pagamento e
  /// historico de uso reais. So funciona para quem tem papel `customer`.
  Future<ClientModel> me() async {
    final response = await _client.get('/me/client') as Map<String, dynamic>;

    return ClientModel.fromJson(response);
  }

  Future<ClientModel> create({
    required String name,
    required String phone,
    String? email,
    String? birthDate,
    String? notes,
    String? password,
  }) async {
    final response =
        await _client.post(
              '/clients',
              body: {
                'name': name,
                'phone': phone,
                'email': ?email,
                'birth_date': ?birthDate,
                'notes': ?notes,
                'password': ?password,
              },
            )
            as Map<String, dynamic>;

    return ClientModel.fromJson(response);
  }

  /// Autoedicao do proprio perfil (`PATCH /me/client`). Nao mexe em e-mail/
  /// senha de login — isso continua exclusivo de `PATCH /me/credentials`.
  Future<ClientModel> updateMe({String? name, String? phone, String? email}) async {
    final response =
        await _client.patch(
              '/me/client',
              body: {'name': ?name, 'phone': ?phone, 'email': ?email},
            )
            as Map<String, dynamic>;

    return ClientModel.fromJson(response);
  }

  /// Edicao de um cliente pelo proprietario (`PATCH /clients/{id}`).
  Future<ClientModel> update({
    required int id,
    String? name,
    String? phone,
    String? notes,
    String? status,
  }) async {
    final response =
        await _client.patch(
              '/clients/$id',
              body: {
                'name': ?name,
                'phone': ?phone,
                'notes': ?notes,
                'status': ?status,
              },
            )
            as Map<String, dynamic>;

    return ClientModel.fromJson(response);
  }
}
