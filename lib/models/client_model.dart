import 'package:clube_do_salao/models/client_subscription_model.dart';

class ClientModel {
  const ClientModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.birthDate,
    this.status = 'active',
    this.notes,
    this.userId,
    this.createdAt,
    this.subscriptions = const [],
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    final subscriptionsJson = json['subscriptions'] as List<dynamic>? ?? const [];

    return ClientModel(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      birthDate: json['birth_date'] as String?,
      status: json['status'] as String? ?? 'active',
      notes: json['notes'] as String?,
      userId: json['user_id'] as int?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      subscriptions: subscriptionsJson
          .map((item) => ClientSubscriptionModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final int id;
  final String name;
  final String phone;
  final String? email;
  final String? birthDate;
  final String status;
  final String? notes;
  final int? userId;
  final DateTime? createdAt;
  final List<ClientSubscriptionModel> subscriptions;

  /// Assinatura mais recente do cliente, usada nas listas e no detalhe.
  ClientSubscriptionModel? get activeSubscription =>
      subscriptions.isEmpty ? null : subscriptions.first;
}
