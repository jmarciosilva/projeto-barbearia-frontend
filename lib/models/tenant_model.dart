import 'package:clube_do_salao/models/saas_subscription_model.dart';

class TenantModel {
  const TenantModel({
    required this.id,
    required this.name,
    required this.saasSubscription,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id'] as int,
      name: json['name'] as String,
      saasSubscription: SaasSubscriptionModel.fromJson(
        json['saas_subscription'] as Map<String, dynamic>,
      ),
    );
  }

  final int id;
  final String name;
  final SaasSubscriptionModel saasSubscription;
}
