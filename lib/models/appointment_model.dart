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
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    final professional = json['professional'] as Map<String, dynamic>?;
    final service = json['service'] as Map<String, dynamic>?;

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
}
