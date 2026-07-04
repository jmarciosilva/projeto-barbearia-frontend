/// Tier pago do SaaS (Basico, Intermediario ou Premium). `null` num limite
/// significa ilimitado (spec, secao 3).
class SaasPlanModel {
  const SaasPlanModel({
    required this.code,
    required this.name,
    required this.priceCents,
    this.maxProfessionals,
    this.maxClientSubscriptions,
    this.maxUnits,
  });

  factory SaasPlanModel.fromJson(Map<String, dynamic> json) {
    return SaasPlanModel(
      code: json['code'] as String,
      name: json['name'] as String,
      priceCents: json['price_cents'] as int,
      maxProfessionals: json['max_professionals'] as int?,
      maxClientSubscriptions: json['max_client_subscriptions'] as int?,
      maxUnits: json['max_units'] as int?,
    );
  }

  final String code;
  final String name;
  final int priceCents;
  final int? maxProfessionals;
  final int? maxClientSubscriptions;
  final int? maxUnits;

  String get limitsLabel {
    final professionals = maxProfessionals == null
        ? 'profissionais ilimitados'
        : 'ate $maxProfessionals profissionais';
    final clients = maxClientSubscriptions == null
        ? 'assinantes ilimitados'
        : 'ate $maxClientSubscriptions assinantes';

    return '$professionals - $clients';
  }
}
