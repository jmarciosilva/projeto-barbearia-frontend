import 'package:clube_do_salao/models/client_subscription_model.dart';
import 'package:clube_do_salao/services/api_client.dart';

/// Contratacao/troca/cancelamento de assinatura pelo proprio cliente.
class ClientSubscriptionsRepository {
  const ClientSubscriptionsRepository(this._client);

  final ApiClient _client;

  /// Assina ou troca de plano (`POST /me/client-subscriptions`). Se ja
  /// existir assinatura ativa, o backend a cancela e cria a nova no lugar.
  Future<ClientSubscriptionModel> subscribeSelf(int subscriptionPlanId) async {
    final response =
        await _client.post(
              '/me/client-subscriptions',
              body: {'subscription_plan_id': subscriptionPlanId},
            )
            as Map<String, dynamic>;

    return ClientSubscriptionModel.fromJson(response);
  }

  /// Cancela a propria assinatura ativa (`POST /me/client-subscriptions/cancel`).
  Future<ClientSubscriptionModel> cancelSelf() async {
    final response =
        await _client.post('/me/client-subscriptions/cancel')
            as Map<String, dynamic>;

    return ClientSubscriptionModel.fromJson(response);
  }
}
