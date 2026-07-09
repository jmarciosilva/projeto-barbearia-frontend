import 'package:clube_do_salao/models/admin_dashboard_summary_model.dart';
import 'package:clube_do_salao/models/admin_tenant_model.dart';
import 'package:clube_do_salao/services/api_client.dart';

/// Area administrativa da plataforma (roadmap Fase 5), exclusiva do papel
/// `admin` — nunca escopada por tenant, ao contrario de todo outro
/// repositorio do app.
class AdminRepository {
  const AdminRepository(this._client);

  final ApiClient _client;

  Future<AdminDashboardSummaryModel> summary() async {
    final response =
        await _client.get('/admin/dashboard') as Map<String, dynamic>;

    return AdminDashboardSummaryModel.fromJson(response);
  }

  Future<List<AdminTenantModel>> listTenants() async {
    final response = await _client.get('/admin/tenants') as List<dynamic>;

    return response
        .map(
          (json) => AdminTenantModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  Future<AdminTenantModel> toggleFounder({
    required int tenantId,
    required bool isFounder,
  }) async {
    final response =
        await _client.patch(
              '/admin/tenants/$tenantId/founder',
              body: {'is_founder': isFounder},
            )
            as Map<String, dynamic>;

    return AdminTenantModel.fromJson(response);
  }

  Future<AdminTenantModel> extendSubscription({
    required int tenantId,
    String? planCode,
    required int months,
    String? reason,
  }) async {
    final response =
        await _client.post(
              '/admin/tenants/$tenantId/subscription/extend',
              body: {
                'plan_code': ?planCode,
                'months': months,
                'reason': ?reason,
              },
            )
            as Map<String, dynamic>;

    return AdminTenantModel.fromJson(response);
  }
}
