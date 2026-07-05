import 'package:clube_do_salao/models/saas_subscription_model.dart';

class TenantModel {
  const TenantModel({
    required this.id,
    required this.name,
    required this.saasSubscription,
    this.professionalPaymentDay = 5,
    this.inviteCode,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id'] as int,
      name: json['name'] as String,
      saasSubscription: SaasSubscriptionModel.fromJson(
        json['saas_subscription'] as Map<String, dynamic>,
      ),
      professionalPaymentDay: json['professional_payment_day'] as int? ?? 5,
      inviteCode: json['invite_code'] as String?,
    );
  }

  final int id;
  final String name;
  final SaasSubscriptionModel saasSubscription;
  final int professionalPaymentDay;

  /// Codigo que o dono compartilha (link/QR) para o cliente se autocadastrar
  /// ja vinculado a este tenant. Ver `POST /auth/register-client`.
  final String? inviteCode;
}
