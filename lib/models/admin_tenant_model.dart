import 'package:clube_do_salao/models/saas_subscription_model.dart';

/// Estabelecimento visto pelo administrador da plataforma (roadmap Fase 5,
/// `GET /admin/tenants`) — inclui dados de todos os saloes, nao so o proprio.
class AdminTenantModel {
  const AdminTenantModel({
    required this.id,
    required this.name,
    required this.businessType,
    required this.isFounder,
    required this.saasSubscription,
    this.city,
  });

  factory AdminTenantModel.fromJson(Map<String, dynamic> json) {
    return AdminTenantModel(
      id: json['id'] as int,
      name: json['name'] as String,
      businessType: json['business_type'] as String? ?? '',
      city: json['city'] as String?,
      isFounder: json['is_founder'] as bool? ?? false,
      saasSubscription: SaasSubscriptionModel.fromJson(
        json['saas_subscription'] as Map<String, dynamic>,
      ),
    );
  }

  final int id;
  final String name;
  final String businessType;
  final String? city;
  final bool isFounder;
  final SaasSubscriptionModel saasSubscription;
}
