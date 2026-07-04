class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.amountCents,
    required this.method,
    required this.status,
    this.clientSubscriptionId,
    this.appointmentId,
    this.dueOn,
    this.paidAt,
    this.notes,
    this.clientName,
    this.serviceName,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final subscription = json['subscription'] as Map<String, dynamic>?;
    final subscriptionClient = subscription?['client'] as Map<String, dynamic>?;
    final directClient = json['client'] as Map<String, dynamic>?;
    final appointment = json['appointment'] as Map<String, dynamic>?;
    final service = appointment?['service'] as Map<String, dynamic>?;

    return PaymentModel(
      id: json['id'] as int,
      amountCents: json['amount_cents'] as int,
      method: json['method'] as String,
      status: json['status'] as String,
      clientSubscriptionId: json['client_subscription_id'] as int?,
      appointmentId: json['appointment_id'] as int?,
      dueOn: json['due_on'] as String?,
      paidAt: json['paid_at'] as String?,
      notes: json['notes'] as String?,
      clientName: directClient?['name'] as String? ?? subscriptionClient?['name'] as String?,
      serviceName: service?['name'] as String?,
    );
  }

  final int id;
  final int amountCents;
  final String method;
  final String status;
  final int? clientSubscriptionId;
  final int? appointmentId;
  final String? dueOn;
  final String? paidAt;
  final String? notes;
  final String? clientName;
  final String? serviceName;

  /// Pagamento avulso (agendamento sem plano) nao tem `client_subscription_id`.
  bool get isAvulso => clientSubscriptionId == null;

  String get methodLabel => switch (method) {
    'pix' => 'PIX',
    'cash' => 'Dinheiro',
    'card' => 'Cartao',
    _ => 'Outro',
  };
}
