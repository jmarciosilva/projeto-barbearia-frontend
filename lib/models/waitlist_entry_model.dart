/// Pedido de "atendimento no estabelecimento" de um cliente sem assinatura,
/// sem profissional nem horario fixos (ver `WaitlistRepository`).
class WaitlistEntryModel {
  const WaitlistEntryModel({
    required this.id,
    required this.status,
    required this.createdAt,
    this.serviceId,
    this.serviceName,
    this.professionalId,
    this.professionalName,
    this.clientName,
    this.notes,
    this.appointmentId,
  });

  factory WaitlistEntryModel.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    final service = json['service'] as Map<String, dynamic>?;
    final professional = json['professional'] as Map<String, dynamic>?;
    final appointment = json['appointment'] as Map<String, dynamic>?;

    return WaitlistEntryModel(
      id: json['id'] as int,
      status: json['status'] as String,
      // O backend sempre grava `created_at` (timestamps padrao do Laravel);
      // so cai no agora se faltar por algum motivo, pra nao quebrar a tela.
      createdAt: json['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['created_at'] as String),
      serviceId: json['service_id'] as int?,
      serviceName: service?['name'] as String?,
      professionalId: json['professional_id'] as int?,
      professionalName: professional?['name'] as String?,
      clientName: client?['name'] as String?,
      notes: json['notes'] as String?,
      appointmentId: appointment?['id'] as int?,
    );
  }

  final int id;
  final String status;
  final DateTime createdAt;
  final int? serviceId;
  final String? serviceName;
  final int? professionalId;
  final String? professionalName;
  final String? clientName;
  final String? notes;
  final int? appointmentId;

  String get statusLabel => switch (status) {
    'scheduled' => 'Atendimento marcado',
    'canceled' => 'Cancelado',
    _ => 'Aguardando vaga',
  };
}
