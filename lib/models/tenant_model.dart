import 'package:clube_do_salao/models/saas_subscription_model.dart';

class TenantModel {
  const TenantModel({
    required this.id,
    required this.name,
    required this.saasSubscription,
    this.professionalPaymentDay = 5,
    this.inviteCode,
    this.openingTime,
    this.closingTime,
    this.breakStartTime,
    this.breakEndTime,
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
      openingTime: json['opening_time'] as String?,
      closingTime: json['closing_time'] as String?,
      breakStartTime: json['break_start_time'] as String?,
      breakEndTime: json['break_end_time'] as String?,
    );
  }

  final int id;
  final String name;
  final SaasSubscriptionModel saasSubscription;
  final int professionalPaymentDay;

  /// Codigo que o dono compartilha (link/QR) para o cliente se autocadastrar
  /// ja vinculado a este tenant. Ver `POST /auth/register-client`.
  final String? inviteCode;

  /// Horario de funcionamento padrao e pausa (ex: almoco), no formato
  /// "HH:mm:ss" retornado pela API. Nulos quando o dono nunca configurou.
  final String? openingTime;
  final String? closingTime;
  final String? breakStartTime;
  final String? breakEndTime;
}
