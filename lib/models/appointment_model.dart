class AppointmentModel {
  const AppointmentModel({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    this.clientId,
    this.professionalId,
    this.serviceId,
    this.clientSubscriptionId,
    this.cancellationReason,
    this.notes,
    this.clientName,
    this.professionalName,
    this.serviceName,
    this.servicePriceCents,
    this.paymentId,
    this.paymentAmountCents,
    this.paymentStatus,
    this.paymentMethod,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    final professional = json['professional'] as Map<String, dynamic>?;
    final service = json['service'] as Map<String, dynamic>?;
    final payment = json['payment'] as Map<String, dynamic>?;

    return AppointmentModel(
      id: json['id'] as int,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
      status: json['status'] as String,
      clientId: json['client_id'] as int?,
      professionalId: json['professional_id'] as int?,
      serviceId: json['service_id'] as int?,
      clientSubscriptionId: json['client_subscription_id'] as int?,
      cancellationReason: json['cancellation_reason'] as String?,
      notes: json['notes'] as String?,
      clientName: client?['name'] as String?,
      professionalName: professional?['name'] as String?,
      serviceName: service?['name'] as String?,
      servicePriceCents: service?['price_cents'] as int?,
      paymentId: payment?['id'] as int?,
      paymentAmountCents: payment?['amount_cents'] as int?,
      paymentStatus: payment?['status'] as String?,
      paymentMethod: payment?['method'] as String?,
    );
  }

  final int id;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
  final int? clientId;
  final int? professionalId;
  final int? serviceId;
  final int? clientSubscriptionId;
  final String? cancellationReason;
  final String? notes;
  final String? clientName;
  final String? professionalName;
  final String? serviceName;
  final int? servicePriceCents;
  final int? paymentId;
  final int? paymentAmountCents;
  final String? paymentStatus;
  final String? paymentMethod;

  /// Contribuicao deste agendamento para a receita prevista do dia (spec
  /// Painel Inteligente): agendamentos cancelados/no-show nao geram receita.
  bool get countsTowardExpectedRevenue =>
      status != 'canceled' && status != 'no_show';
}
