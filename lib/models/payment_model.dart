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
    this.planName,
    this.receipts = const [],
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final subscription = json['subscription'] as Map<String, dynamic>?;
    final subscriptionClient = subscription?['client'] as Map<String, dynamic>?;
    final subscriptionPlan = subscription?['plan'] as Map<String, dynamic>?;
    final directClient = json['client'] as Map<String, dynamic>?;
    final appointment = json['appointment'] as Map<String, dynamic>?;
    final service = appointment?['service'] as Map<String, dynamic>?;
    final receiptsJson = json['receipts'] as List<dynamic>? ?? const [];

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
      clientName:
          directClient?['name'] as String? ??
          subscriptionClient?['name'] as String?,
      serviceName: service?['name'] as String?,
      planName: subscriptionPlan?['name'] as String?,
      receipts: receiptsJson
          .map(
            (receipt) =>
                PaymentReceiptModel.fromJson(receipt as Map<String, dynamic>),
          )
          .toList(),
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
  final String? planName;
  final List<PaymentReceiptModel> receipts;

  /// Pagamento avulso (agendamento sem plano) nao tem `client_subscription_id`.
  bool get isAvulso => clientSubscriptionId == null;

  String get methodLabel => switch (method) {
    'pix' => 'PIX',
    'credit_card' => 'Cartao credito',
    'debit_card' => 'Cartao debito',
    'cash' => 'Dinheiro',
    'fiado' => 'Fiado',
    _ => 'Outro',
  };

  String get statusLabel => switch (status) {
    'paid' => 'Pago',
    'overdue' => 'Atrasado',
    _ => 'Pendente',
  };

  int get receivedCents {
    final total = receipts.fold(0, (sum, receipt) => sum + receipt.amountCents);

    return status == 'paid' && total == 0 ? amountCents : total;
  }

  int get remainingCents => status == 'paid'
      ? 0
      : (amountCents - receivedCents).clamp(0, amountCents);
}

class PaymentReceiptModel {
  const PaymentReceiptModel({
    required this.id,
    required this.amountCents,
    required this.method,
    required this.receivedAt,
    this.notes,
  });

  factory PaymentReceiptModel.fromJson(Map<String, dynamic> json) {
    return PaymentReceiptModel(
      id: json['id'] as int,
      amountCents: json['amount_cents'] as int,
      method: json['method'] as String,
      receivedAt: json['received_at'] as String,
      notes: json['notes'] as String?,
    );
  }

  final int id;
  final int amountCents;
  final String method;
  final String receivedAt;
  final String? notes;

  String get methodLabel => switch (method) {
    'pix' => 'PIX',
    'credit_card' => 'Cartao credito',
    'debit_card' => 'Cartao debito',
    'cash' => 'Dinheiro',
    'fiado' => 'Fiado',
    _ => 'Outro',
  };
}
