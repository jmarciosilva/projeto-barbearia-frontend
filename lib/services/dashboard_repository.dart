import 'package:clube_do_salao/models/dashboard_summary_model.dart';
import 'package:clube_do_salao/models/occupancy_model.dart';
import 'package:clube_do_salao/models/return_risk_model.dart';
import 'package:clube_do_salao/services/api_client.dart';

/// Painel Inteligente do Proprietario (roadmap Fase 4): resumo do dia,
/// ocupacao da equipe e inteligencia de retorno de clientes.
class DashboardRepository {
  const DashboardRepository(this._client);

  final ApiClient _client;

  Future<DashboardSummaryModel> summary() async {
    final response = await _client.get('/dashboard/summary')
        as Map<String, dynamic>;

    return DashboardSummaryModel.fromJson(response);
  }

  Future<List<OccupancyProfessionalModel>> occupancy() async {
    final response = await _client.get('/dashboard/occupancy') as List<dynamic>;

    return response
        .map(
          (json) => OccupancyProfessionalModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<List<ReturnRiskEntryModel>> returnRisk() async {
    final response =
        await _client.get('/dashboard/return-risk') as List<dynamic>;

    return response
        .map(
          (json) => ReturnRiskEntryModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }
}
