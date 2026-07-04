import 'package:clube_do_salao/models/saas_plan_model.dart';

/// Contagem de uso/limite de um recurso do plano SaaS. `null` significa
/// ilimitado quando usado como limite.
class SaasPlanCounters {
  const SaasPlanCounters({this.professionals, this.clientSubscriptions, this.units});

  factory SaasPlanCounters.fromJson(Map<String, dynamic> json) {
    return SaasPlanCounters(
      professionals: json['professionals'] as int?,
      clientSubscriptions: json['client_subscriptions'] as int?,
      units: json['units'] as int?,
    );
  }

  final int? professionals;
  final int? clientSubscriptions;
  final int? units;
}

/// Assinatura do estabelecimento com o SaaS (trial ou um dos 3 tiers pagos).
class SaasSubscriptionModel {
  const SaasSubscriptionModel({
    required this.status,
    required this.effectiveStatus,
    required this.planName,
    required this.priceCents,
    required this.limits,
    required this.usage,
    this.trialDaysRemaining,
    this.plan,
  });

  factory SaasSubscriptionModel.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'] as Map<String, dynamic>?;

    return SaasSubscriptionModel(
      status: json['status'] as String,
      effectiveStatus: json['effective_status'] as String,
      trialDaysRemaining: json['trial_days_remaining'] as int?,
      planName: json['plan_name'] as String,
      priceCents: json['price_cents'] as int,
      plan: plan == null ? null : SaasPlanModel.fromJson(plan),
      limits: SaasPlanCounters.fromJson(
        json['limits'] as Map<String, dynamic>? ?? const {},
      ),
      usage: SaasPlanCounters.fromJson(
        json['usage'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  final String status;
  final String effectiveStatus;
  final int? trialDaysRemaining;
  final String planName;
  final int priceCents;
  final SaasPlanModel? plan;
  final SaasPlanCounters limits;
  final SaasPlanCounters usage;

  bool get isTrial => status == 'trial';
  bool get isExpired => effectiveStatus == 'trial_expired';
}
