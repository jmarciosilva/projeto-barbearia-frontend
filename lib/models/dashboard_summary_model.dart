class DashboardSummaryModel {
  const DashboardSummaryModel({
    required this.appointmentsToday,
    required this.confirmedToday,
    required this.pendingToday,
    required this.canceledToday,
    required this.waitlistCount,
    required this.expectedRevenueTodayCents,
    required this.recurringRevenueMonthCents,
    required this.walkinRevenueMonthCents,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      appointmentsToday: json['appointments_today'] as int,
      confirmedToday: json['confirmed_today'] as int,
      pendingToday: json['pending_today'] as int,
      canceledToday: json['canceled_today'] as int,
      waitlistCount: json['waitlist_count'] as int,
      expectedRevenueTodayCents: json['expected_revenue_today_cents'] as int,
      recurringRevenueMonthCents:
          json['recurring_revenue_month_cents'] as int,
      walkinRevenueMonthCents: json['walkin_revenue_month_cents'] as int,
    );
  }

  final int appointmentsToday;
  final int confirmedToday;
  final int pendingToday;
  final int canceledToday;
  final int waitlistCount;
  final int expectedRevenueTodayCents;
  final int recurringRevenueMonthCents;
  final int walkinRevenueMonthCents;
}
