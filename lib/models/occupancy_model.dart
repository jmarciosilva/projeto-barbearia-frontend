class OccupancyDayModel {
  const OccupancyDayModel({
    required this.weekday,
    required this.date,
    required this.hasOverride,
    required this.availableMinutes,
    required this.occupiedMinutes,
    required this.percentage,
  });

  factory OccupancyDayModel.fromJson(Map<String, dynamic> json) {
    return OccupancyDayModel(
      weekday: json['weekday'] as int,
      date: json['date'] as String,
      hasOverride: json['has_override'] as bool? ?? false,
      availableMinutes: json['available_minutes'] as int,
      occupiedMinutes: json['occupied_minutes'] as int,
      percentage: json['percentage'] as int,
    );
  }

  final int weekday;
  final String date;
  final bool hasOverride;
  final int availableMinutes;
  final int occupiedMinutes;
  final int percentage;
}

class OccupancyProfessionalModel {
  const OccupancyProfessionalModel({
    required this.professionalId,
    required this.professionalName,
    required this.days,
  });

  factory OccupancyProfessionalModel.fromJson(Map<String, dynamic> json) {
    final daysJson = json['days'] as List<dynamic>? ?? const [];

    return OccupancyProfessionalModel(
      professionalId: json['professional_id'] as int,
      professionalName: json['professional_name'] as String,
      days: daysJson
          .map((day) => OccupancyDayModel.fromJson(day as Map<String, dynamic>))
          .toList(),
    );
  }

  final int professionalId;
  final String professionalName;
  final List<OccupancyDayModel> days;
}
