import 'package:clube_do_salao/models/tenant_model.dart';
import 'package:clube_do_salao/models/tenant_schedule_override_model.dart';
import 'package:clube_do_salao/services/api_client.dart';

class TenantRepository {
  const TenantRepository(this._client);

  final ApiClient _client;

  Future<TenantModel> show() async {
    final response = await _client.get('/tenant') as Map<String, dynamic>;

    return TenantModel.fromJson(response);
  }

  Future<TenantModel> updateProfessionalPaymentDay(int day) async {
    final response =
        await _client.patch('/tenant', body: {'professional_payment_day': day})
            as Map<String, dynamic>;

    return TenantModel.fromJson(response);
  }

  /// Troca o codigo de convite do proprio estabelecimento, invalidando o
  /// anterior. Exclusivo do dono.
  Future<TenantModel> regenerateInviteCode() async {
    final response =
        await _client.post('/tenant/invite-code/regenerate')
            as Map<String, dynamic>;

    return TenantModel.fromJson(response);
  }

  /// Horario de funcionamento padrao e pausa (ex: almoco). Cada campo e
  /// "HH:mm" ou nulo para limpar (fechar/pausa deixa de estar configurada).
  Future<TenantModel> updateBusinessHours({
    String? openingTime,
    String? closingTime,
    String? breakStartTime,
    String? breakEndTime,
  }) async {
    final response =
        await _client.patch(
              '/tenant',
              body: {
                'opening_time': openingTime,
                'closing_time': closingTime,
                'break_start_time': breakStartTime,
                'break_end_time': breakEndTime,
              },
            )
            as Map<String, dynamic>;

    return TenantModel.fromJson(response);
  }

  Future<List<TenantScheduleOverrideModel>> listScheduleOverrides() async {
    final response =
        await _client.get('/tenant/schedule-overrides') as List<dynamic>;

    return response
        .map(
          (json) =>
              TenantScheduleOverrideModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  Future<TenantScheduleOverrideModel> createScheduleOverride({
    required DateTime date,
    bool isClosed = false,
    String? opensAt,
    String? closesAt,
  }) async {
    final response =
        await _client.post(
              '/tenant/schedule-overrides',
              body: {
                'date': date.toIso8601String().split('T').first,
                'is_closed': isClosed,
                'opens_at': opensAt,
                'closes_at': closesAt,
              },
            )
            as Map<String, dynamic>;

    return TenantScheduleOverrideModel.fromJson(response);
  }

  Future<void> deleteScheduleOverride(int id) {
    return _client.delete('/tenant/schedule-overrides/$id');
  }
}
