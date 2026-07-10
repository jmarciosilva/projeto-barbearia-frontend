import 'package:clube_do_salao/core/app_exception.dart';
import 'package:clube_do_salao/core/formatting.dart';
import 'package:clube_do_salao/models/admin_dashboard_summary_model.dart';
import 'package:clube_do_salao/models/admin_tenant_model.dart';
import 'package:clube_do_salao/services/admin_repository.dart';
import 'package:clube_do_salao/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';

/// Painel geral da plataforma (roadmap Fase 5), exclusivo do papel `admin`:
/// quantos saloes existem, quantos estao ativos/em trial/vencidos, quantos
/// sao fundadores, receita projetada (soma dos planos pagos ativos — nao ha
/// gateway de pagamento ainda, entao e projecao, nao dinheiro capturado de
/// fato) e total de usuarios cadastrados no produto.
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key, required this.adminRepository});

  final AdminRepository adminRepository;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  bool _isLoading = true;
  String? _errorMessage;
  AdminDashboardSummaryModel? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await widget.adminRepository.summary();

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.userMessage;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return AppLoadingError(message: _errorMessage!, onRetry: _load);
    }

    final summary = _summary!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const AppSectionTitle('Numeros'),
        AppHeroMetric(
          label: 'Receita projetada',
          value: formatCents(summary.projectedRevenueCents),
        ),
        const SizedBox(height: 10),
        AppMetricGrid(
          metrics: [
            AppMetric(
              'Usuarios cadastrados',
              '${summary.totalUsers}',
              Icons.people_outline,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const AppSectionTitle('Saloes'),
        AppMetricGrid(
          metrics: [
            AppMetric('Total', '${summary.totalTenants}', Icons.storefront),
            AppMetric(
              'Ativos',
              '${summary.activeTenants}',
              Icons.check_circle_outline,
            ),
            AppMetric('Em trial', '${summary.trialTenants}', Icons.schedule),
            AppMetric(
              'Fundadores',
              '${summary.founderTenants}',
              Icons.workspace_premium,
            ),
          ],
        ),
        if (summary.expiredTenants > 0) ...[
          const SizedBox(height: 10),
          AppAlertMetric(
            icon: Icons.warning_amber,
            title: '${summary.expiredTenants} salão(ões) vencido(s)',
            subtitle: 'Assinatura SaaS expirada',
          ),
        ],
      ],
    );
  }
}

/// Rotulo amigavel do status efetivo da assinatura SaaS de um tenant.
String _tenantStatusLabel(String effectiveStatus) => switch (effectiveStatus) {
  'trial' => 'Em trial',
  'trial_expired' => 'Trial vencido',
  'active' => 'Ativo',
  _ => effectiveStatus,
};

/// Lista de todos os saloes cadastrados na plataforma, vista pelo
/// administrador (roadmap Fase 5). Tocar num salao abre a tela onde da pra
/// marcar como fundador e conceder assinatura gratuita.
class AdminTenantsPage extends StatefulWidget {
  const AdminTenantsPage({super.key, required this.adminRepository});

  final AdminRepository adminRepository;

  @override
  State<AdminTenantsPage> createState() => _AdminTenantsPageState();
}

class _AdminTenantsPageState extends State<AdminTenantsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<AdminTenantModel> _tenants = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tenants = await widget.adminRepository.listTenants();

      if (!mounted) return;
      setState(() {
        _tenants = tenants;
        _isLoading = false;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.userMessage;
        _isLoading = false;
      });
    }
  }

  Future<void> _openTenant(AdminTenantModel tenant) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminTenantDetailPage(
          tenant: tenant,
          adminRepository: widget.adminRepository,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return AppLoadingError(message: _errorMessage!, onRetry: _load);
    }

    if (_tenants.isEmpty) {
      return const Center(child: Text('Nenhum salao cadastrado ainda.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const AppSectionTitle('Saloes'),
        for (final tenant in _tenants)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(
                tenant.isFounder ? Icons.workspace_premium : Icons.storefront,
              ),
              title: Text(tenant.name),
              subtitle: Text(
                '${_tenantStatusLabel(tenant.saasSubscription.effectiveStatus)} - '
                '${tenant.saasSubscription.planName}'
                '${tenant.isFounder ? ' - Fundador' : ''}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openTenant(tenant),
            ),
          ),
      ],
    );
  }
}

/// Nomes/codigos dos 3 tiers pagos (trial nao e selecionavel aqui, so faz
/// sentido pra concessao gratuita mesmo).
const _paidPlanCodes = {
  'basico': 'Básico',
  'intermediario': 'Intermediário',
  'premium': 'Premium',
};

/// Detalhe de um salao pelo administrador: selo de fundador e concessao de
/// assinatura gratuita (roadmap Fase 5).
class AdminTenantDetailPage extends StatefulWidget {
  const AdminTenantDetailPage({
    super.key,
    required this.tenant,
    required this.adminRepository,
  });

  final AdminTenantModel tenant;
  final AdminRepository adminRepository;

  @override
  State<AdminTenantDetailPage> createState() => _AdminTenantDetailPageState();
}

class _AdminTenantDetailPageState extends State<AdminTenantDetailPage> {
  late AdminTenantModel _tenant = widget.tenant;
  final _monthsController = TextEditingController(text: '12');
  final _reasonController = TextEditingController();
  String _planCode = 'premium';

  bool _isSavingFounder = false;
  bool _isGranting = false;
  String? _grantError;

  @override
  void dispose() {
    _monthsController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _toggleFounder(bool value) async {
    setState(() => _isSavingFounder = true);

    try {
      final updated = await widget.adminRepository.toggleFounder(
        tenantId: _tenant.id,
        isFounder: value,
      );

      if (!mounted) return;
      setState(() {
        _tenant = updated;
        _isSavingFounder = false;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _isSavingFounder = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.userMessage)));
    }
  }

  Future<void> _grantSubscription() async {
    final months = int.tryParse(_monthsController.text.trim());
    if (months == null || months <= 0) {
      setState(() => _grantError = 'Informe um numero de meses valido.');
      return;
    }

    setState(() {
      _isGranting = true;
      _grantError = null;
    });

    try {
      final updated = await widget.adminRepository.extendSubscription(
        tenantId: _tenant.id,
        planCode: _planCode,
        months: months,
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      );

      if (!mounted) return;
      final endsAt = updated.saasSubscription.currentPeriodEndsAt;
      setState(() {
        _tenant = updated;
        _isGranting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            endsAt == null
                ? 'Assinatura estendida.'
                : 'Assinatura estendida ate ${formatDate(endsAt)}.',
          ),
        ),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _grantError = error.userMessage;
        _isGranting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscription = _tenant.saasSubscription;
    final endsAt = subscription.currentPeriodEndsAt;

    return AppScaffold(
      appBar: AppBar(title: Text(_tenant.name)),
      body: AppProfileSummary(
        title: _tenant.name,
        rows: [
          AppInfoRow(
            'Status',
            _tenantStatusLabel(subscription.effectiveStatus),
          ),
          AppInfoRow('Plano', subscription.planName),
          AppInfoRow('Valor', formatCents(subscription.priceCents)),
          AppInfoRow('Vence em', endsAt == null ? '-' : formatDate(endsAt)),
        ],
        footer: [
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              title: const Text('Salão Fundador'),
              subtitle: const Text(
                'Faz parte do clube dos fundadores; não vê mais o aviso de trial vencendo.',
              ),
              value: _tenant.isFounder,
              onChanged: _isSavingFounder ? null : _toggleFounder,
            ),
          ),
          const SizedBox(height: 16),
          const AppSectionTitle('Conceder assinatura gratuita'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _planCode,
            decoration: const InputDecoration(labelText: 'Plano'),
            items: [
              for (final entry in _paidPlanCodes.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (value) =>
                setState(() => _planCode = value ?? _planCode),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _monthsController,
            decoration: const InputDecoration(labelText: 'Meses'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Motivo (opcional)',
              hintText: 'Ex: negociação fundador',
            ),
          ),
          if (_grantError != null) ...[
            const SizedBox(height: 12),
            Text(
              _grantError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isGranting ? null : _grantSubscription,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            child: _isGranting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Conceder gratuitamente'),
          ),
        ],
      ),
    );
  }
}
