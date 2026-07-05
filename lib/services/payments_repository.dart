import 'package:clube_do_salao/models/payment_model.dart';
import 'package:clube_do_salao/services/api_client.dart';

class PaymentsRepository {
  const PaymentsRepository(this._client);

  final ApiClient _client;

  Future<List<PaymentModel>> index() async {
    final response = await _client.get('/payments') as List<dynamic>;

    return response
        .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<PaymentModel> markPaid(int paymentId, {required String method}) async {
    final response =
        await _client.post(
              '/payments/$paymentId/mark-paid',
              body: {'method': method},
            )
            as Map<String, dynamic>;

    return PaymentModel.fromJson(response);
  }

  Future<PaymentModel> receive(
    int paymentId, {
    required int amountCents,
    required String method,
  }) async {
    final response =
        await _client.post(
              '/payments/$paymentId/receipts',
              body: {'amount_cents': amountCents, 'method': method},
            )
            as Map<String, dynamic>;

    return PaymentModel.fromJson(response);
  }

  Future<List<PaymentModel>> mine() async {
    final response = await _client.get('/me/payments') as List<dynamic>;

    return response
        .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
