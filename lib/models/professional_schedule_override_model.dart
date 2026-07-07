class ProfessionalScheduleOverrideModel {
  const ProfessionalScheduleOverrideModel({
    required this.id,
    required this.date,
    required this.isOff,
    this.startsAt,
    this.endsAt,
  });

  factory ProfessionalScheduleOverrideModel.fromJson(Map<String, dynamic> json) {
    return ProfessionalScheduleOverrideModel(
      id: json['id'] as int,
      date: json['date'] as String,
      isOff: json['is_off'] as bool? ?? false,
      startsAt: json['starts_at'] as String?,
      endsAt: json['ends_at'] as String?,
    );
  }

  final int id;
  final String date;
  final bool isOff;
  final String? startsAt;
  final String? endsAt;
}
