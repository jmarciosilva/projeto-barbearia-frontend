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

  /// Registra um pagamento novo, avulso ou de assinatura (`clientSubscriptionId`).
  /// Usado para dar entrada no pagamento de uma assinatura que ainda nao tem
  /// nenhum registro de cobranca (ex: assinante antigo, ou renovacao do mes).
  Future<PaymentModel> create({
    int? clientSubscriptionId,
    int? clientId,
    required int amountCents,
    String? status,
  }) async {
    final response =
        await _client.post(
              '/payments',
              body: {
                'client_subscription_id': clientSubscriptionId,
                'client_id': clientId,
                'amount_cents': amountCents,
                'status': status,
              },
            )
            as Map<String, dynamic>;

    return PaymentModel.fromJson(response);
  }

  /// Confirma a forma de pagamento usada na maquininha do salao (roadmap:
  /// enfileiravel offline — so registra o que ja foi cobrado fisicamente,
  /// nao processa nenhuma cobranca de verdade).
  Future<PaymentModel> markPaid(int paymentId, {required String method}) async {
    final response =
        await _client.postQueueable(
              '/payments/$paymentId/mark-paid',
              body: {'method': method},
              description: 'Pagamento — confirmação',
            )
            as Map<String, dynamic>;

    return PaymentModel.fromJson(response);
  }

  /// Recebimento parcial de um pagamento em aberto (ex: fiado). Enfileiravel
  /// offline (ver `markPaid`).
  Future<PaymentModel> receive(
    int paymentId, {
    required int amountCents,
    required String method,
  }) async {
    final response =
        await _client.postQueueable(
              '/payments/$paymentId/receipts',
              body: {'amount_cents': amountCents, 'method': method},
              description: 'Pagamento — recebimento',
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

  /// Corrige um lancamento ja confirmado (valor/metodo/observacao digitados
  /// errado, ex: dono lancou o mesmo pagamento duas vezes). NAO enfileiravel
  /// offline de proposito — e uma correcao de registro financeiro, nao deve
  /// ficar reenviando sozinha depois sem o dono ver o resultado na hora
  /// (mesmo padrao ja usado por `deleteScheduleOverride`).
  Future<PaymentModel> update({
    required int id,
    int? amountCents,
    String? method,
    String? notes,
  }) async {
    final response =
        await _client.patch(
              '/payments/$id',
              body: {
                'amount_cents': ?amountCents,
                'method': ?method,
                'notes': ?notes,
              },
            )
            as Map<String, dynamic>;

    return PaymentModel.fromJson(response);
  }

  /// Remove um lancamento errado. Ver `update` sobre nao ser enfileiravel.
  Future<void> delete(int id) => _client.delete('/payments/$id');
}
