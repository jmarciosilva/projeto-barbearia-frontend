import 'package:clube_do_salao/models/appointment_model.dart';
import 'package:clube_do_salao/services/api_client.dart';

class AppointmentsRepository {
  const AppointmentsRepository(this._client);

  final ApiClient _client;

  Future<List<AppointmentModel>> index({DateTime? from, DateTime? to}) async {
    final response =
        await _client.get(
              '/appointments',
              query: {
                'from': ?from?.toIso8601String(),
                'to': ?to?.toIso8601String(),
              },
            )
            as List<dynamic>;

    return response
        .map(
          (json) => AppointmentModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  /// Agenda do salao inteiro (`GET /appointments/salon`), sem dado de outro
  /// cliente: usada pelo cliente para se programar antes de escolher entre
  /// agendar direto ou entrar na fila de espera. O backend ja omite o
  /// cliente de cada agendamento, entao `clientName` sempre vem nulo aqui.
  Future<List<AppointmentModel>> salonSchedule({
    DateTime? from,
    DateTime? to,
  }) async {
    final response =
        await _client.get(
              '/appointments/salon',
              query: {
                'from': ?from?.toIso8601String(),
                'to': ?to?.toIso8601String(),
              },
            )
            as List<dynamic>;

    return response
        .map(
          (json) => AppointmentModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  /// Marca um atendimento como concluido (`POST /appointments/{id}/complete`).
  /// Profissional so consegue concluir os proprios; o backend recusa o resto.
  Future<AppointmentModel> complete(int appointmentId) async {
    final response =
        await _client.post('/appointments/$appointmentId/complete')
            as Map<String, dynamic>;

    return AppointmentModel.fromJson(response);
  }

  /// Cancela um agendamento (`PATCH /appointments/{id}`). Cliente so pode
  /// cancelar o proprio; dono/profissional podem cancelar qualquer um.
  Future<AppointmentModel> cancel(int appointmentId) async {
    final response =
        await _client.patch(
              '/appointments/$appointmentId',
              body: {'status': 'canceled'},
            )
            as Map<String, dynamic>;

    return AppointmentModel.fromJson(response);
  }

  /// Remarca um agendamento para um novo horario (`PATCH /appointments/{id}`).
  Future<AppointmentModel> reschedule(
    int appointmentId,
    DateTime startsAt,
  ) async {
    final response =
        await _client.patch(
              '/appointments/$appointmentId',
              body: {'starts_at': startsAt.toIso8601String()},
            )
            as Map<String, dynamic>;

    return AppointmentModel.fromJson(response);
  }

  /// Cria um agendamento (`POST /appointments`). Quando quem chama e um
  /// `customer`, o backend ignora o `clientId` enviado e usa o proprio
  /// cliente vinculado ao login — o parametro fica so para o caso de
  /// proprietario/profissional agendarem em nome de um cliente.
  Future<AppointmentModel> create({
    required int clientId,
    required int professionalId,
    required int serviceId,
    required DateTime startsAt,
    int? clientSubscriptionId,
    String? notes,
  }) async {
    final response =
        await _client.post(
              '/appointments',
              body: {
                'client_id': clientId,
                'professional_id': professionalId,
                'service_id': serviceId,
                'starts_at': startsAt.toIso8601String(),
                'client_subscription_id': ?clientSubscriptionId,
                'notes': ?notes,
              },
            )
            as Map<String, dynamic>;

    return AppointmentModel.fromJson(response);
  }
}
