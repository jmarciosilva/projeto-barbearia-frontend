import 'package:clube_do_salao/models/service_model.dart';
import 'package:clube_do_salao/services/api_client.dart';

class ServicesRepository {
  const ServicesRepository(this._client);

  final ApiClient _client;

  Future<List<ServiceModel>> index() async {
    final response = await _client.get('/services') as List<dynamic>;

    return response
        .map((json) => ServiceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Enfileiravel offline (roadmap): cadastro de catalogo, nao disputa um
  /// horario de agenda.
  Future<ServiceModel> create({
    required String name,
    required int durationMinutes,
    int? priceCents,
    String? description,
  }) async {
    final response =
        await _client.postQueueable(
              '/services',
              body: {
                'name': name,
                'duration_minutes': durationMinutes,
                'price_cents': ?priceCents,
                'description': ?description,
              },
              description: "Serviço '$name' — cadastro",
            )
            as Map<String, dynamic>;

    return ServiceModel.fromJson(response);
  }

  /// Edicao de um servico pelo proprietario (`PATCH /services/{id}`).
  /// Enfileiravel offline (ver `create`).
  Future<ServiceModel> update({
    required int id,
    String? name,
    int? durationMinutes,
    int? priceCents,
    String? description,
    bool? isActive,
  }) async {
    final response =
        await _client.patchQueueable(
              '/services/$id',
              body: {
                'name': ?name,
                'duration_minutes': ?durationMinutes,
                'price_cents': ?priceCents,
                'description': ?description,
                'is_active': ?isActive,
              },
              description: name != null
                  ? "Serviço '$name' — edição"
                  : 'Serviço — edição',
            )
            as Map<String, dynamic>;

    return ServiceModel.fromJson(response);
  }
}
