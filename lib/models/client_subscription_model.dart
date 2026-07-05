import 'package:clube_do_salao/models/subscription_plan_model.dart';
import 'package:clube_do_salao/models/payment_model.dart';

/// Um uso registrado de uma assinatura (atendimento concluido que consumiu
/// o plano), usado no historico de uso real da tela do cliente.
class SubscriptionUsageModel {
  const SubscriptionUsageModel({required this.usedAt, this.serviceName});

  factory SubscriptionUsageModel.fromJson(Map<String, dynamic> json) {
    final service = json['service'] as Map<String, dynamic>?;

    return SubscriptionUsageModel(
      usedAt: DateTime.parse(json['used_at'] as String),
      serviceName: service?['name'] as String?,
    );
  }

  final DateTime usedAt;
  final String? serviceName;
}

class ClientSubscriptionModel {
  const ClientSubscriptionModel({
    required this.id,
    required this.clientId,
    required this.subscriptionPlanId,
    required this.status,
    required this.paymentStatus,
    this.startsOn,
    this.renewsOn,
    this.endsOn,
    this.lastPaymentAt,
    this.notes,
    this.plan,
    this.clientName,
    this.usages = const [],
    this.payments = const [],
  });

  factory ClientSubscriptionModel.fromJson(Map<String, dynamic> json) {
    final planJson = json['plan'] as Map<String, dynamic>?;
    final clientJson = json['client'] as Map<String, dynamic>?;
    final usagesJson = json['usages'] as List<dynamic>? ?? const [];
    final paymentsJson = json['payments'] as List<dynamic>? ?? const [];

    return ClientSubscriptionModel(
      id: json['id'] as int,
      clientId: json['client_id'] as int,
      subscriptionPlanId: json['subscription_plan_id'] as int,
      status: json['status'] as String,
      paymentStatus: json['payment_status'] as String,
      startsOn: json['starts_on'] as String?,
      renewsOn: json['renews_on'] as String?,
      endsOn: json['ends_on'] as String?,
      lastPaymentAt: json['last_payment_at'] as String?,
      notes: json['notes'] as String?,
      plan: planJson == null ? null : SubscriptionPlanModel.fromJson(planJson),
      clientName: clientJson?['name'] as String?,
      usages: usagesJson
          .map(
            (usage) =>
                SubscriptionUsageModel.fromJson(usage as Map<String, dynamic>),
          )
          .toList(),
      payments: paymentsJson
          .map(
            (payment) => PaymentModel.fromJson(payment as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final int id;
  final int clientId;
  final int subscriptionPlanId;
  final String status;
  final String paymentStatus;
  final String? startsOn;
  final String? renewsOn;
  final String? endsOn;
  final String? lastPaymentAt;
  final String? notes;
  final SubscriptionPlanModel? plan;
  final String? clientName;
  final List<SubscriptionUsageModel> usages;
  final List<PaymentModel> payments;

  String get paymentStatusLabel => switch (paymentStatus) {
    'paid' => 'Pagamento pago',
    'overdue' => 'Pagamento atrasado',
    _ => 'Pagamento pendente',
  };

  /// Quantos usos ja foram registrados no mes corrente (mesma convencao do
  /// backend: contado por mes calendario).
  int usagesThisMonth([DateTime? now]) {
    final reference = now ?? DateTime.now();

    return usages
        .where(
          (usage) =>
              usage.usedAt.year == reference.year &&
              usage.usedAt.month == reference.month,
        )
        .length;
  }
}
