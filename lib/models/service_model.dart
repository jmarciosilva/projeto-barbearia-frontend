class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.name,
    required this.durationMinutes,
    this.priceCents,
    this.description,
    this.isActive = true,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as int,
      name: json['name'] as String,
      durationMinutes: json['duration_minutes'] as int,
      priceCents: json['price_cents'] as int?,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  final int id;
  final String name;
  final int durationMinutes;
  final int? priceCents;
  final String? description;
  final bool isActive;
}
