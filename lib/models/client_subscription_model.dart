import 'package:clube_do_salao/models/subscription_plan_model.dart';

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
  });

  factory ClientSubscriptionModel.fromJson(Map<String, dynamic> json) {
    final planJson = json['plan'] as Map<String, dynamic>?;
    final clientJson = json['client'] as Map<String, dynamic>?;

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

  String get paymentStatusLabel => switch (paymentStatus) {
    'paid' => 'Pagamento pago',
    'overdue' => 'Pagamento atrasado',
    _ => 'Pagamento pendente',
  };
}
