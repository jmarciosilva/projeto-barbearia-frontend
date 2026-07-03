class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.amountCents,
    required this.method,
    required this.status,
    this.clientSubscriptionId,
    this.dueOn,
    this.paidAt,
    this.notes,
    this.clientName,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final subscription = json['subscription'] as Map<String, dynamic>?;
    final client = subscription?['client'] as Map<String, dynamic>?;

    return PaymentModel(
      id: json['id'] as int,
      amountCents: json['amount_cents'] as int,
      method: json['method'] as String,
      status: json['status'] as String,
      clientSubscriptionId: json['client_subscription_id'] as int?,
      dueOn: json['due_on'] as String?,
      paidAt: json['paid_at'] as String?,
      notes: json['notes'] as String?,
      clientName: client?['name'] as String?,
    );
  }

  final int id;
  final int amountCents;
  final String method;
  final String status;
  final int? clientSubscriptionId;
  final String? dueOn;
  final String? paidAt;
  final String? notes;
  final String? clientName;

  String get methodLabel => switch (method) {
    'pix' => 'PIX',
    'cash' => 'Dinheiro',
    'card' => 'Cartao',
    _ => 'Outro',
  };
}
