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

  Future<ServiceModel> create({
    required String name,
    required int durationMinutes,
    int? priceCents,
    String? description,
  }) async {
    final response =
        await _client.post(
              '/services',
              body: {
                'name': name,
                'duration_minutes': durationMinutes,
                'price_cents': ?priceCents,
                'description': ?description,
              },
            )
            as Map<String, dynamic>;

    return ServiceModel.fromJson(response);
  }
}
