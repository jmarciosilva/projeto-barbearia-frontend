import 'package:clube_do_salao/models/waitlist_entry_model.dart';
import 'package:clube_do_salao/services/api_client.dart';

/// Fila de espera para atendimento avulso sem horario marcado.
class WaitlistRepository {
  const WaitlistRepository(this._client);

  final ApiClient _client;

  /// `GET /waitlist`. Cliente ve so as propias entradas; dono/profissional
  /// veem a fila inteira do estabelecimento (o backend ja aplica o recorte).
  Future<List<WaitlistEntryModel>> index({String? status}) async {
    final response =
        await _client.get('/waitlist', query: {'status': ?status})
            as List<dynamic>;

    return response
        .map(
          (json) => WaitlistEntryModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  /// Entra na fila (`POST /waitlist`). Cliente logado nunca envia
  /// `professional_id` — a fila e sempre "qualquer profissional".
  Future<WaitlistEntryModel> create({
    required int serviceId,
    String? notes,
    int? clientId,
  }) async {
    final response =
        await _client.post(
              '/waitlist',
              body: {
                'service_id': serviceId,
                'notes': ?notes,
                'client_id': ?clientId,
              },
            )
            as Map<String, dynamic>;

    return WaitlistEntryModel.fromJson(response);
  }

  /// Cancela a propria entrada, ou qualquer uma quando chamado por staff
  /// (`PATCH /waitlist/{id}`).
  Future<WaitlistEntryModel> cancel(int id) async {
    final response =
        await _client.patch('/waitlist/$id', body: {'status': 'canceled'})
            as Map<String, dynamic>;

    return WaitlistEntryModel.fromJson(response);
  }

  /// Atribui um horario vago a uma entrada da fila, exclusivo de dono e
  /// profissional (`POST /waitlist/{id}/assign`). Cria o agendamento avulso
  /// de verdade (com cobranca automatica quando o servico tem preco).
  Future<WaitlistEntryModel> assign({
    required int id,
    required DateTime startsAt,
    int? professionalId,
  }) async {
    final response =
        await _client.post(
              '/waitlist/$id/assign',
              body: {
                'professional_id': ?professionalId,
                'starts_at': startsAt.toIso8601String(),
              },
            )
            as Map<String, dynamic>;

    return WaitlistEntryModel.fromJson(response);
  }
}
