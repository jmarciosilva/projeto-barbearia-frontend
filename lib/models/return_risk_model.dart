class ReturnRiskEntryModel {
  const ReturnRiskEntryModel({
    required this.clientId,
    required this.clientName,
    required this.lastVisitAt,
    required this.avgIntervalDays,
    required this.daysSinceLast,
    required this.probability,
  });

  factory ReturnRiskEntryModel.fromJson(Map<String, dynamic> json) {
    return ReturnRiskEntryModel(
      clientId: json['client_id'] as int,
      clientName: json['client_name'] as String,
      lastVisitAt: json['last_visit_at'] as String,
      avgIntervalDays: json['avg_interval_days'] as int,
      daysSinceLast: json['days_since_last'] as int,
      probability: json['probability'] as String,
    );
  }

  final int clientId;
  final String clientName;
  final String lastVisitAt;
  final int avgIntervalDays;
  final int daysSinceLast;
  final String probability;
}
