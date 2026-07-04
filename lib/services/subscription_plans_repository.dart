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

  Future<SubscriptionPlanModel> create({
    required String name,
    required int priceCents,
    int? usageLimit,
    List<int>? allowedWeekdays,
    String? allowedStartTime,
    String? allowedEndTime,
    List<int> serviceIds = const [],
    List<int> professionalIds = const [],
  }) async {
    final response =
        await _client.post(
              '/subscription-plans',
              body: {
                'name': name,
                'price_cents': priceCents,
                'usage_limit': ?usageLimit,
                'allowed_weekdays': ?allowedWeekdays,
                'allowed_start_time': ?allowedStartTime,
                'allowed_end_time': ?allowedEndTime,
                'services': serviceIds
                    .map((id) => {'id': id})
                    .toList(),
                'professional_ids': professionalIds,
              },
            )
            as Map<String, dynamic>;

    return SubscriptionPlanModel.fromJson(response);
  }
}
