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
  });

  factory ProfessionalModel.fromJson(Map<String, dynamic> json) {
    return ProfessionalModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      specialty: json['specialty'] as String?,
      commissionPercentage: json['commission_percentage'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      userId: json['user_id'] as int?,
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
}
