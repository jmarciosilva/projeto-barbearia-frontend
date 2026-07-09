import 'package:clube_do_salao/models/professional_finance_model.dart';
import 'package:clube_do_salao/models/professional_model.dart';
import 'package:clube_do_salao/models/professional_schedule_override_model.dart';
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
  /// Enfileiravel offline (roadmap): nao disputa um horario de agenda.
  Future<ProfessionalModel> updateMe({
    String? name,
    String? email,
    String? phone,
    String? specialty,
  }) async {
    final response =
        await _client.patchQueueable(
              '/me/professional',
              body: {
                'name': ?name,
                'email': ?email,
                'phone': ?phone,
                'specialty': ?specialty,
              },
              description: 'Meu perfil — atualização',
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
    List<ProfessionalWorkingHourModel>? workingHours,
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
                if (workingHours != null)
                  'working_hours': workingHours.map((h) => h.toJson()).toList(),
              },
            )
            as Map<String, dynamic>;

    return ProfessionalModel.fromJson(response);
  }

  /// Edicao de um profissional pelo proprietario (`PATCH /professionals/{id}`),
  /// incluindo os servicos habilitados (spec 4.1) e o horario de trabalho.
  Future<ProfessionalModel> update({
    required int id,
    String? name,
    String? email,
    String? phone,
    String? specialty,
    int? commissionPercentage,
    bool? isActive,
    List<int>? serviceIds,
    List<ProfessionalWorkingHourModel>? workingHours,
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
                if (workingHours != null)
                  'working_hours': workingHours.map((h) => h.toJson()).toList(),
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

  /// Enfileiravel offline (roadmap): registra um adiantamento ja pago fora
  /// do app (dinheiro/pix na hora), nao disputa um horario de agenda.
  Future<ProfessionalAdvanceModel> createAdvance({
    required int professionalId,
    required int amountCents,
    String? notes,
  }) async {
    final response =
        await _client.postQueueable(
              '/professionals/$professionalId/advances',
              body: {'amount_cents': amountCents, 'notes': ?notes},
              description: 'Adiantamento — lançamento',
            )
            as Map<String, dynamic>;

    return ProfessionalAdvanceModel.fromJson(response);
  }

  /// Ajustes pontuais do proprio horario por data (`GET
  /// /me/professional/schedule-overrides`), sem alterar o horario recorrente.
  Future<List<ProfessionalScheduleOverrideModel>> myScheduleOverrides() async {
    final response =
        await _client.get('/me/professional/schedule-overrides')
            as List<dynamic>;

    return response
        .map(
          (json) => ProfessionalScheduleOverrideModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Cria/atualiza (upsert por data) um ajuste pontual do proprio horario
  /// (`POST /me/professional/schedule-overrides`). `isOff` marca que o
  /// profissional nao vai trabalhar naquele dia; caso contrario, `startsAt`
  /// e `endsAt` (formato `HH:mm`) sao obrigatorios.
  Future<ProfessionalScheduleOverrideModel> createMyScheduleOverride({
    required DateTime date,
    bool isOff = false,
    String? startsAt,
    String? endsAt,
  }) async {
    final response =
        await _client.post(
              '/me/professional/schedule-overrides',
              body: {
                'date': date.toIso8601String().split('T').first,
                'is_off': isOff,
                'starts_at': ?startsAt,
                'ends_at': ?endsAt,
              },
            )
            as Map<String, dynamic>;

    return ProfessionalScheduleOverrideModel.fromJson(response);
  }

  Future<void> deleteMyScheduleOverride(int id) {
    return _client.delete('/me/professional/schedule-overrides/$id');
  }
}
