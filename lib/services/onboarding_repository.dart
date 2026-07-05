import 'package:clube_do_salao/models/tenant_summary_model.dart';
import 'package:clube_do_salao/services/api_client.dart';

/// Endpoints publicos (sem token) usados antes do cliente se autocadastrar:
/// diretorio de estabelecimentos e consulta por codigo de convite.
class OnboardingRepository {
  const OnboardingRepository(this._client);

  final ApiClient _client;

  Future<List<TenantSummaryModel>> directory() async {
    final response = await _client.get('/tenants/directory') as List<dynamic>;

    return response
        .map((json) => TenantSummaryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<TenantSummaryModel> lookupInviteCode(String code) async {
    final response =
        await _client.get('/tenants/by-invite-code/$code')
            as Map<String, dynamic>;

    return TenantSummaryModel.fromJson(response);
  }
}
