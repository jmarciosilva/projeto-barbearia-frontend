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
}
