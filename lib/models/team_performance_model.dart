/// Desempenho de um profissional no mes corrente (roadmap Fase 4,
/// `GET /dashboard/team-performance`): mesma agregacao do extrato
/// individual do profissional, exposta pra todos de uma vez.
class TeamPerformanceEntryModel {
  const TeamPerformanceEntryModel({
    required this.professionalId,
    required this.professionalName,
    required this.completedCount,
    required this.avulsoCount,
    required this.planoCount,
    required this.grossCents,
    required this.commissionPercentage,
    required this.commissionCents,
  });

  factory TeamPerformanceEntryModel.fromJson(Map<String, dynamic> json) {
    return TeamPerformanceEntryModel(
      professionalId: json['professional_id'] as int,
      professionalName: json['professional_name'] as String,
      completedCount: json['completed_count'] as int,
      avulsoCount: json['avulso_count'] as int,
      planoCount: json['plano_count'] as int,
      grossCents: json['gross_cents'] as int,
      commissionPercentage: json['commission_percentage'] as int,
      commissionCents: json['commission_cents'] as int,
    );
  }

  final int professionalId;
  final String professionalName;
  final int completedCount;
  final int avulsoCount;
  final int planoCount;
  final int grossCents;
  final int commissionPercentage;
  final int commissionCents;
}
