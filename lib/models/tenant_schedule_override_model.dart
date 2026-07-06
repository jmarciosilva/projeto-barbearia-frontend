/// Excecao pontual ao horario padrao do estabelecimento para uma data
/// especifica (ex: fechar mais cedo, ou fechar o dia inteiro). Ver
/// `TenantRepository` e `CreatesAppointments::assertWithinBusinessHours` no
/// backend.
class TenantScheduleOverrideModel {
  const TenantScheduleOverrideModel({
    required this.id,
    required this.date,
    required this.isClosed,
    this.opensAt,
    this.closesAt,
  });

  factory TenantScheduleOverrideModel.fromJson(Map<String, dynamic> json) {
    return TenantScheduleOverrideModel(
      id: json['id'] as int,
      date: DateTime.parse(json['date'] as String),
      isClosed: json['is_closed'] as bool? ?? false,
      opensAt: json['opens_at'] as String?,
      closesAt: json['closes_at'] as String?,
    );
  }

  final int id;
  final DateTime date;
  final bool isClosed;
  final String? opensAt;
  final String? closesAt;
}
