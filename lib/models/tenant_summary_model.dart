/// Dado publico e minimo de um estabelecimento, usado antes do cliente ter
/// qualquer token: diretorio (`GET /tenants/directory`) e confirmacao de
/// convite (`GET /tenants/by-invite-code/{code}`).
class TenantSummaryModel {
  const TenantSummaryModel({
    required this.id,
    required this.name,
    required this.businessType,
    this.city,
  });

  factory TenantSummaryModel.fromJson(Map<String, dynamic> json) {
    return TenantSummaryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      businessType: json['business_type'] as String,
      city: json['city'] as String?,
    );
  }

  final int id;
  final String name;
  final String businessType;
  final String? city;
}
