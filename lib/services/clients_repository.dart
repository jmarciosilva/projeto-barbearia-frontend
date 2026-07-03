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

  Future<ClientModel> create({
    required String name,
    required String phone,
    String? email,
    String? birthDate,
    String? notes,
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
              },
            )
            as Map<String, dynamic>;

    return ClientModel.fromJson(response);
  }
}
