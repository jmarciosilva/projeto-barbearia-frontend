import 'package:clube_do_salao/models/professional_model.dart';
import 'package:clube_do_salao/services/api_client.dart';

class ProfessionalsRepository {
  const ProfessionalsRepository(this._client);

  final ApiClient _client;

  /// `GET /professionals`. Owner/professional veem todos; customer ve so
  /// os ativos (o backend ja filtra por papel).
  Future<List<ProfessionalModel>> index() async {
    final response = await _client.get('/professionals') as List<dynamic>;

    return response
        .map(
          (json) => ProfessionalModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  /// Perfil do profissional logado (`GET /me/professional`).
  Future<ProfessionalModel> me() async {
    final response =
        await _client.get('/me/professional') as Map<String, dynamic>;

    return ProfessionalModel.fromJson(response);
  }

  /// Autoedicao do proprio perfil (`PATCH /me/professional`). Nao aceita
  /// comissao nem ativacao — isso continua exclusivo do proprietario.
  Future<ProfessionalModel> updateMe({
    String? name,
    String? email,
    String? phone,
    String? specialty,
  }) async {
    final response =
        await _client.patch(
              '/me/professional',
              body: {
                'name': ?name,
                'email': ?email,
                'phone': ?phone,
                'specialty': ?specialty,
              },
            )
            as Map<String, dynamic>;

    return ProfessionalModel.fromJson(response);
  }
}
