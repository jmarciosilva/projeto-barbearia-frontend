import 'package:clube_do_salao/models/subscription_plan_model.dart';
import 'package:clube_do_salao/services/api_client.dart';

class SubscriptionPlansRepository {
  const SubscriptionPlansRepository(this._client);

  final ApiClient _client;

  Future<List<SubscriptionPlanModel>> index() async {
    final response = await _client.get('/subscription-plans') as List<dynamic>;

    return response
        .map(
          (json) =>
              SubscriptionPlanModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  /// Enfileiravel offline (roadmap): cadastro de plano, nao disputa um
  /// horario de agenda.
  Future<SubscriptionPlanModel> create({
    required String name,
    required int priceCents,
    String? description,
    int? usageLimit,
    List<int>? allowedWeekdays,
    String? allowedStartTime,
    String? allowedEndTime,
    List<int> serviceIds = const [],
    List<int> professionalIds = const [],
  }) async {
    final response =
        await _client.postQueueable(
              '/subscription-plans',
              body: {
                'name': name,
                'price_cents': priceCents,
                'description': ?description,
                'usage_limit': ?usageLimit,
                'allowed_weekdays': ?allowedWeekdays,
                'allowed_start_time': ?allowedStartTime,
                'allowed_end_time': ?allowedEndTime,
                'services': serviceIds
                    .map((id) => {'id': id})
                    .toList(),
                'professional_ids': professionalIds,
              },
              description: "Plano '$name' — cadastro",
            )
            as Map<String, dynamic>;

    return SubscriptionPlanModel.fromJson(response);
  }

  /// Edicao de um plano pelo proprietario (`PATCH /subscription-plans/{id}`),
  /// incluindo servicos e profissionais habilitados. Enfileiravel offline
  /// (ver `create`).
  Future<SubscriptionPlanModel> update({
    required int id,
    String? name,
    int? priceCents,
    String? description,
    int? usageLimit,
    bool? isActive,
    List<int>? serviceIds,
    List<int>? professionalIds,
  }) async {
    final response =
        await _client.patchQueueable(
              '/subscription-plans/$id',
              body: {
                'name': ?name,
                'price_cents': ?priceCents,
                'description': ?description,
                'usage_limit': ?usageLimit,
                'is_active': ?isActive,
                'services': ?serviceIds?.map((serviceId) => {'id': serviceId}).toList(),
                'professional_ids': ?professionalIds,
              },
              description: name != null
                  ? "Plano '$name' — edição"
                  : 'Plano — edição',
            )
            as Map<String, dynamic>;

    return SubscriptionPlanModel.fromJson(response);
  }
}
