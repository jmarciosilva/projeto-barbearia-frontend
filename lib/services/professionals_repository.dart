import 'package:clube_do_salao/models/professional_finance_model.dart';
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
        .map((json) => ProfessionalModel.fromJson(json as Map<String, dynamic>))
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

  /// Cadastro de profissional pelo proprietario (`POST /professionals`).
  /// Senha e opcional: quando informada, libera acesso ao app com o email
  /// como login.
  Future<ProfessionalModel> create({
    required String name,
    String? email,
    String? phone,
    String? specialty,
    int? commissionPercentage,
    String? password,
    List<int> serviceIds = const [],
  }) async {
    final response =
        await _client.post(
              '/professionals',
              body: {
                'name': name,
                'email': ?email,
                'phone': ?phone,
                'specialty': ?specialty,
                'commission_percentage': ?commissionPercentage,
                'password': ?password,
                'service_ids': serviceIds,
              },
            )
            as Map<String, dynamic>;

    return ProfessionalModel.fromJson(response);
  }

  /// Edicao de um profissional pelo proprietario (`PATCH /professionals/{id}`),
  /// incluindo os servicos habilitados (spec 4.1).
  Future<ProfessionalModel> update({
    required int id,
    String? name,
    String? email,
    String? phone,
    String? specialty,
    int? commissionPercentage,
    bool? isActive,
    List<int>? serviceIds,
  }) async {
    final response =
        await _client.patch(
              '/professionals/$id',
              body: {
                'name': ?name,
                'email': ?email,
                'phone': ?phone,
                'specialty': ?specialty,
                'commission_percentage': ?commissionPercentage,
                'is_active': ?isActive,
                'service_ids': ?serviceIds,
              },
            )
            as Map<String, dynamic>;

    return ProfessionalModel.fromJson(response);
  }

  Future<ProfessionalFinanceModel> myFinance({String period = 'month'}) async {
    final response =
        await _client.get('/me/professional/finance', query: {'period': period})
            as Map<String, dynamic>;

    return ProfessionalFinanceModel.fromJson(response);
  }

  Future<ProfessionalFinanceModel> finance(
    int professionalId, {
    String period = 'month',
  }) async {
    final response =
        await _client.get(
              '/professionals/$professionalId/finance',
              query: {'period': period},
            )
            as Map<String, dynamic>;

    return ProfessionalFinanceModel.fromJson(response);
  }

  Future<ProfessionalAdvanceModel> createAdvance({
    required int professionalId,
    required int amountCents,
    String? notes,
  }) async {
    final response =
        await _client.post(
              '/professionals/$professionalId/advances',
              body: {'amount_cents': amountCents, 'notes': ?notes},
            )
            as Map<String, dynamic>;

    return ProfessionalAdvanceModel.fromJson(response);
  }
}
