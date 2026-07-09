class ProfessionalAdvanceModel {
  const ProfessionalAdvanceModel({
    required this.id,
    required this.amountCents,
    required this.paidAt,
    this.notes,
  });

  factory ProfessionalAdvanceModel.fromJson(Map<String, dynamic> json) {
    return ProfessionalAdvanceModel(
      id: json['id'] as int,
      amountCents: json['amount_cents'] as int,
      paidAt: json['paid_at'] as String,
      notes: json['notes'] as String?,
    );
  }

  final int id;
  final int amountCents;
  final String paidAt;
  final String? notes;
}

/// Um atendimento concluido dentro do periodo do extrato (`appointments` em
/// `GET /me/professional/finance`), usado para detalhar os cards de
/// "Atendimentos"/"Avulso"/"Assinatura"/"Receita gerada" no painel do
/// profissional sem precisar de outra chamada a API.
class ProfessionalFinanceAppointmentModel {
  const ProfessionalFinanceAppointmentModel({
    required this.startsAt,
    required this.hasSubscription,
    this.serviceName,
    this.clientName,
    this.servicePriceCents,
  });

  factory ProfessionalFinanceAppointmentModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final service = json['service'] as Map<String, dynamic>?;
    final client = json['client'] as Map<String, dynamic>?;

    return ProfessionalFinanceAppointmentModel(
      startsAt: DateTime.parse(json['starts_at'] as String),
      hasSubscription: json['client_subscription_id'] != null,
      serviceName: service?['name'] as String?,
      clientName: client?['name'] as String?,
      servicePriceCents: service?['price_cents'] as int?,
    );
  }

  final DateTime startsAt;
  final bool hasSubscription;
  final String? serviceName;
  final String? clientName;
  final int? servicePriceCents;
}

class ProfessionalFinanceModel {
  const ProfessionalFinanceModel({
    required this.completedCount,
    required this.avulsoCount,
    required this.planoCount,
    required this.grossCents,
    required this.avulsoRevenueCents,
    required this.planoRevenueCents,
    required this.commissionPercentage,
    required this.commissionCents,
    required this.advancesCents,
    required this.netCents,
    required this.paymentDay,
    required this.advances,
    required this.appointments,
  });

  factory ProfessionalFinanceModel.fromJson(Map<String, dynamic> json) {
    final advancesJson = json['advances'] as List<dynamic>? ?? const [];
    final appointmentsJson = json['appointments'] as List<dynamic>? ?? const [];

    return ProfessionalFinanceModel(
      completedCount: json['completed_count'] as int,
      avulsoCount: json['avulso_count'] as int? ?? 0,
      planoCount: json['plano_count'] as int? ?? 0,
      grossCents: json['gross_cents'] as int,
      avulsoRevenueCents: json['avulso_revenue_cents'] as int? ?? 0,
      planoRevenueCents: json['plano_revenue_cents'] as int? ?? 0,
      commissionPercentage: json['commission_percentage'] as int,
      commissionCents: json['commission_cents'] as int,
      advancesCents: json['advances_cents'] as int,
      netCents: json['net_cents'] as int,
      paymentDay: json['payment_day'] as int,
      advances: advancesJson
          .map(
            (advance) => ProfessionalAdvanceModel.fromJson(
              advance as Map<String, dynamic>,
            ),
          )
          .toList(),
      appointments: appointmentsJson
          .map(
            (appointment) => ProfessionalFinanceAppointmentModel.fromJson(
              appointment as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  final int completedCount;
  final int avulsoCount;
  final int planoCount;
  final int grossCents;
  final int avulsoRevenueCents;
  final int planoRevenueCents;
  final int commissionPercentage;
  final int commissionCents;
  final int advancesCents;
  final int netCents;
  final int paymentDay;
  final List<ProfessionalAdvanceModel> advances;
  final List<ProfessionalFinanceAppointmentModel> appointments;
}
