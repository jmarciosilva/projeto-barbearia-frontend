/// Servico incluso em um plano, com os dados do pivot (`included_quantity`,
/// `discount_percentage`) alem dos dados do proprio servico.
class PlanServiceModel {
  const PlanServiceModel({
    required this.id,
    required this.name,
    this.includedQuantity,
    this.discountPercentage,
  });

  factory PlanServiceModel.fromJson(Map<String, dynamic> json) {
    final pivot = json['pivot'] as Map<String, dynamic>?;

    return PlanServiceModel(
      id: json['id'] as int,
      name: json['name'] as String,
      includedQuantity: pivot?['included_quantity'] as int?,
      discountPercentage: pivot?['discount_percentage'] as int?,
    );
  }

  final int id;
  final String name;
  final int? includedQuantity;
  final int? discountPercentage;
}

class SubscriptionPlanModel {
  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.priceCents,
    this.description,
    this.usageLimit,
    this.allowedWeekdays,
    this.allowedStartTime,
    this.allowedEndTime,
    this.isActive = true,
    this.services = const [],
    this.professionalIds = const [],
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    final servicesJson = json['services'] as List<dynamic>? ?? const [];
    final professionalsJson = json['professionals'] as List<dynamic>? ?? const [];

    return SubscriptionPlanModel(
      id: json['id'] as int,
      name: json['name'] as String,
      priceCents: json['price_cents'] as int,
      description: json['description'] as String?,
      usageLimit: json['usage_limit'] as int?,
      allowedWeekdays: (json['allowed_weekdays'] as List<dynamic>?)
          ?.map((day) => day as int)
          .toList(),
      allowedStartTime: json['allowed_start_time'] as String?,
      allowedEndTime: json['allowed_end_time'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      services: servicesJson
          .map((service) => PlanServiceModel.fromJson(service as Map<String, dynamic>))
          .toList(),
      professionalIds: professionalsJson
          .map((professional) => (professional as Map<String, dynamic>)['id'] as int)
          .toList(),
    );
  }

  final int id;
  final String name;
  final int priceCents;
  final String? description;
  final int? usageLimit;
  final List<int>? allowedWeekdays;
  final String? allowedStartTime;
  final String? allowedEndTime;
  final bool isActive;
  final List<PlanServiceModel> services;
  final List<int> professionalIds;

  String get usageLimitLabel =>
      usageLimit == null ? 'Uso ilimitado' : '$usageLimit usos mensais';
}
