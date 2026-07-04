import 'package:clube_do_salao/models/saas_plan_model.dart';
import 'package:clube_do_salao/models/tenant_model.dart';
import 'package:clube_do_salao/services/api_client.dart';

class SaasSubscriptionRepository {
  const SaasSubscriptionRepository(this._client);

  final ApiClient _client;

  Future<List<SaasPlanModel>> plans() async {
    final response = await _client.get('/saas-plans') as List<dynamic>;

    return response
        .map((json) => SaasPlanModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<TenantModel> switchPlan(String planCode) async {
    final response =
        await _client.patch(
              '/saas-subscription',
              body: {'plan_code': planCode},
            )
            as Map<String, dynamic>;

    return TenantModel.fromJson(response);
  }
}
