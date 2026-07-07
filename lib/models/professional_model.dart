class ProfessionalWorkingHourModel {
  const ProfessionalWorkingHourModel({
    required this.weekday,
    required this.startsAt,
    required this.endsAt,
  });

  factory ProfessionalWorkingHourModel.fromJson(Map<String, dynamic> json) {
    return ProfessionalWorkingHourModel(
      weekday: json['weekday'] as int,
      startsAt: (json['starts_at'] as String).substring(0, 5),
      endsAt: (json['ends_at'] as String).substring(0, 5),
    );
  }

  Map<String, dynamic> toJson() => {
    'weekday': weekday,
    'starts_at': startsAt,
    'ends_at': endsAt,
  };

  final int weekday;
  final String startsAt;
  final String endsAt;
}

class ProfessionalModel {
  const ProfessionalModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.specialty,
    this.commissionPercentage,
    this.isActive = true,
    this.userId,
    this.serviceIds = const [],
    this.workingHours = const [],
  });

  factory ProfessionalModel.fromJson(Map<String, dynamic> json) {
    final servicesJson = json['services'] as List<dynamic>? ?? const [];
    final workingHoursJson =
        json['working_hours'] as List<dynamic>? ?? const [];

    return ProfessionalModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      specialty: json['specialty'] as String?,
      commissionPercentage: json['commission_percentage'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      userId: json['user_id'] as int?,
      serviceIds: servicesJson
          .map((service) => (service as Map<String, dynamic>)['id'] as int)
          .toList(),
      workingHours: workingHoursJson
          .map(
            (workingHour) => ProfessionalWorkingHourModel.fromJson(
              workingHour as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? specialty;
  final int? commissionPercentage;
  final bool isActive;
  final int? userId;
  final List<int> serviceIds;
  final List<ProfessionalWorkingHourModel> workingHours;
}
