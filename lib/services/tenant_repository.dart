import 'package:clube_do_salao/models/tenant_model.dart';
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
}
