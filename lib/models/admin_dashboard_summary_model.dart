/// Resumo da plataforma como um todo (roadmap Fase 5, `GET /admin/dashboard`)
/// — visao do administrador, nao de um estabelecimento especifico.
class AdminDashboardSummaryModel {
  const AdminDashboardSummaryModel({
    required this.totalTenants,
    required this.activeTenants,
    required this.trialTenants,
    required this.expiredTenants,
    required this.founderTenants,
    required this.projectedRevenueCents,
    required this.totalUsers,
  });

  factory AdminDashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardSummaryModel(
      totalTenants: json['total_tenants'] as int,
      activeTenants: json['active_tenants'] as int,
      trialTenants: json['trial_tenants'] as int,
      expiredTenants: json['expired_tenants'] as int,
      founderTenants: json['founder_tenants'] as int,
      projectedRevenueCents: json['projected_revenue_cents'] as int,
      totalUsers: json['total_users'] as int,
    );
  }

  final int totalTenants;
  final int activeTenants;
  final int trialTenants;
  final int expiredTenants;
  final int founderTenants;
  final int projectedRevenueCents;
  final int totalUsers;
}
