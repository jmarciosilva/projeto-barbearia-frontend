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

class ProfessionalFinanceModel {
  const ProfessionalFinanceModel({
    required this.completedCount,
    required this.grossCents,
    required this.commissionPercentage,
    required this.commissionCents,
    required this.advancesCents,
    required this.netCents,
    required this.paymentDay,
    required this.advances,
  });

  factory ProfessionalFinanceModel.fromJson(Map<String, dynamic> json) {
    final advancesJson = json['advances'] as List<dynamic>? ?? const [];

    return ProfessionalFinanceModel(
      completedCount: json['completed_count'] as int,
      grossCents: json['gross_cents'] as int,
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
    );
  }

  final int completedCount;
  final int grossCents;
  final int commissionPercentage;
  final int commissionCents;
  final int advancesCents;
  final int netCents;
  final int paymentDay;
  final List<ProfessionalAdvanceModel> advances;
}
