import 'package:clube_do_salao/core/app_exception.dart';
import 'package:clube_do_salao/core/formatting.dart';
import 'package:clube_do_salao/models/appointment_model.dart';
import 'package:clube_do_salao/models/client_model.dart';
import 'package:clube_do_salao/models/client_subscription_model.dart';
import 'package:clube_do_salao/models/dashboard_summary_model.dart';
import 'package:clube_do_salao/models/occupancy_model.dart';
import 'package:clube_do_salao/models/payment_model.dart';
import 'package:clube_do_salao/models/return_risk_model.dart';
import 'package:clube_do_salao/models/professional_model.dart';
import 'package:clube_do_salao/models/professional_finance_model.dart';
import 'package:clube_do_salao/models/saas_plan_model.dart';
import 'package:clube_do_salao/models/saas_subscription_model.dart';
import 'package:clube_do_salao/models/service_model.dart';
import 'package:clube_do_salao/models/subscription_plan_model.dart';
import 'package:clube_do_salao/models/team_performance_model.dart';
import 'package:clube_do_salao/models/tenant_model.dart';
import 'package:clube_do_salao/models/waitlist_entry_model.dart';
import 'package:clube_do_salao/pages/account_settings_page.dart';
import 'package:clube_do_salao/pages/business_hours_page.dart';
import 'package:clube_do_salao/pages/customer_pages.dart';
import 'package:clube_do_salao/pages/owner_invite_page.dart';
import 'package:clube_do_salao/pages/payment_confirmation_page.dart';
import 'package:clube_do_salao/pages/professional_pages.dart';
import 'package:clube_do_salao/services/appointments_repository.dart';
import 'package:clube_do_salao/services/auth_session.dart';
import 'package:clube_do_salao/services/clients_repository.dart';
import 'package:clube_do_salao/services/dashboard_repository.dart';
import 'package:clube_do_salao/services/onboarding_checklist_storage.dart';
import 'package:clube_do_salao/services/payments_repository.dart';
import 'package:clube_do_salao/services/professionals_repository.dart';
import 'package:clube_do_salao/services/saas_subscription_repository.dart';
import 'package:clube_do_salao/services/services_repository.dart';
import 'package:clube_do_salao/services/subscription_plans_repository.dart';
import 'package:clube_do_salao/services/tenant_repository.dart';
import 'package:clube_do_salao/services/waitlist_repository.dart';
import 'package:clube_do_salao/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OwnerHomePage extends StatefulWidget {
  const OwnerHomePage({
    super.key,
    required this.clientsRepository,
    required this.appointmentsRepository,
    required this.paymentsRepository,
    required this.plansRepository,
    required this.servicesRepository,
    required this.professionalsRepository,
    required this.tenantRepository,
    required this.saasSubscriptionRepository,
    required this.checklistStorage,
    required this.authSession,
    required this.dashboardRepository,
    required this.waitlistRepository,
  });

  final ClientsRepository clientsRepository;
  final AppointmentsRepository appointmentsRepository;
  final PaymentsRepository paymentsRepository;
  final SubscriptionPlansRepository plansRepository;
  final ServicesRepository servicesRepository;
  final ProfessionalsRepository professionalsRepository;
  final TenantRepository tenantRepository;
  final SaasSubscriptionRepository saasSubscriptionRepository;
  final OnboardingChecklistStorage checklistStorage;
  final AuthSession authSession;
  final DashboardRepository dashboardRepository;
  final WaitlistRepository waitlistRepository;

  @override
  State<OwnerHomePage> createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends State<OwnerHomePage> {
  bool _isLoading = true;
  String? _errorMessage;
  DashboardSummaryModel? _summary;
  int _teamCompletedCount = 0;
  SaasSubscriptionModel? _saasSubscription;
  TenantModel? _tenant;
  int _professionalsCount = 0;
  int _servicesCount = 0;
  int _plansCount = 0;
  bool _hasSharedInvite = false;
  bool _checklistDismissed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _showChecklist =>
      !_checklistDismissed &&
      !(_professionalsCount > 0 &&
          _servicesCount > 0 &&
          _plansCount > 0 &&
          _hasSharedInvite);

  Future<void> _dismissChecklist() async {
    await widget.checklistStorage.dismiss(_tenant!.id);
    if (!mounted) return;
    setState(() => _checklistDismissed = true);
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await widget.dashboardRepository.summary();
      final teamPerformance = await widget.dashboardRepository
          .teamPerformance();
      final tenant = await widget.tenantRepository.show();
      final professionals = await widget.professionalsRepository.index();
      final services = await widget.servicesRepository.index();
      final plans = await widget.plansRepository.index();
      final hasSharedInvite = await widget.checklistStorage.hasSharedInvite(
        tenant.id,
      );
      final checklistDismissed = await widget.checklistStorage.isDismissed(
        tenant.id,
      );

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _teamCompletedCount = teamPerformance.fold<int>(
          0,
          (sum, entry) => sum + entry.completedCount,
        );
        _saasSubscription = tenant.saasSubscription;
        _tenant = tenant;
        _professionalsCount = professionals.length;
        _servicesCount = services.length;
        _plansCount = plans.length;
        _hasSharedInvite = hasSharedInvite;
        _checklistDismissed = checklistDismissed;
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

    final subscription = _saasSubscription!;
    final accentColors = appAccentColors(context);
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_tenant!.isFounder)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: _FounderBadge(),
          ),
        if (!_tenant!.isFounder &&
            (subscription.isExpired || subscription.isTrial))
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _SaasPlanBanner(
              subscription: subscription,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SaasPlanPage(
                      tenantRepository: widget.tenantRepository,
                      saasSubscriptionRepository:
                          widget.saasSubscriptionRepository,
                    ),
                  ),
                );
                _load();
              },
            ),
          ),
        if (_showChecklist)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _OnboardingChecklistCard(
              hasProfessional: _professionalsCount > 0,
              hasService: _servicesCount > 0,
              hasPlan: _plansCount > 0,
              hasSharedInvite: _hasSharedInvite,
              onDismiss: _dismissChecklist,
              onAddProfessional: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NewProfessionalPage(
                      professionalsRepository: widget.professionalsRepository,
                      servicesRepository: widget.servicesRepository,
                      authSession: widget.authSession,
                    ),
                  ),
                );
                _load();
              },
              onAddService: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NewServicePage(
                      servicesRepository: widget.servicesRepository,
                    ),
                  ),
                );
                _load();
              },
              onAddPlan: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NewPlanPage(
                      plansRepository: widget.plansRepository,
                      servicesRepository: widget.servicesRepository,
                      professionalsRepository: widget.professionalsRepository,
                    ),
                  ),
                );
                _load();
              },
              onShareInvite: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => InviteCodePage(
                      tenantRepository: widget.tenantRepository,
                      checklistStorage: widget.checklistStorage,
                      initialTenant: _tenant!,
                    ),
                  ),
                );
                _load();
              },
            ),
          ),
        const AppSectionTitle('Receita'),
        AppHeroMetric(
          label: 'Receita do mês',
          value: formatCents(_summary!.walkinRevenueMonthCents),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WalkinRevenueMonthPage(
                  paymentsRepository: widget.paymentsRepository,
                ),
              ),
            );
            _load();
          },
        ),
        const SizedBox(height: 10),
        AppMetricGrid(
          metrics: [
            AppMetric(
              'Prevista hoje',
              formatCents(_summary!.expectedRevenueTodayCents),
              Icons.today,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TodayRevenuePage(
                      appointmentsRepository: widget.appointmentsRepository,
                    ),
                  ),
                );
                _load();
              },
            ),
            AppMetric(
              'Recorrente do mês',
              formatCents(_summary!.recurringRevenueMonthCents),
              Icons.autorenew,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ActiveSubscribersPage(
                      clientsRepository: widget.clientsRepository,
                      paymentsRepository: widget.paymentsRepository,
                    ),
                  ),
                );
                _load();
              },
            ),
          ],
        ),
        if (_summary!.openDebtCents > 0) ...[
          const SizedBox(height: 10),
          AppAlertMetric(
            icon: Icons.receipt_long,
            title: '${formatCents(_summary!.openDebtCents)} em fiado',
            subtitle: 'Toque para gerenciar',
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DebtManagementPage(
                    paymentsRepository: widget.paymentsRepository,
                  ),
                ),
              );
              _load();
            },
          ),
        ],
        const SizedBox(height: 16),
        const AppSectionTitle('Hoje'),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AppHeroMetric(
                  label: 'Agendamentos',
                  value: '${_summary!.appointmentsToday}',
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TodayAppointmentsPage(
                          appointmentsRepository: widget.appointmentsRepository,
                          paymentsRepository: widget.paymentsRepository,
                        ),
                      ),
                    );
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppHeroMetric(
                  label: 'Desempenho da equipe',
                  value: '$_teamCompletedCount',
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TeamPerformancePage(
                          dashboardRepository: widget.dashboardRepository,
                        ),
                      ),
                    );
                    _load();
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AppMetricGrid(
          metrics: [
            AppMetric(
              'Confirmados',
              '${_summary!.confirmedToday}',
              Icons.check_circle_outline,
              accentColor: colorScheme.primary,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TodayAppointmentsPage(
                      appointmentsRepository: widget.appointmentsRepository,
                      paymentsRepository: widget.paymentsRepository,
                    ),
                  ),
                );
                _load();
              },
            ),
            AppMetric(
              'Pendentes',
              '${_summary!.pendingToday}',
              Icons.warning_amber,
              accentColor: heroGoldAccent,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PendingPaymentsPage(
                      paymentsRepository: widget.paymentsRepository,
                    ),
                  ),
                );
                _load();
              },
            ),
            AppMetric(
              'Fila de espera',
              '${_summary!.waitlistCount}',
              Icons.people_outline,
              accentColor: colorScheme.secondary,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ManageWaitlistPage(
                      waitlistRepository: widget.waitlistRepository,
                      professionalsRepository: widget.professionalsRepository,
                      clientsRepository: widget.clientsRepository,
                      servicesRepository: widget.servicesRepository,
                    ),
                  ),
                );
                _load();
              },
            ),
            AppMetric(
              'Cancelamentos',
              '${_summary!.canceledToday}',
              Icons.event_busy,
              accentColor: colorScheme.error,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TodayAppointmentsPage(
                      appointmentsRepository: widget.appointmentsRepository,
                      paymentsRepository: widget.paymentsRepository,
                    ),
                  ),
                );
                _load();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        const AppSectionTitle('Próximas ações'),
        AppActionTile(
          icon: Icons.diamond,
          accentColor: accentColors[0 % 3],
          title: 'Meu plano',
          subtitle: subscription.isTrial
              ? 'Trial - faltam ${subscription.trialDaysRemaining} dias'
              : subscription.planName,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SaasPlanPage(
                  tenantRepository: widget.tenantRepository,
                  saasSubscriptionRepository: widget.saasSubscriptionRepository,
                ),
              ),
            );
            _load();
          },
        ),
        AppActionTile(
          icon: Icons.storefront,
          accentColor: accentColors[1 % 3],
          title: 'Catálogo',
          subtitle: 'Gerencie serviços e profissionais do seu salão.',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CatalogPage(
                  servicesRepository: widget.servicesRepository,
                  professionalsRepository: widget.professionalsRepository,
                  authSession: widget.authSession,
                ),
              ),
            );
            _load();
          },
        ),
        AppActionTile(
          icon: Icons.schedule,
          accentColor: accentColors[2 % 3],
          title: 'Horário de funcionamento',
          subtitle: 'Defina abertura, fechamento, pausas e exceções por data.',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  BusinessHoursPage(tenantRepository: widget.tenantRepository),
            ),
          ),
        ),
        AppActionTile(
          icon: Icons.bar_chart,
          accentColor: accentColors[3 % 3],
          title: 'Ocupação da equipe',
          subtitle:
              'Veja o quanto da agenda de cada profissional está ocupada.',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OccupancyPage(
                dashboardRepository: widget.dashboardRepository,
                professionalsRepository: widget.professionalsRepository,
                servicesRepository: widget.servicesRepository,
              ),
            ),
          ),
        ),
        AppActionTile(
          icon: Icons.favorite_border,
          accentColor: accentColors[4 % 3],
          title: 'Clientes para reconquistar',
          subtitle:
              'Veja quem está no momento certo de voltar, segundo o histórico.',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReturnRiskPage(
                dashboardRepository: widget.dashboardRepository,
              ),
            ),
          ),
        ),
        AppActionTile(
          icon: Icons.lock_outline,
          accentColor: accentColors[5 % 3],
          title: 'Meus dados de acesso',
          subtitle: 'Altere seu e-mail e/ou senha de login.',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  AccountSettingsPage(authSession: widget.authSession),
            ),
          ),
        ),
        AppActionTile(
          icon: Icons.person_add,
          accentColor: accentColors[6 % 3],
          title: 'Cadastrar cliente',
          subtitle: 'Nome, telefone, e-mail e senha de acesso.',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    NewClientPage(clientsRepository: widget.clientsRepository),
              ),
            );
            _load();
          },
        ),
        AppActionTile(
          icon: Icons.workspace_premium,
          accentColor: accentColors[7 % 3],
          title: 'Criar plano de assinatura',
          subtitle: 'Defina serviços, limites, dias e horários permitidos.',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NewPlanPage(
                  plansRepository: widget.plansRepository,
                  servicesRepository: widget.servicesRepository,
                  professionalsRepository: widget.professionalsRepository,
                ),
              ),
            );
            _load();
          },
        ),
        AppActionTile(
          icon: Icons.price_check,
          accentColor: accentColors[8 % 3],
          title: 'Confirmar pagamento manual',
          subtitle: 'PIX, cartão, dinheiro ou fiado.',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PendingPaymentsPage(
                  paymentsRepository: widget.paymentsRepository,
                ),
              ),
            );
            _load();
          },
        ),
        AppActionTile(
          icon: Icons.receipt_long,
          accentColor: accentColors[9 % 3],
          title: 'Gestão do fiado',
          subtitle: 'Acompanhe saldos pendentes e lance recebimentos parciais.',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DebtManagementPage(
                  paymentsRepository: widget.paymentsRepository,
                ),
              ),
            );
            _load();
          },
        ),
        AppActionTile(
          icon: Icons.account_balance_wallet,
          accentColor: accentColors[10 % 3],
          title: 'Comissoes profissionais',
          subtitle: 'Veja produção, comissão e adiantamentos.',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProfessionalCommissionsPage(
                  professionalsRepository: widget.professionalsRepository,
                  tenantRepository: widget.tenantRepository,
                  dashboardRepository: widget.dashboardRepository,
                ),
              ),
            );
            _load();
          },
        ),
      ],
    );
  }
}

/// Checklist de configuracao inicial, exibido no topo do dashboard do dono
/// ate os 3 passos serem concluidos (ou o card ser dispensado). Item
/// concluido nao bloqueia os outros nem esconde o card sozinho — so some
/// quando os 3 estao prontos ou o dono dispensa manualmente.
class _OnboardingChecklistCard extends StatelessWidget {
  const _OnboardingChecklistCard({
    required this.hasProfessional,
    required this.hasService,
    required this.hasPlan,
    required this.hasSharedInvite,
    required this.onDismiss,
    required this.onAddProfessional,
    required this.onAddService,
    required this.onAddPlan,
    required this.onShareInvite,
  });

  final bool hasProfessional;
  final bool hasService;
  final bool hasPlan;
  final bool hasSharedInvite;
  final VoidCallback onDismiss;
  final VoidCallback onAddProfessional;
  final VoidCallback onAddService;
  final VoidCallback onAddPlan;
  final VoidCallback onShareInvite;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Vamos configurar seu salão',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Dispensar',
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),

            _ChecklistItem(
              done: hasService,
              label: 'Cadastre seu primeiro serviço',
              onTap: onAddService,
            ),
            _ChecklistItem(
              done: hasProfessional,
              label: 'Cadastre seu primeiro profissional',
              onTap: onAddProfessional,
            ),
            _ChecklistItem(
              done: hasPlan,
              label:
                  'Crie um plano de assinatura com os serviços e profissionais',
              onTap: onAddPlan,
            ),
            _ChecklistItem(
              done: hasSharedInvite,
              label: 'Compartilhe o convite com seus clientes',
              onTap: onShareInvite,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.done,
    required this.label,
    required this.onTap,
  });

  final bool done;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        done ? Icons.check_circle : Icons.radio_button_unchecked,
        color: done ? colorScheme.primary : colorScheme.outline,
      ),
      title: Text(
        label,
        style: done
            ? TextStyle(
                decoration: TextDecoration.lineThrough,
                color: colorScheme.onSurfaceVariant,
              )
            : null,
      ),
      trailing: done ? null : const Icon(Icons.chevron_right),
      onTap: done ? null : onTap,
    );
  }
}

/// Agenda do dia. Proprietario ve o estabelecimento inteiro; profissional
/// ve so os proprios atendimentos (o backend ja aplica esse recorte).
///
/// Cobre o caso do cliente que liga ou manda mensagem em vez de usar o
/// app: dono/profissional podem criar um agendamento manual em nome dele
/// ("Novo agendamento") ou coloca-lo na fila de espera do dia sem precisar
/// que o proprio cliente esteja logado.
class AgendaPage extends StatefulWidget {
  const AgendaPage({
    super.key,
    required this.appointmentsRepository,
    required this.paymentsRepository,
    required this.waitlistRepository,
    required this.professionalsRepository,
    required this.clientsRepository,
    required this.servicesRepository,
    required this.tenantRepository,
  });

  final AppointmentsRepository appointmentsRepository;
  final PaymentsRepository paymentsRepository;
  final WaitlistRepository waitlistRepository;
  final ProfessionalsRepository professionalsRepository;
  final ClientsRepository clientsRepository;
  final ServicesRepository servicesRepository;
  final TenantRepository tenantRepository;

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  DateTime _selectedDay = DateTime.now();
  bool _isLoading = true;
  String? _errorMessage;
  List<AppointmentModel> _appointments = [];
  List<WaitlistEntryModel> _waitlistEntries = [];

  bool get _isToday => DateUtils.isSameDay(_selectedDay, DateTime.now());

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
      final startOfDay = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final appointments = await widget.appointmentsRepository.index(
        from: startOfDay,
        to: endOfDay,
      );
      // Fila de espera nao tem data marcada — so faz sentido mostrar junto
      // da agenda de hoje, que e quando o cliente esta de fato esperando.
      final waitlistEntries = _isToday
          ? await widget.waitlistRepository.index(status: 'waiting')
          : <WaitlistEntryModel>[];

      if (!mounted) return;
      setState(() {
        _appointments = appointments;
        _waitlistEntries = waitlistEntries;
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

  void _onDaySelected(DateTime day) {
    setState(() => _selectedDay = day);
    _load();
  }

  Future<void> _openDetail(AppointmentModel appointment) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppointmentDetailPage(
          appointment: appointment,
          appointmentsRepository: widget.appointmentsRepository,
          paymentsRepository: widget.paymentsRepository,
          canConfirmPayment: true,
        ),
      ),
    );
    _load();
  }

  Future<void> _openWaitlistEntry(WaitlistEntryModel entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AssignWaitlistPage(
          waitlistRepository: widget.waitlistRepository,
          professionalsRepository: widget.professionalsRepository,
          entry: entry,
        ),
      ),
    );
    _load();
  }

  Future<void> _openWaitlist() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManageWaitlistPage(
          waitlistRepository: widget.waitlistRepository,
          professionalsRepository: widget.professionalsRepository,
          clientsRepository: widget.clientsRepository,
          servicesRepository: widget.servicesRepository,
        ),
      ),
    );
    _load();
  }

  Future<void> _openNewAppointment() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChooseClientPage(
          clientsRepository: widget.clientsRepository,
          servicesRepository: widget.servicesRepository,
          professionalsRepository: widget.professionalsRepository,
          appointmentsRepository: widget.appointmentsRepository,
          tenantRepository: widget.tenantRepository,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final Widget schedule;

    if (_isLoading) {
      schedule = const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_errorMessage != null) {
      schedule = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else {
      schedule = AppDayTimeline(
        appointments: _appointments,
        waitlistEntries: _waitlistEntries,
        onAppointmentTap: _openDetail,
        onWaitlistTap: _openWaitlistEntry,
        emptyMessage: 'Nenhum agendamento para este dia.',
      );
    }

    return Stack(
      children: [
        ListView(
          // Espaco reservado embaixo pros dois FABs empilhados nao cobrirem
          // o ultimo item da lista.
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: CalendarDatePicker(
                initialDate: _selectedDay,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateChanged: _onDaySelected,
              ),
            ),
            schedule,
          ],
        ),
        Positioned(
          right: 16,
          bottom: 88,
          child: FloatingActionButton.extended(
            heroTag: 'novoAgendamento',
            onPressed: _openNewAppointment,
            icon: const Icon(Icons.add),
            label: const Text('Novo agendamento'),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'filaDeEspera',
            onPressed: _openWaitlist,
            icon: const Icon(Icons.groups),
            label: const Text('Fila de espera'),
          ),
        ),
      ],
    );
  }
}

/// Escolha do cliente para um agendamento manual criado pelo dono ou
/// profissional (ex: cliente ligou ou mandou mensagem em vez de usar o
/// app). Depois de escolhido, reaproveita o mesmo fluxo de agendamento do
/// cliente (servico > profissional > horario), so que em nome dele.
class ChooseClientPage extends StatefulWidget {
  const ChooseClientPage({
    super.key,
    required this.clientsRepository,
    required this.servicesRepository,
    required this.professionalsRepository,
    required this.appointmentsRepository,
    required this.tenantRepository,
  });

  final ClientsRepository clientsRepository;
  final ServicesRepository servicesRepository;
  final ProfessionalsRepository professionalsRepository;
  final AppointmentsRepository appointmentsRepository;
  final TenantRepository tenantRepository;

  @override
  State<ChooseClientPage> createState() => _ChooseClientPageState();
}

class _ChooseClientPageState extends State<ChooseClientPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ClientModel> _clients = [];
  ClientModel? _selected;

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
      final clients = await widget.clientsRepository.index();

      if (!mounted) return;
      setState(() {
        _clients = clients;
        _selected = clients.isEmpty ? null : clients.first;
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

  Future<void> _openNewClient() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            NewClientPage(clientsRepository: widget.clientsRepository),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else if (_clients.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nenhum cliente cadastrado ainda.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _openNewClient,
                icon: const Icon(Icons.person_add),
                label: const Text('Cadastrar cliente'),
              ),
            ],
          ),
        ),
      );
    } else {
      body = RadioGroup<ClientModel>(
        groupValue: _selected,
        onChanged: (value) => setState(() => _selected = value),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextButton.icon(
              onPressed: _openNewClient,
              icon: const Icon(Icons.person_add),
              label: const Text('Cliente novo? Cadastre primeiro'),
            ),
            const SizedBox(height: 8),
            for (final client in _clients)
              RadioListTile<ClientModel>(
                title: Text(client.name),
                subtitle: Text(client.phone),
                value: client,
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _selected == null
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChooseServicePage(
                          clientsRepository: widget.clientsRepository,
                          servicesRepository: widget.servicesRepository,
                          professionalsRepository:
                              widget.professionalsRepository,
                          appointmentsRepository: widget.appointmentsRepository,
                          tenantRepository: widget.tenantRepository,
                          client: _selected,
                        ),
                      ),
                    ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Novo agendamento')),
      body: body,
    );
  }
}

class PlansPage extends StatefulWidget {
  const PlansPage({
    super.key,
    required this.plansRepository,
    required this.servicesRepository,
    required this.professionalsRepository,
  });

  final SubscriptionPlansRepository plansRepository;
  final ServicesRepository servicesRepository;
  final ProfessionalsRepository professionalsRepository;

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<SubscriptionPlanModel> _plans = [];

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
      final plans = await widget.plansRepository.index();

      if (!mounted) return;
      setState(() {
        _plans = plans;
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

  Future<void> _openNewPlan() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewPlanPage(
          plansRepository: widget.plansRepository,
          servicesRepository: widget.servicesRepository,
          professionalsRepository: widget.professionalsRepository,
        ),
      ),
    );
    _load();
  }

  Future<void> _openPlan(SubscriptionPlanModel plan) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditPlanPage(
          plansRepository: widget.plansRepository,
          servicesRepository: widget.servicesRepository,
          professionalsRepository: widget.professionalsRepository,
          plan: plan,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else if (_plans.isEmpty) {
      body = const Center(child: Text('Nenhum plano cadastrado ainda.'));
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          const AppSectionTitle('Planos ativos'),
          for (final plan in _plans)
            AppPlanTile(
              plan.name,
              '${formatCents(plan.priceCents)}/mes',
              plan.usageLimitLabel,
              onTap: () => _openPlan(plan),
            ),
        ],
      );
    }

    return Stack(
      children: [
        body,
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _openNewPlan,
            tooltip: 'Criar plano de assinatura',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class ClientsPage extends StatefulWidget {
  const ClientsPage({
    super.key,
    required this.clientsRepository,
    required this.paymentsRepository,
    required this.tenantRepository,
    required this.checklistStorage,
  });

  final ClientsRepository clientsRepository;
  final PaymentsRepository paymentsRepository;
  final TenantRepository tenantRepository;
  final OnboardingChecklistStorage checklistStorage;

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ClientModel> _clients = [];
  TenantModel? _tenant;

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
      final results = await Future.wait([
        widget.clientsRepository.index(),
        widget.tenantRepository.show(),
      ]);

      if (!mounted) return;
      setState(() {
        _clients = results[0] as List<ClientModel>;
        _tenant = results[1] as TenantModel;
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

  Future<void> _openNewClient() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            NewClientPage(clientsRepository: widget.clientsRepository),
      ),
    );
    _load();
  }

  Future<void> _openInvite() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InviteCodePage(
          tenantRepository: widget.tenantRepository,
          checklistStorage: widget.checklistStorage,
          initialTenant: _tenant!,
        ),
      ),
    );
    _load();
  }

  /// Unifica os dois jeitos de trazer um cliente novo pro salao numa unica
  /// acao (antes eram dois pontos de entrada separados: FAB aqui e a tile
  /// "Convidar clientes" escondida em "Próximas ações"): o dono cadastra
  /// diretamente (com senha de acesso, se quiser) ou compartilha o convite
  /// pra o proprio cliente se cadastrar sozinho.
  Future<void> _addClient() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: AppSectionTitle('Adicionar cliente'),
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Cadastrar cliente'),
              subtitle: const Text(
                'Você preenche nome, telefone, e-mail e senha de acesso na hora.',
              ),
              onTap: () => Navigator.of(context).pop('register'),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Convidar por link ou QR code'),
              subtitle: const Text(
                'O cliente se cadastra sozinho pelo convite do salão.',
              ),
              onTap: () => Navigator.of(context).pop('invite'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == 'register') {
      await _openNewClient();
    } else if (choice == 'invite') {
      await _openInvite();
    }
  }

  Future<void> _openClient(ClientModel client) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientDetailPage(
          clientsRepository: widget.clientsRepository,
          paymentsRepository: widget.paymentsRepository,
          client: client,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else if (_clients.isEmpty) {
      body = const Center(child: Text('Nenhum cliente cadastrado ainda.'));
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          const AppSectionTitle('Clientes'),
          for (final client in _clients)
            AppClientTile(
              client.name,
              client.activeSubscription == null
                  ? 'Sem plano'
                  : 'Plano ${client.activeSubscription!.plan?.name ?? '-'}',
              client.activeSubscription?.paymentStatusLabel ?? '-',
              contact: [
                client.phone,
                if (client.email != null && client.email!.isNotEmpty)
                  client.email!,
              ].join(' - '),
              since: client.createdAt == null
                  ? null
                  : 'Cliente desde ${formatMonthYear(client.createdAt!)}',
              onTap: () => _openClient(client),
            ),
        ],
      );
    }

    return Stack(
      children: [
        body,
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _addClient,
            tooltip: 'Adicionar cliente',
            child: const Icon(Icons.person_add),
          ),
        ),
      ],
    );
  }
}

/// Formulario de cadastro de cliente, gravado direto na API.
class NewClientPage extends StatefulWidget {
  const NewClientPage({super.key, required this.clientsRepository});

  final ClientsRepository clientsRepository;

  @override
  State<NewClientPage> createState() => _NewClientPageState();
}

class _NewClientPageState extends State<NewClientPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _notesController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.clientsRepository.create(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        password: _passwordController.text.isEmpty
            ? null
            : _passwordController.text,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cliente ${_nameController.text} cadastrado.')),
      );
      Navigator.of(context).pop();
    } on QueuedForSyncException catch (queued) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(queued.userMessage)));
      Navigator.of(context).pop();
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.userMessage;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Cadastrar cliente')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                hintText: 'Ex: 11912345678',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Informe o telefone'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-mail (opcional)'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Senha de acesso ao app (opcional)',
                hintText: 'Deixe em branco para não liberar login',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Observações'),
              maxLines: 3,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formulario de criacao de plano de assinatura, gravado direto na API.
class NewPlanPage extends StatefulWidget {
  const NewPlanPage({
    super.key,
    required this.plansRepository,
    required this.servicesRepository,
    required this.professionalsRepository,
  });

  final SubscriptionPlansRepository plansRepository;
  final ServicesRepository servicesRepository;
  final ProfessionalsRepository professionalsRepository;

  @override
  State<NewPlanPage> createState() => _NewPlanPageState();
}

class _NewPlanPageState extends State<NewPlanPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _limitController = TextEditingController();
  final Set<int> _selectedServiceIds = {};
  final Set<int> _selectedProfessionalIds = {};

  bool _isLoadingOptions = true;
  String? _optionsError;
  List<ServiceModel> _services = [];
  List<ProfessionalModel> _professionals = [];

  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoadingOptions = true;
      _optionsError = null;
    });

    try {
      final results = await Future.wait([
        widget.servicesRepository.index(),
        widget.professionalsRepository.index(),
      ]);

      if (!mounted) return;
      setState(() {
        _services = results[0] as List<ServiceModel>;
        _professionals = results[1] as List<ProfessionalModel>;
        _isLoadingOptions = false;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _optionsError = error.userMessage;
        _isLoadingOptions = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      await widget.plansRepository.create(
        name: _nameController.text.trim(),
        priceCents: parsePriceToCents(_priceController.text),
        usageLimit: _limitController.text.trim().isEmpty
            ? null
            : int.tryParse(_limitController.text.trim()),
        serviceIds: _selectedServiceIds.toList(),
        professionalIds: _selectedProfessionalIds.toList(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plano ${_nameController.text} criado.')),
      );
      Navigator.of(context).pop();
    } on QueuedForSyncException catch (queued) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(queued.userMessage)));
      Navigator.of(context).pop();
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _saveError = error.userMessage;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Criar plano de assinatura')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome do plano'),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Preco mensal',
                hintText: 'Ex: 99,90',
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Informe o preco' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _limitController,
              decoration: const InputDecoration(
                labelText: 'Limite de usos mensais (opcional)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const AppSectionTitle('Serviços inclusos'),
            if (_isLoadingOptions)
              const Center(child: CircularProgressIndicator())
            else if (_optionsError != null)
              AppLoadingError(message: _optionsError!, onRetry: _loadOptions)
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final service in _services)
                    FilterChip(
                      label: Text(service.name),
                      selected: _selectedServiceIds.contains(service.id),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _selectedServiceIds.add(service.id);
                        } else {
                          _selectedServiceIds.remove(service.id);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const AppSectionTitle('Profissionais habilitados'),
              Text(
                'Deixe sem selecionar para permitir qualquer profissional atender assinantes deste plano.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final professional in _professionals)
                    FilterChip(
                      label: Text(professional.name),
                      selected: _selectedProfessionalIds.contains(
                        professional.id,
                      ),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _selectedProfessionalIds.add(professional.id);
                        } else {
                          _selectedProfessionalIds.remove(professional.id);
                        }
                      }),
                    ),
                ],
              ),
            ],
            if (_saveError != null) ...[
              const SizedBox(height: 12),
              Text(
                _saveError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Detalhe e edicao de um plano de assinatura ja cadastrado, incluindo
/// trocar servicos/profissionais habilitados e desativar sem apagar.
class EditPlanPage extends StatefulWidget {
  const EditPlanPage({
    super.key,
    required this.plansRepository,
    required this.servicesRepository,
    required this.professionalsRepository,
    required this.plan,
  });

  final SubscriptionPlansRepository plansRepository;
  final ServicesRepository servicesRepository;
  final ProfessionalsRepository professionalsRepository;
  final SubscriptionPlanModel plan;

  @override
  State<EditPlanPage> createState() => _EditPlanPageState();
}

class _EditPlanPageState extends State<EditPlanPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.plan.name);
  late final _priceController = TextEditingController(
    text: (widget.plan.priceCents / 100)
        .toStringAsFixed(2)
        .replaceAll('.', ','),
  );
  late final _limitController = TextEditingController(
    text: widget.plan.usageLimit?.toString() ?? '',
  );
  late final Set<int> _selectedServiceIds = {
    for (final service in widget.plan.services) service.id,
  };
  late final Set<int> _selectedProfessionalIds = {
    ...widget.plan.professionalIds,
  };
  late bool _isActive = widget.plan.isActive;

  bool _isLoadingOptions = true;
  String? _optionsError;
  List<ServiceModel> _services = [];
  List<ProfessionalModel> _professionals = [];

  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoadingOptions = true;
      _optionsError = null;
    });

    try {
      final results = await Future.wait([
        widget.servicesRepository.index(),
        widget.professionalsRepository.index(),
      ]);

      if (!mounted) return;
      setState(() {
        _services = results[0] as List<ServiceModel>;
        _professionals = results[1] as List<ProfessionalModel>;
        _isLoadingOptions = false;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _optionsError = error.userMessage;
        _isLoadingOptions = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      await widget.plansRepository.update(
        id: widget.plan.id,
        name: _nameController.text.trim(),
        priceCents: parsePriceToCents(_priceController.text),
        usageLimit: _limitController.text.trim().isEmpty
            ? null
            : int.tryParse(_limitController.text.trim()),
        isActive: _isActive,
        serviceIds: _selectedServiceIds.toList(),
        professionalIds: _selectedProfessionalIds.toList(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Plano atualizado.')));
      Navigator.of(context).pop();
    } on QueuedForSyncException catch (queued) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(queued.userMessage)));
      Navigator.of(context).pop();
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _saveError = error.userMessage;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text(widget.plan.name)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome do plano'),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Preco mensal',
                hintText: 'Ex: 99,90',
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Informe o preco' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _limitController,
              decoration: const InputDecoration(
                labelText: 'Limite de usos mensais (opcional)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ativo'),
              subtitle: const Text(
                'Planos inativos somem da lista de contratacao do cliente.',
              ),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 8),
            const AppSectionTitle('Serviços inclusos'),
            if (_isLoadingOptions)
              const Center(child: CircularProgressIndicator())
            else if (_optionsError != null)
              AppLoadingError(message: _optionsError!, onRetry: _loadOptions)
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final service in _services)
                    FilterChip(
                      label: Text(service.name),
                      selected: _selectedServiceIds.contains(service.id),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _selectedServiceIds.add(service.id);
                        } else {
                          _selectedServiceIds.remove(service.id);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const AppSectionTitle('Profissionais habilitados'),
              Text(
                'Deixe sem selecionar para permitir qualquer profissional atender assinantes deste plano.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final professional in _professionals)
                    FilterChip(
                      label: Text(professional.name),
                      selected: _selectedProfessionalIds.contains(
                        professional.id,
                      ),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _selectedProfessionalIds.add(professional.id);
                        } else {
                          _selectedProfessionalIds.remove(professional.id);
                        }
                      }),
                    ),
                ],
              ),
            ],
            if (_saveError != null) ...[
              const SizedBox(height: 12),
              Text(
                _saveError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista de pagamentos pendentes de confirmacao manual.
class PendingPaymentsPage extends StatefulWidget {
  const PendingPaymentsPage({super.key, required this.paymentsRepository});

  final PaymentsRepository paymentsRepository;

  @override
  State<PendingPaymentsPage> createState() => _PendingPaymentsPageState();
}

class _PendingPaymentsPageState extends State<PendingPaymentsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<PaymentModel> _pending = [];

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
      final payments = await widget.paymentsRepository.index();

      if (!mounted) return;
      setState(() {
        // Pagamento ja marcado como "Fiado" pelo dono sai daqui e passa a
        // viver so em "Gestao do fiado" (mesmo filtro/comentario de
        // DebtManagementPage._load()) — senao ficava duplicado nas duas
        // telas, e aqui mostrando o valor cheio em vez do saldo restante
        // apos um recebimento parcial.
        _pending = payments
            .where(
              (payment) =>
                  payment.status == 'pending' && payment.method != 'fiado',
            )
            .toList();
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

  Future<void> _openConfirmation(PaymentModel payment) async {
    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentConfirmationPage(
          paymentsRepository: widget.paymentsRepository,
          payment: payment,
        ),
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _pending.removeWhere((item) => item.id == payment.id));
    } else if (confirmed == false && mounted) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else if (_pending.isEmpty) {
      body = const Center(child: Text('Nenhum pagamento pendente.'));
    } else {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final payment in _pending)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(
                  payment.isAvulso ? Icons.content_cut : Icons.price_check,
                ),
                title: Text(payment.clientName ?? 'Cliente'),
                subtitle: Text(
                  payment.isAvulso
                      ? '${payment.serviceName ?? 'Avulso'} - ${payment.methodLabel}'
                      : payment.methodLabel,
                ),
                trailing: Text(formatCents(payment.amountCents)),
                onTap: () => _openConfirmation(payment),
              ),
            ),
        ],
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Pagamentos pendentes')),
      body: body,
    );
  }
}

/// Detalhe por tras dos cards "Assinantes" e "MRR previsto" do dashboard: a
/// mesma lista de assinaturas ativas explica os dois numeros (MRR e a soma
/// dos precos dos planos aqui listados).
class ActiveSubscribersPage extends StatefulWidget {
  const ActiveSubscribersPage({
    super.key,
    required this.clientsRepository,
    required this.paymentsRepository,
  });

  final ClientsRepository clientsRepository;
  final PaymentsRepository paymentsRepository;

  @override
  State<ActiveSubscribersPage> createState() => _ActiveSubscribersPageState();
}

class _ActiveSubscribersPageState extends State<ActiveSubscribersPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ClientModel> _subscribers = [];

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
      final clients = await widget.clientsRepository.index();

      if (!mounted) return;
      setState(() {
        _subscribers = clients
            .where((client) => client.activeSubscription?.status == 'active')
            .toList();
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

  Future<void> _openClient(ClientModel client) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientDetailPage(
          clientsRepository: widget.clientsRepository,
          paymentsRepository: widget.paymentsRepository,
          client: client,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else if (_subscribers.isEmpty) {
      body = const Center(child: Text('Nenhum assinante ativo no momento.'));
    } else {
      final totalCents = _subscribers.fold<int>(
        0,
        (sum, client) =>
            sum + (client.activeSubscription?.plan?.priceCents ?? 0),
      );

      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const Icon(Icons.payments),
              title: Text(formatCents(totalCents)),
              subtitle: const Text('MRR previsto (soma dos planos ativos)'),
            ),
          ),
          for (final client in _subscribers)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.card_membership),
                title: Text(client.name),
                subtitle: Text(
                  client.activeSubscription?.plan?.name ?? 'Plano',
                ),
                trailing: Text(
                  formatCents(client.activeSubscription?.plan?.priceCents),
                ),
                onTap: () => _openClient(client),
              ),
            ),
        ],
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Assinantes ativos')),
      body: body,
    );
  }
}

/// Detalhe por tras do card "Agenda hoje" do dashboard: os agendamentos de
/// hoje agrupados por horario, reaproveitando o mesmo `AppDayTimeline` da
/// aba Agenda.
class TodayAppointmentsPage extends StatefulWidget {
  const TodayAppointmentsPage({
    super.key,
    required this.appointmentsRepository,
    required this.paymentsRepository,
  });

  final AppointmentsRepository appointmentsRepository;
  final PaymentsRepository paymentsRepository;

  @override
  State<TodayAppointmentsPage> createState() => _TodayAppointmentsPageState();
}

class _TodayAppointmentsPageState extends State<TodayAppointmentsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<AppointmentModel> _appointments = [];

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
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final appointments = await widget.appointmentsRepository.index(
        from: startOfDay,
        to: endOfDay,
      );

      if (!mounted) return;
      setState(() {
        _appointments = appointments;
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

  Future<void> _openDetail(AppointmentModel appointment) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppointmentDetailPage(
          appointment: appointment,
          appointmentsRepository: widget.appointmentsRepository,
          paymentsRepository: widget.paymentsRepository,
          canConfirmPayment: true,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else {
      body = Padding(
        padding: const EdgeInsets.all(16),
        child: AppDayTimeline(
          appointments: _appointments,
          onAppointmentTap: _openDetail,
          emptyMessage: 'Nenhum agendamento para hoje.',
        ),
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Agenda de hoje')),
      body: body,
    );
  }
}

/// Extrato por tras do card "Prevista hoje" (Painel Inteligente): lista os
/// agendamentos de hoje que contam para a receita, com o valor de cada um
/// (preco do servico), somando exatamente o valor mostrado no card.
class TodayRevenuePage extends StatefulWidget {
  const TodayRevenuePage({super.key, required this.appointmentsRepository});

  final AppointmentsRepository appointmentsRepository;

  @override
  State<TodayRevenuePage> createState() => _TodayRevenuePageState();
}

class _TodayRevenuePageState extends State<TodayRevenuePage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<AppointmentModel> _appointments = [];

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
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final appointments = await widget.appointmentsRepository.index(
        from: startOfDay,
        to: endOfDay,
      );

      if (!mounted) return;
      setState(() {
        _appointments =
            appointments
                .where((appointment) => appointment.countsTowardExpectedRevenue)
                .toList()
              // Decrescente: horario mais recente primeiro, mesmo padrao usado
              // no resto do app (AppDayTimeline).
              ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
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
    Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else if (_appointments.isEmpty) {
      body = const Center(child: Text('Nenhum agendamento hoje.'));
    } else {
      final totalCents = _appointments.fold<int>(
        0,
        (sum, appointment) => sum + (appointment.servicePriceCents ?? 0),
      );

      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: const Text('Total previsto hoje'),
              trailing: Text(
                formatCents(totalCents),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          for (final appointment in _appointments)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(
                  appointment.clientSubscriptionId == null
                      ? Icons.content_cut
                      : Icons.card_membership,
                ),
                title: Text(appointment.clientName ?? 'Cliente'),
                subtitle: Text(
                  '${appointment.serviceName ?? 'Servico'} - ${appointment.professionalName ?? ''} - '
                  '${appointment.clientSubscriptionId == null ? 'Avulso' : 'Assinatura'}',
                ),
                trailing: Text(formatCents(appointment.servicePriceCents ?? 0)),
              ),
            ),
        ],
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Receita prevista hoje')),
      body: body,
    );
  }
}

/// Uma linha de receita do mes: um pagamento confirmado na hora (sem nenhum
/// recibo, ex: `markPaid`), avulso ou de assinatura, ou um recebimento
/// parcial de um fiado (ver `PaymentController::receive` no backend) — cada
/// um contado no mes em que o dinheiro de fato entrou, nao so quando o
/// fiado inteiro e quitado.
class _RevenueEntry {
  const _RevenueEntry({
    required this.paymentId,
    required this.clientName,
    required this.description,
    required this.amountCents,
    required this.method,
    required this.date,
    required this.icon,
    required this.isEditable,
  });

  final int paymentId;
  final String clientName;
  final String description;
  final int amountCents;
  final String method;
  final DateTime date;
  final IconData icon;

  /// So o pagamento confirmado numa tacada so (sem nenhum recibo) e
  /// editavel/excluivel por aqui nesta rodada — um recebimento parcial de
  /// fiado levanta perguntas novas (o pagamento pai deveria voltar pra
  /// pendente? os outros recibos do mesmo fiado continuam validos?) que nao
  /// fazem parte do problema que motivou esta tela.
  final bool isEditable;
}

/// Extrato por tras do card "Receita do mês" (Painel Inteligente): mesma
/// soma de `walkin_revenue_month_cents` no backend — todo pagamento de fato
/// confirmado dentro do mes corrente, avulso ou de assinatura, mais
/// qualquer recebimento parcial de fiado recebido dentro do mes (mesmo que
/// o fiado ainda nao esteja quitado por completo). Diferente de "Recorrente
/// do mês", que e uma projecao pelo preco do plano das assinaturas ativas,
/// nao pelo que de fato foi pago.
class WalkinRevenueMonthPage extends StatefulWidget {
  const WalkinRevenueMonthPage({super.key, required this.paymentsRepository});

  final PaymentsRepository paymentsRepository;

  @override
  State<WalkinRevenueMonthPage> createState() => _WalkinRevenueMonthPageState();
}

class _WalkinRevenueMonthPageState extends State<WalkinRevenueMonthPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<_RevenueEntry> _entries = [];

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
      final payments = await widget.paymentsRepository.index();
      final now = DateTime.now();

      bool isThisMonth(DateTime? date) =>
          date != null && date.year == now.year && date.month == now.month;

      final entries = <_RevenueEntry>[];

      for (final payment in payments) {
        final icon = payment.isAvulso ? Icons.content_cut : Icons.autorenew;
        final origin = payment.serviceName ?? payment.planName ?? 'Pagamento';

        // Confirmado na hora, sem recibo: entra pelo valor cheio no mes do
        // paid_at. Se tiver recibo, ja e contado abaixo — senao contaria
        // duas vezes o fiado que terminou de ser quitado por recibos.
        if (payment.status == 'paid' && payment.receipts.isEmpty) {
          final paidAt = payment.paidAt == null
              ? null
              : DateTime.tryParse(payment.paidAt!);
          if (isThisMonth(paidAt)) {
            entries.add(
              _RevenueEntry(
                paymentId: payment.id,
                clientName: payment.clientName ?? 'Cliente',
                description: '$origin - ${payment.methodLabel}',
                amountCents: payment.amountCents,
                method: payment.method,
                date: paidAt!,
                icon: icon,
                isEditable: true,
              ),
            );
          }
        }

        for (final receipt in payment.receipts) {
          final receivedAt = DateTime.tryParse(receipt.receivedAt);
          if (isThisMonth(receivedAt)) {
            entries.add(
              _RevenueEntry(
                paymentId: payment.id,
                clientName: payment.clientName ?? 'Cliente',
                description: '$origin - recebimento (${receipt.methodLabel})',
                amountCents: receipt.amountCents,
                method: receipt.method,
                date: receivedAt!,
                icon: icon,
                isEditable: false,
              ),
            );
          }
        }
      }

      entries.sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) return;
      setState(() {
        _entries = entries;
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

  Future<void> _openEntry(_RevenueEntry entry) async {
    if (!entry.isEditable) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditPaymentEntryPage(
          paymentsRepository: widget.paymentsRepository,
          paymentId: entry.paymentId,
          amountCents: entry.amountCents,
          method: entry.method,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else if (_entries.isEmpty) {
      body = const Center(child: Text('Nenhuma receita confirmada este mês.'));
    } else {
      final totalCents = _entries.fold<int>(
        0,
        (sum, entry) => sum + entry.amountCents,
      );

      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: const Text('Total no mês'),
              trailing: Text(
                formatCents(totalCents),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          for (final entry in _entries)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(entry.icon),
                title: Text(entry.clientName),
                subtitle: Text(entry.description),
                trailing: Text(formatCents(entry.amountCents)),
                onTap: entry.isEditable ? () => _openEntry(entry) : null,
              ),
            ),
        ],
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Receita do mês')),
      body: body,
    );
  }
}

/// Corrige ou remove um lancamento confirmado (ex: dono lancou o mesmo
/// pagamento duas vezes por engano). So alcancavel a partir de "Receita do
/// mês" pra lancamentos "pagos numa tacada so" (ver `_RevenueEntry.isEditable`).
class EditPaymentEntryPage extends StatefulWidget {
  const EditPaymentEntryPage({
    super.key,
    required this.paymentsRepository,
    required this.paymentId,
    required this.amountCents,
    required this.method,
  });

  final PaymentsRepository paymentsRepository;
  final int paymentId;
  final int amountCents;
  final String method;

  @override
  State<EditPaymentEntryPage> createState() => _EditPaymentEntryPageState();
}

class _EditPaymentEntryPageState extends State<EditPaymentEntryPage> {
  late final _amountController = TextEditingController(
    text: (widget.amountCents / 100).toStringAsFixed(2).replaceAll('.', ','),
  );
  final _notesController = TextEditingController();
  late String _selectedMethod = widget.method;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.paymentsRepository.update(
        id: widget.paymentId,
        amountCents: parsePriceToCents(_amountController.text),
        method: _selectedMethod,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lançamento atualizado.')));
      Navigator.of(context).pop(true);
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.userMessage;
        _isSaving = false;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: const Text(
          'Essa ação não pode ser desfeita. Use isso pra corrigir um lançamento duplicado ou registrado por engano.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await widget.paymentsRepository.delete(widget.paymentId);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lançamento excluído.')));
      Navigator.of(context).pop(true);
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.userMessage;
        _isDeleting = false;
      });
    }
  }

  static const _editableMethods = {
    'pix': 'PIX',
    'credit_card': 'Cartão crédito',
    'debit_card': 'Cartão débito',
    'cash': 'Dinheiro',
  };

  @override
  Widget build(BuildContext context) {
    final isBusy = _isSaving || _isDeleting;

    return AppScaffold(
      appBar: AppBar(title: const Text('Editar lançamento')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Valor'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          const AppSectionTitle('Forma de pagamento'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in _editableMethods.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _selectedMethod == entry.key,
                  onSelected: isBusy
                      ? null
                      : (_) => setState(() => _selectedMethod = entry.key),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Observação (opcional)',
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isBusy ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: isBusy ? null : _confirmDelete,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
            child: _isDeleting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                : const Text('Excluir lançamento'),
          ),
        ],
      ),
    );
  }
}

class DebtManagementPage extends StatefulWidget {
  const DebtManagementPage({super.key, required this.paymentsRepository});

  final PaymentsRepository paymentsRepository;

  @override
  State<DebtManagementPage> createState() => _DebtManagementPageState();
}

class _DebtManagementPageState extends State<DebtManagementPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<PaymentModel> _pending = [];

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
      final payments = await widget.paymentsRepository.index();

      if (!mounted) return;
      setState(() {
        // So o que o dono de fato marcou como "Fiado" na confirmacao — um
        // avulso comum ainda aguardando a primeira confirmacao tambem fica
        // com status=pending, mas nao e devedor de fiado.
        _pending = payments
            .where(
              (payment) =>
                  payment.status == 'pending' && payment.method == 'fiado',
            )
            .toList();
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

  Future<void> _openPayment(PaymentModel payment) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DebtDetailPage(
          payment: payment,
          paymentsRepository: widget.paymentsRepository,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final totalOpen = _pending.fold<int>(
      0,
      (total, payment) => total + payment.remainingCents,
    );

    final Widget body;
    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Total em aberto'),
              trailing: Text(formatCents(totalOpen)),
            ),
          ),
          const SizedBox(height: 16),
          if (_pending.isEmpty)
            const Card(child: ListTile(title: Text('Nenhum fiado em aberto.')))
          else
            for (final payment in _pending)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text(payment.clientName ?? 'Cliente'),
                  subtitle: Text(
                    '${payment.serviceName ?? 'Assinatura'} - recebido ${formatCents(payment.receivedCents)}',
                  ),
                  trailing: Text(formatCents(payment.remainingCents)),
                  onTap: () => _openPayment(payment),
                ),
              ),
        ],
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Gestão do fiado')),
      body: body,
    );
  }
}

class DebtDetailPage extends StatefulWidget {
  const DebtDetailPage({
    super.key,
    required this.payment,
    required this.paymentsRepository,
  });

  final PaymentModel payment;
  final PaymentsRepository paymentsRepository;

  @override
  State<DebtDetailPage> createState() => _DebtDetailPageState();
}

class _DebtDetailPageState extends State<DebtDetailPage> {
  final _amountController = TextEditingController();
  String _selectedMethod = 'pix';
  PaymentModel? _payment;
  bool _isSaving = false;
  String? _errorMessage;

  PaymentModel get payment => _payment ?? widget.payment;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _receive() async {
    final amount = parsePriceToCents(_amountController.text);
    if (amount <= 0) {
      setState(() => _errorMessage = 'Informe um valor recebido.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updated = await widget.paymentsRepository.receive(
        payment.id,
        amountCents: amount,
        method: _selectedMethod,
      );

      if (!mounted) return;
      setState(() {
        _payment = updated;
        _isSaving = false;
        _amountController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.status == 'paid'
                ? 'Fiado quitado.'
                : 'Recebimento lancado.',
          ),
        ),
      );
    } on QueuedForSyncException catch (queued) {
      // Sem conexao: nao ha resposta do servidor pra saber se o fiado ficou
      // quitado, so que o recebimento foi registrado localmente.
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _amountController.clear();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(queued.userMessage)));
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.userMessage;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Detalhe do fiado')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Cliente'),
                  trailing: Text(payment.clientName ?? '-'),
                ),
                ListTile(
                  title: const Text('Total'),
                  trailing: Text(formatCents(payment.amountCents)),
                ),
                ListTile(
                  title: const Text('Recebido'),
                  trailing: Text(formatCents(payment.receivedCents)),
                ),
                ListTile(
                  title: const Text('Pendente'),
                  trailing: Text(formatCents(payment.remainingCents)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AppSectionTitle('Recebimentos'),
          if (payment.receipts.isEmpty)
            const Card(
              child: ListTile(title: Text('Nenhum recebimento ainda.')),
            )
          else
            for (final receipt in payment.receipts)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: Text(formatCents(receipt.amountCents)),
                  subtitle: Text(receipt.method),
                ),
              ),
          if (payment.status != 'paid') ...[
            const SizedBox(height: 16),
            const AppSectionTitle('Lancar recebimento'),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor recebido'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final method in _paidPaymentMethods)
                  ChoiceChip(
                    label: Text(_paymentMethodLabel(method)),
                    selected: _selectedMethod == method,
                    onSelected: _isSaving
                        ? null
                        : (_) => setState(() => _selectedMethod = method),
                  ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSaving ? null : _receive,
              icon: const Icon(Icons.add_card),
              label: const Text('Lancar recebimento'),
            ),
          ],
        ],
      ),
    );
  }

  static const _paidPaymentMethods = [
    'pix',
    'credit_card',
    'debit_card',
    'cash',
  ];

  String _paymentMethodLabel(String method) => switch (method) {
    'pix' => 'PIX',
    'credit_card' => 'Cartão crédito',
    'debit_card' => 'Cartão débito',
    'cash' => 'Dinheiro',
    _ => method,
  };
}

class ProfessionalCommissionsPage extends StatefulWidget {
  const ProfessionalCommissionsPage({
    super.key,
    required this.professionalsRepository,
    required this.tenantRepository,
    required this.dashboardRepository,
  });

  final ProfessionalsRepository professionalsRepository;
  final TenantRepository tenantRepository;
  final DashboardRepository dashboardRepository;

  @override
  State<ProfessionalCommissionsPage> createState() =>
      _ProfessionalCommissionsPageState();
}

class _ProfessionalCommissionsPageState
    extends State<ProfessionalCommissionsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ProfessionalModel> _professionals = [];
  Map<int, TeamPerformanceEntryModel> _performanceByProfessional = {};
  int _paymentDay = 5;

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
      final professionals = await widget.professionalsRepository.index();
      final tenant = await widget.tenantRepository.show();
      final performance = await widget.dashboardRepository.teamPerformance();

      if (!mounted) return;
      setState(() {
        _performanceByProfessional = {
          for (final entry in performance) entry.professionalId: entry,
        };
        _professionals = professionals;
        _paymentDay = tenant.professionalPaymentDay;
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

  Future<void> _changePaymentDay() async {
    final day = await showDialog<int>(
      context: context,
      builder: (_) => _ChangePaymentDayDialog(initialDay: _paymentDay),
    );

    if (day == null) return;

    try {
      final tenant = await widget.tenantRepository.updateProfessionalPaymentDay(
        day.clamp(1, 31),
      );
      if (!mounted) return;
      setState(() => _paymentDay = tenant.professionalPaymentDay);
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.userMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Dia de pagamento'),
              trailing: Text('Dia $_paymentDay'),
              onTap: _changePaymentDay,
            ),
          ),
          const SizedBox(height: 16),
          for (final professional in _professionals)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.badge),
                title: Text(professional.name),
                subtitle: Text(
                  'Comissão ${professional.commissionPercentage ?? 0}% - '
                  'A receber ${formatCents(_performanceByProfessional[professional.id]?.netCents ?? 0)}',
                ),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfessionalCommissionDetailPage(
                        professional: professional,
                        professionalsRepository: widget.professionalsRepository,
                      ),
                    ),
                  );
                  _load();
                },
              ),
            ),
        ],
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Comissoes')),
      body: body,
    );
  }
}

/// Dialogo do campo unico "Dia de pagamento", como widget proprio (nao
/// inline) para que o `TextEditingController` seja criado e descartado pelo
/// ciclo de vida do proprio dialogo (`initState`/`dispose`). Descartar o
/// controller manualmente logo apos `await showDialog(...)` retornar e
/// inseguro: a rota do dialogo ainda esta sendo removida da arvore (animacao
/// de saida), entao o `TextField` pode tentar reconstruir com o controller
/// ja descartado e derrubar a tela ("Nao foi possivel carregar esta tela").
class _ChangePaymentDayDialog extends StatefulWidget {
  const _ChangePaymentDayDialog({required this.initialDay});

  final int initialDay;

  @override
  State<_ChangePaymentDayDialog> createState() =>
      _ChangePaymentDayDialogState();
}

class _ChangePaymentDayDialogState extends State<_ChangePaymentDayDialog> {
  late final _controller = TextEditingController(text: '${widget.initialDay}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dia de pagamento'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Dia do mes'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(int.tryParse(_controller.text)),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class ProfessionalCommissionDetailPage extends StatefulWidget {
  const ProfessionalCommissionDetailPage({
    super.key,
    required this.professional,
    required this.professionalsRepository,
  });

  final ProfessionalModel professional;
  final ProfessionalsRepository professionalsRepository;

  @override
  State<ProfessionalCommissionDetailPage> createState() =>
      _ProfessionalCommissionDetailPageState();
}

class _ProfessionalCommissionDetailPageState
    extends State<ProfessionalCommissionDetailPage> {
  bool _isLoading = true;
  String? _errorMessage;
  ProfessionalFinanceModel? _finance;

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
      final finance = await widget.professionalsRepository.finance(
        widget.professional.id,
      );

      if (!mounted) return;
      setState(() {
        _finance = finance;
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

  Future<void> _addAdvance() async {
    final result = await showDialog<_AddAdvanceResult>(
      context: context,
      builder: (_) => const _AddAdvanceDialog(),
    );

    if (result == null || result.amountCents <= 0) return;

    try {
      await widget.professionalsRepository.createAdvance(
        professionalId: widget.professional.id,
        amountCents: result.amountCents,
        notes: result.notes,
      );
      await _load();
    } on QueuedForSyncException catch (queued) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(queued.userMessage)));
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.userMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else {
      final finance = _finance!;
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppMetricGrid(
            metrics: [
              AppMetric(
                'Atendimentos',
                '${finance.completedCount}',
                Icons.content_cut,
              ),
              AppMetric(
                'Comissão',
                formatCents(finance.commissionCents),
                Icons.percent,
              ),
              AppMetric(
                'Adiantado',
                formatCents(finance.advancesCents),
                Icons.payments,
              ),
              AppMetric(
                'A receber',
                formatCents(finance.netCents),
                Icons.wallet,
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _addAdvance,
            icon: const Icon(Icons.add_card),
            label: const Text('Lançar adiantamento'),
          ),
          const SizedBox(height: 16),
          const AppSectionTitle('Adiantamentos'),
          if (finance.advances.isEmpty)
            const Card(child: ListTile(title: Text('Nenhum adiantamento.')))
          else
            // Decrescente: adiantamento mais recente primeiro, mesmo padrao
            // usado no resto do app (AppDayTimeline).
            for (final advance
                in finance.advances.toList()
                  ..sort((a, b) => b.paidAt.compareTo(a.paidAt)))
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: Text(formatCents(advance.amountCents)),
                  subtitle: Text(
                    '${advance.notes ?? 'Adiantamento'} - ${formatDateTime(advance.paidAt)}',
                  ),
                ),
              ),
        ],
      );
    }

    return AppScaffold(
      appBar: AppBar(title: Text(widget.professional.name)),
      body: body,
    );
  }
}

/// Resultado do dialogo "Lançar adiantamento" (`_AddAdvanceDialog`).
class _AddAdvanceResult {
  const _AddAdvanceResult(this.amountCents, this.notes);

  final int amountCents;
  final String? notes;
}

/// Dialogo de "Lançar adiantamento", como widget proprio (nao inline) pelo
/// mesmo motivo do `_ChangePaymentDayDialog`: os `TextEditingController`s
/// precisam ser criados e descartados pelo ciclo de vida do proprio
/// dialogo, nao manualmente logo apos `await showDialog(...)` retornar —
/// bug real reportado pelo usuario ("Nao foi possivel carregar esta tela"
/// apos salvar, embora o adiantamento fosse persistido corretamente).
class _AddAdvanceDialog extends StatefulWidget {
  const _AddAdvanceDialog();

  @override
  State<_AddAdvanceDialog> createState() => _AddAdvanceDialogState();
}

class _AddAdvanceDialogState extends State<_AddAdvanceDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final amount = parsePriceToCents(_amountController.text);
    final notes = _notesController.text.trim();
    Navigator.of(
      context,
    ).pop(_AddAdvanceResult(amount, notes.isEmpty ? null : notes));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lançar adiantamento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Valor'),
          ),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Observacao'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
  }
}

/// Detalhe de um cliente com os dados reais de plano e pagamento.
/// Detalhe e edicao de um cliente ja cadastrado. Plano e pagamento sao
/// somente leitura aqui (vem da assinatura, nao do cadastro do cliente).
class ClientDetailPage extends StatefulWidget {
  const ClientDetailPage({
    super.key,
    required this.clientsRepository,
    required this.paymentsRepository,
    required this.client,
  });

  final ClientsRepository clientsRepository;
  final PaymentsRepository paymentsRepository;
  final ClientModel client;

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.client.name);
  late final _phoneController = TextEditingController(
    text: widget.client.phone,
  );
  late final _notesController = TextEditingController(
    text: widget.client.notes ?? '',
  );
  late bool _isActive = widget.client.status != 'inactive';
  late ClientSubscriptionModel? _subscription =
      widget.client.activeSubscription;

  bool _isSaving = false;
  bool _isRegisteringPayment = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _registerPayment() async {
    final subscription = _subscription;
    if (subscription == null) return;

    setState(() {
      _isRegisteringPayment = true;
      _errorMessage = null;
    });

    try {
      final payment = await widget.paymentsRepository.create(
        clientSubscriptionId: subscription.id,
        amountCents: subscription.plan?.priceCents ?? 0,
        status: 'pending',
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentConfirmationPage(
            paymentsRepository: widget.paymentsRepository,
            payment: payment,
          ),
        ),
      );

      // Recarrega o cliente para refletir o novo status de pagamento da
      // assinatura, ja sincronizado no backend pelo fluxo de confirmacao.
      final clients = await widget.clientsRepository.index();
      final refreshed = clients
          .where((c) => c.id == widget.client.id)
          .firstOrNull;

      if (!mounted) return;
      setState(
        () => _subscription = refreshed?.activeSubscription ?? subscription,
      );
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.userMessage);
    } finally {
      if (mounted) setState(() => _isRegisteringPayment = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.clientsRepository.update(
        id: widget.client.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        status: _isActive ? 'active' : 'inactive',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cliente atualizado.')));
      Navigator.of(context).pop();
    } on QueuedForSyncException catch (queued) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(queued.userMessage)));
      Navigator.of(context).pop();
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.userMessage;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscription = _subscription;

    return AppScaffold(
      appBar: AppBar(title: Text(widget.client.name)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                hintText: 'Ex: 11912345678',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Informe o telefone'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Observações'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ativo'),
              subtitle: const Text(
                'Clientes inativos continuam no historico, sem poder agendar.',
              ),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 16),
            const AppSectionTitle('Assinatura'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Plano'),
                    trailing: Text(
                      subscription?.plan?.name ?? 'Sem plano ativo',
                    ),
                  ),
                  if (subscription != null) ...[
                    ListTile(
                      title: const Text('Pagamento'),
                      trailing: Text(subscription.paymentStatusLabel),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isRegisteringPayment
                              ? null
                              : _registerPayment,
                          icon: _isRegisteringPayment
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.price_check),
                          label: const Text('Registrar pagamento'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Catalogo do estabelecimento: servicos e profissionais, cada um em uma
/// sub-aba para nao competir por espaco na barra de navegacao principal.
class CatalogPage extends StatefulWidget {
  const CatalogPage({
    super.key,
    required this.servicesRepository,
    required this.professionalsRepository,
    required this.authSession,
  });

  final ServicesRepository servicesRepository;
  final ProfessionalsRepository professionalsRepository;
  final AuthSession authSession;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Catalogo'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Serviços'),
            Tab(text: 'Profissionais'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ServicesPage(servicesRepository: widget.servicesRepository),
          ProfessionalsPage(
            professionalsRepository: widget.professionalsRepository,
            servicesRepository: widget.servicesRepository,
            authSession: widget.authSession,
          ),
        ],
      ),
    );
  }
}

/// Lista de servicos do estabelecimento, com atalho para cadastrar um novo.
class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key, required this.servicesRepository});

  final ServicesRepository servicesRepository;

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ServiceModel> _services = [];

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
      final services = await widget.servicesRepository.index();

      if (!mounted) return;
      setState(() {
        _services = services;
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

  Future<void> _openNewService() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            NewServicePage(servicesRepository: widget.servicesRepository),
      ),
    );
    _load();
  }

  Future<void> _openService(ServiceModel service) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditServicePage(
          servicesRepository: widget.servicesRepository,
          service: service,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else if (_services.isEmpty) {
      body = const Center(child: Text('Nenhum serviço cadastrado ainda.'));
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          for (final service in _services)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.content_cut),
                title: Text(service.name),
                subtitle: Text(
                  formatDuration(Duration(minutes: service.durationMinutes)),
                ),
                trailing: Text(formatCents(service.priceCents)),
                onTap: () => _openService(service),
              ),
            ),
        ],
      );
    }

    return Stack(
      children: [
        body,
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _openNewService,
            tooltip: 'Cadastrar serviço',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

/// Formulario de cadastro de servico, gravado direto na API.
class NewServicePage extends StatefulWidget {
  const NewServicePage({super.key, required this.servicesRepository});

  final ServicesRepository servicesRepository;

  @override
  State<NewServicePage> createState() => _NewServicePageState();
}

class _NewServicePageState extends State<NewServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.servicesRepository.create(
        name: _nameController.text.trim(),
        durationMinutes: int.parse(_durationController.text.trim()),
        priceCents: _priceController.text.trim().isEmpty
            ? null
            : parsePriceToCents(_priceController.text),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Serviço ${_nameController.text} cadastrado.')),
      );
      Navigator.of(context).pop();
    } on QueuedForSyncException catch (queued) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(queued.userMessage)));
      Navigator.of(context).pop();
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.userMessage;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Cadastrar serviço')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome do serviço'),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(labelText: 'Duração (minutos)'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Informe a duração';
                return int.tryParse(value) == null
                    ? 'Informe um número válido'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Preco (opcional)',
                hintText: 'Ex: 60,00',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descricao (opcional)',
              ),
              maxLines: 3,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Detalhe e edicao de um servico ja cadastrado.
class EditServicePage extends StatefulWidget {
  const EditServicePage({
    super.key,
    required this.servicesRepository,
    required this.service,
  });

  final ServicesRepository servicesRepository;
  final ServiceModel service;

  @override
  State<EditServicePage> createState() => _EditServicePageState();
}

class _EditServicePageState extends State<EditServicePage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.service.name);
  late final _durationController = TextEditingController(
    text: widget.service.durationMinutes.toString(),
  );
  late final _priceController = TextEditingController(
    text: widget.service.priceCents == null
        ? ''
        : (widget.service.priceCents! / 100)
              .toStringAsFixed(2)
              .replaceAll('.', ','),
  );
  late final _descriptionController = TextEditingController(
    text: widget.service.description ?? '',
  );
  late bool _isActive = widget.service.isActive;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.servicesRepository.update(
        id: widget.service.id,
        name: _nameController.text.trim(),
        durationMinutes: int.parse(_durationController.text.trim()),
        priceCents: _priceController.text.trim().isEmpty
            ? null
            : parsePriceToCents(_priceController.text),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isActive: _isActive,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Serviço atualizado.')));
      Navigator.of(context).pop();
    } on QueuedForSyncException catch (queued) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(queued.userMessage)));
      Navigator.of(context).pop();
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.userMessage;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text(widget.service.name)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome do serviço'),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(labelText: 'Duração (minutos)'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Informe a duração';
                return int.tryParse(value) == null
                    ? 'Informe um número válido'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Preco (opcional)',
                hintText: 'Ex: 60,00',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descricao (opcional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ativo'),
              subtitle: const Text(
                'Serviços inativos somem do agendamento do cliente.',
              ),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista de profissionais do estabelecimento, com atalho para cadastrar um
/// novo e para reabrir um existente e revisar servicos habilitados.
class ProfessionalsPage extends StatefulWidget {
  const ProfessionalsPage({
    super.key,
    required this.professionalsRepository,
    required this.servicesRepository,
    required this.authSession,
  });

  final ProfessionalsRepository professionalsRepository;
  final ServicesRepository servicesRepository;
  final AuthSession authSession;

  @override
  State<ProfessionalsPage> createState() => _ProfessionalsPageState();
}

class _ProfessionalsPageState extends State<ProfessionalsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ProfessionalModel> _professionals = [];

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
      final professionals = await widget.professionalsRepository.index();

      if (!mounted) return;
      setState(() {
        _professionals = professionals;
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

  Future<void> _openNewProfessional() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewProfessionalPage(
          professionalsRepository: widget.professionalsRepository,
          servicesRepository: widget.servicesRepository,
          authSession: widget.authSession,
        ),
      ),
    );
    _load();
  }

  Future<void> _openProfessional(ProfessionalModel professional) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfessionalPage(
          professionalsRepository: widget.professionalsRepository,
          servicesRepository: widget.servicesRepository,
          professional: professional,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else if (_professionals.isEmpty) {
      body = const Center(child: Text('Nenhum profissional cadastrado ainda.'));
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          for (final professional in _professionals)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.badge),
                title: Text(professional.name),
                subtitle: Text(professional.specialty ?? 'Sem especialidade'),
                trailing: professional.isActive ? null : const Text('Inativo'),
                onTap: () => _openProfessional(professional),
              ),
            ),
        ],
      );
    }

    return Stack(
      children: [
        body,
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _openNewProfessional,
            tooltip: 'Cadastrar profissional',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

/// Formulario de cadastro de profissional, com selecao dos servicos
/// habilitados (spec 4.1).
class NewProfessionalPage extends StatefulWidget {
  const NewProfessionalPage({
    super.key,
    required this.professionalsRepository,
    required this.servicesRepository,
    required this.authSession,
  });

  final ProfessionalsRepository professionalsRepository;
  final ServicesRepository servicesRepository;
  final AuthSession authSession;

  @override
  State<NewProfessionalPage> createState() => _NewProfessionalPageState();
}

class _NewProfessionalPageState extends State<NewProfessionalPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _commissionController = TextEditingController();
  final _passwordController = TextEditingController();
  final Set<int> _selectedServiceIds = {};
  List<ProfessionalWorkingHourModel> _workingHours = [];
  bool _isSelf = false;

  bool _isLoadingServices = true;
  String? _servicesError;
  List<ServiceModel> _services = [];

  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoadingServices = true;
      _servicesError = null;
    });

    try {
      final services = await widget.servicesRepository.index();

      if (!mounted) return;
      setState(() {
        _services = services;
        _isLoadingServices = false;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _servicesError = error.userMessage;
        _isLoadingServices = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _commissionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      await widget.professionalsRepository.create(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        specialty: _specialtyController.text.trim().isEmpty
            ? null
            : _specialtyController.text.trim(),
        commissionPercentage: _commissionController.text.trim().isEmpty
            ? null
            : int.tryParse(_commissionController.text.trim()),
        password: _passwordController.text.isEmpty
            ? null
            : _passwordController.text,
        serviceIds: _selectedServiceIds.toList(),
        workingHours: _workingHours,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profissional ${_nameController.text} cadastrado.'),
        ),
      );
      Navigator.of(context).pop();
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _saveError = error.userMessage;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Cadastrar profissional')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _isSelf,
              onChanged: (checked) => setState(() {
                _isSelf = checked ?? false;
                if (_isSelf) {
                  if (_nameController.text.trim().isEmpty) {
                    _nameController.text = widget.authSession.user?.name ?? '';
                  }
                  _emailController.clear();
                  _passwordController.clear();
                }
              }),
              title: const Text('Este profissional sou eu (dono)'),
              subtitle: const Text(
                'Você continua entrando no app com a sua própria conta de '
                'dono — não é preciso um e-mail nem uma senha separados '
                'para o seu perfil de profissional.',
              ),
            ),
            if (!_isSelf) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail (opcional)',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefone (opcional)',
                hintText: 'Ex: 11912345678',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _specialtyController,
              decoration: const InputDecoration(
                labelText: 'Especialidade (opcional)',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commissionController,
              decoration: const InputDecoration(
                labelText: 'Comissão % (opcional)',
              ),
              keyboardType: TextInputType.number,
            ),
            if (!_isSelf) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Senha de acesso ao app (opcional)',
                  hintText: 'Deixe em branco para não liberar login',
                ),
                obscureText: true,
              ),
            ],
            const SizedBox(height: 16),
            const AppSectionTitle('Serviços habilitados'),
            Text(
              'Deixe sem selecionar para permitir qualquer serviço cadastrado.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (_isLoadingServices)
              const Center(child: CircularProgressIndicator())
            else if (_servicesError != null)
              AppLoadingError(message: _servicesError!, onRetry: _loadServices)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final service in _services)
                    FilterChip(
                      label: Text(service.name),
                      selected: _selectedServiceIds.contains(service.id),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _selectedServiceIds.add(service.id);
                        } else {
                          _selectedServiceIds.remove(service.id);
                        }
                      }),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            const AppSectionTitle('Horário de trabalho'),
            Text(
              'Usado para calcular o indice de ocupacao. Deixe os dias '
              'desligados se o profissional ainda nao tem horario definido.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            WorkingHoursEditor(
              initialWorkingHours: const [],
              onChanged: (workingHours) =>
                  setState(() => _workingHours = workingHours),
            ),
            if (_saveError != null) ...[
              const SizedBox(height: 12),
              Text(
                _saveError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Edicao de um profissional existente. Foco principal e revisar os
/// servicos habilitados (spec 4.1); os demais campos tambem podem ser
/// atualizados pelo mesmo formulario.
class EditProfessionalPage extends StatefulWidget {
  const EditProfessionalPage({
    super.key,
    required this.professionalsRepository,
    required this.servicesRepository,
    required this.professional,
  });

  final ProfessionalsRepository professionalsRepository;
  final ServicesRepository servicesRepository;
  final ProfessionalModel professional;

  @override
  State<EditProfessionalPage> createState() => _EditProfessionalPageState();
}

class _EditProfessionalPageState extends State<EditProfessionalPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.professional.name,
  );
  late final _specialtyController = TextEditingController(
    text: widget.professional.specialty ?? '',
  );
  late final _commissionController = TextEditingController(
    text: widget.professional.commissionPercentage?.toString() ?? '',
  );
  late final Set<int> _selectedServiceIds = {...widget.professional.serviceIds};
  late bool _isActive = widget.professional.isActive;
  late List<ProfessionalWorkingHourModel> _workingHours =
      widget.professional.workingHours;

  bool _isLoadingServices = true;
  String? _servicesError;
  List<ServiceModel> _services = [];

  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoadingServices = true;
      _servicesError = null;
    });

    try {
      final services = await widget.servicesRepository.index();

      if (!mounted) return;
      setState(() {
        _services = services;
        _isLoadingServices = false;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _servicesError = error.userMessage;
        _isLoadingServices = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      await widget.professionalsRepository.update(
        id: widget.professional.id,
        name: _nameController.text.trim(),
        specialty: _specialtyController.text.trim().isEmpty
            ? null
            : _specialtyController.text.trim(),
        commissionPercentage: _commissionController.text.trim().isEmpty
            ? null
            : int.tryParse(_commissionController.text.trim()),
        isActive: _isActive,
        serviceIds: _selectedServiceIds.toList(),
        workingHours: _workingHours,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profissional atualizado.')));
      Navigator.of(context).pop();
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _saveError = error.userMessage;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text(widget.professional.name)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _specialtyController,
              decoration: const InputDecoration(labelText: 'Especialidade'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commissionController,
              decoration: const InputDecoration(labelText: 'Comissão %'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ativo'),
              subtitle: const Text('Profissionais inativos somem da agenda.'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 8),
            const AppSectionTitle('Serviços habilitados'),
            Text(
              'Deixe sem selecionar para permitir qualquer serviço cadastrado.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (_isLoadingServices)
              const Center(child: CircularProgressIndicator())
            else if (_servicesError != null)
              AppLoadingError(message: _servicesError!, onRetry: _loadServices)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final service in _services)
                    FilterChip(
                      label: Text(service.name),
                      selected: _selectedServiceIds.contains(service.id),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _selectedServiceIds.add(service.id);
                        } else {
                          _selectedServiceIds.remove(service.id);
                        }
                      }),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            const AppSectionTitle('Horário de trabalho'),
            Text(
              'Usado para calcular o indice de ocupacao.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            WorkingHoursEditor(
              initialWorkingHours: widget.professional.workingHours,
              onChanged: (workingHours) =>
                  setState(() => _workingHours = workingHours),
            ),
            if (_saveError != null) ...[
              const SizedBox(height: 12),
              Text(
                _saveError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Verde/amarelo/vermelho conforme o percentual, reaproveitado pela barra
/// da tela de ocupacao e pelas barras de "Desempenho da equipe".
Color _percentageColor(BuildContext context, int percentage) {
  if (percentage >= 80) return Colors.green;
  if (percentage >= 40) return Colors.amber.shade800;
  return Theme.of(context).colorScheme.error;
}

/// Indice de ocupacao da equipe (roadmap Fase 4): para cada profissional
/// ativo, quanto do horario de trabalho cadastrado (semana corrente) esta
/// ocupado por agendamentos, dia a dia. Ajuda o dono a distribuir melhor
/// os atendimentos entre a equipe.
class OccupancyPage extends StatefulWidget {
  const OccupancyPage({
    super.key,
    required this.dashboardRepository,
    required this.professionalsRepository,
    required this.servicesRepository,
  });

  final DashboardRepository dashboardRepository;
  final ProfessionalsRepository professionalsRepository;
  final ServicesRepository servicesRepository;

  @override
  State<OccupancyPage> createState() => _OccupancyPageState();
}

class _OccupancyPageState extends State<OccupancyPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<OccupancyProfessionalModel> _occupancy = [];
  List<ProfessionalModel> _professionals = [];

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
      final results = await Future.wait([
        widget.dashboardRepository.occupancy(),
        widget.professionalsRepository.index(),
      ]);

      if (!mounted) return;
      setState(() {
        _occupancy = results[0] as List<OccupancyProfessionalModel>;
        _professionals = results[1] as List<ProfessionalModel>;
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

  /// Toque no card leva o dono a editar o horario de trabalho recorrente
  /// do profissional (mesma tela de cadastro/edicao, com o
  /// `WorkingHoursEditor` ja existente) — configurar ocupacao e cadastrar
  /// horario sao a mesma acao, o dono nao precisa saber que sao telas
  /// diferentes.
  Future<void> _openEdit(OccupancyProfessionalModel occupancy) async {
    final professional = _professionals.firstWhere(
      (item) => item.id == occupancy.professionalId,
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfessionalPage(
          professionalsRepository: widget.professionalsRepository,
          servicesRepository: widget.servicesRepository,
          professional: professional,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else if (_occupancy.isEmpty) {
      body = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhum profissional com horário de trabalho configurado ainda. '
            'Toque em "Cadastrar horário" para configurar.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Toque num profissional para ver ou ajustar o horário de trabalho '
            'dele.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          for (final professional in _occupancy)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _openEdit(professional),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              professional.professionalName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (professional.days.isEmpty)
                        Text(
                          'Sem horário de trabalho configurado.',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else
                        for (final day in professional.days)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text(weekdayLabels[day.weekday]),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: day.percentage / 100,
                                      minHeight: 10,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                      color: _percentageColor(
                                        context,
                                        day.percentage,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    '${day.percentage}%',
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                if (day.hasOverride) ...[
                                  const SizedBox(width: 4),
                                  Tooltip(
                                    message: 'Horário ajustado neste dia',
                                    child: Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Ocupação da equipe')),
      body: body,
    );
  }
}

/// Desempenho da equipe (roadmap Fase 4): percentual de ocupacao da agenda
/// de cada profissional (semana corrente), numa barra por profissional,
/// ordenado do profissional que mais gerou receita no mes para o que menos
/// gerou — cada barra e relativa ao melhor profissional (100%), pra dar
/// visibilidade imediata de atendimentos/receita sem exigir nenhum cadastro
/// extra (diferente de ocupacao, que depende de horario de trabalho
/// configurado e pode ficar vazia mesmo com atendimentos reais).
class TeamPerformancePage extends StatefulWidget {
  const TeamPerformancePage({super.key, required this.dashboardRepository});

  final DashboardRepository dashboardRepository;

  @override
  State<TeamPerformancePage> createState() => _TeamPerformancePageState();
}

class _TeamPerformancePageState extends State<TeamPerformancePage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<TeamPerformanceEntryModel> _performance = [];

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
      final performance = await widget.dashboardRepository.teamPerformance();

      if (!mounted) return;
      setState(() {
        _performance = performance;
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
    Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else if (_performance.isEmpty) {
      body = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhum profissional ativo ainda.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      // Ja vem ordenado por receita gerada (decrescente) da API; o topo da
      // lista e o melhor profissional, usado como referencia de 100%.
      final topGrossCents = _performance.first.grossCents;

      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final entry in _performance)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.professionalName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final percentage = topGrossCents > 0
                          ? ((entry.grossCents / topGrossCents) * 100)
                                .round()
                                .clamp(0, 100)
                          : 0;

                      return Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                minHeight: 14,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                color: _percentageColor(context, percentage),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 44,
                            child: Text(
                              '$percentage%',
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.completedCount} atendimento${entry.completedCount == 1 ? '' : 's'} - '
                    '${formatCents(entry.grossCents)} - '
                    'a receber ${formatCents(entry.netCents)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Desempenho da equipe')),
      body: body,
    );
  }
}

/// Inteligencia de retorno (roadmap Fase 4): para cada cliente com pelo
/// menos 2 atendimentos concluidos, compara o tempo desde o ultimo
/// atendimento com a media historica do proprio cliente, sinalizando quando
/// vale a pena contatar. Probabilidade e uma heuristica, nao uma previsao de
/// IA de verdade.
class ReturnRiskPage extends StatefulWidget {
  const ReturnRiskPage({super.key, required this.dashboardRepository});

  final DashboardRepository dashboardRepository;

  @override
  State<ReturnRiskPage> createState() => _ReturnRiskPageState();
}

class _ReturnRiskPageState extends State<ReturnRiskPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ReturnRiskEntryModel> _entries = [];

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
      final entries = await widget.dashboardRepository.returnRisk();

      if (!mounted) return;
      setState(() {
        _entries = entries;
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

  (Color, Color) _probabilityColors(BuildContext context, String probability) {
    final colorScheme = Theme.of(context).colorScheme;

    return switch (probability) {
      'alta' => (Colors.green.shade100, Colors.green.shade900),
      'media' => (Colors.amber.shade100, Colors.amber.shade900),
      _ => (colorScheme.surfaceContainerHighest, colorScheme.onSurfaceVariant),
    };
  }

  String _probabilityLabel(String probability) => switch (probability) {
    'alta' => 'Alta',
    'media' => 'Média',
    _ => 'Baixa',
  };

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else if (_entries.isEmpty) {
      body = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhum cliente com histórico suficiente ainda. Clientes com '
            'pelo menos 2 atendimentos concluídos aparecem aqui.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final entry in _entries)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(entry.clientName),
                subtitle: Text(
                  'Último atendimento: ${entry.daysSinceLast} dias atrás\n'
                  'Média: ${entry.avgIntervalDays} dias',
                ),
                isThreeLine: true,
                trailing: Builder(
                  builder: (context) {
                    final (background, foreground) = _probabilityColors(
                      context,
                      entry.probability,
                    );

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _probabilityLabel(entry.probability),
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Clientes para reconquistar')),
      body: body,
    );
  }
}

/// Fila de espera vista pelo staff: lista quem esta `waiting` e permite
/// atribuir um horario, transformando a entrada em agendamento de verdade.
/// Tambem permite colocar um cliente na fila manualmente (ex: cliente ligou
/// avisando que esta a caminho, sem preferencia de profissional).
class ManageWaitlistPage extends StatefulWidget {
  const ManageWaitlistPage({
    super.key,
    required this.waitlistRepository,
    required this.professionalsRepository,
    required this.clientsRepository,
    required this.servicesRepository,
  });

  final WaitlistRepository waitlistRepository;
  final ProfessionalsRepository professionalsRepository;
  final ClientsRepository clientsRepository;
  final ServicesRepository servicesRepository;

  @override
  State<ManageWaitlistPage> createState() => _ManageWaitlistPageState();
}

class _ManageWaitlistPageState extends State<ManageWaitlistPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<WaitlistEntryModel> _entries = [];

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
      final entries = await widget.waitlistRepository.index(status: 'waiting');

      if (!mounted) return;
      setState(() {
        _entries = entries;
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

  Future<void> _openAssign(WaitlistEntryModel entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AssignWaitlistPage(
          waitlistRepository: widget.waitlistRepository,
          professionalsRepository: widget.professionalsRepository,
          entry: entry,
        ),
      ),
    );
    _load();
  }

  Future<void> _openAddToWaitlist() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddClientToWaitlistPage(
          waitlistRepository: widget.waitlistRepository,
          clientsRepository: widget.clientsRepository,
          servicesRepository: widget.servicesRepository,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else if (_entries.isEmpty) {
      body = const Center(child: Text('Nenhum cliente aguardando vaga.'));
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          for (final entry in _entries)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.groups),
                title: Text(entry.clientName ?? 'Cliente'),
                subtitle: Text(
                  '${entry.serviceName ?? 'Serviço'} - ${entry.professionalName ?? 'Qualquer profissional'}\n'
                  'Entrou na fila às ${formatTime(entry.createdAt)}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openAssign(entry),
              ),
            ),
        ],
      );
    }

    return Stack(
      children: [
        AppScaffold(
          appBar: AppBar(title: const Text('Fila de espera')),
          body: body,
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _openAddToWaitlist,
            tooltip: 'Colocar cliente na fila',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

/// Coloca um cliente na fila de espera em nome dele (ex: ligou avisando que
/// esta a caminho do salao). Mesma ideia da fila que o proprio cliente
/// preenche pelo app, so que com um passo a mais pra escolher quem e.
class AddClientToWaitlistPage extends StatefulWidget {
  const AddClientToWaitlistPage({
    super.key,
    required this.waitlistRepository,
    required this.clientsRepository,
    required this.servicesRepository,
  });

  final WaitlistRepository waitlistRepository;
  final ClientsRepository clientsRepository;
  final ServicesRepository servicesRepository;

  @override
  State<AddClientToWaitlistPage> createState() =>
      _AddClientToWaitlistPageState();
}

class _AddClientToWaitlistPageState extends State<AddClientToWaitlistPage> {
  bool _isLoadingOptions = true;
  String? _loadError;
  List<ClientModel> _clients = [];
  List<ServiceModel> _services = [];
  ClientModel? _selectedClient;
  ServiceModel? _selectedService;
  final _notesController = TextEditingController();

  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoadingOptions = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        widget.clientsRepository.index(),
        widget.servicesRepository.index(),
      ]);

      if (!mounted) return;
      setState(() {
        _clients = results[0] as List<ClientModel>;
        _services = results[1] as List<ServiceModel>;
        _selectedClient = _clients.isEmpty ? null : _clients.first;
        _selectedService = _services.isEmpty ? null : _services.first;
        _isLoadingOptions = false;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.userMessage;
        _isLoadingOptions = false;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedClient == null || _selectedService == null) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      await widget.waitlistRepository.create(
        clientId: _selectedClient!.id,
        serviceId: _selectedService!.id,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedClient!.name} entrou na fila de espera.'),
        ),
      );
      Navigator.of(context).pop();
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _saveError = error.userMessage;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;

    if (_isLoadingOptions) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_loadError != null) {
      body = AppLoadingError(message: _loadError!, onRetry: _loadOptions);
    } else if (_clients.isEmpty) {
      body = const Center(child: Text('Nenhum cliente cadastrado ainda.'));
    } else if (_services.isEmpty) {
      body = const Center(child: Text('Nenhum serviço cadastrado ainda.'));
    } else {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppSectionTitle('Cliente'),
          RadioGroup<ClientModel>(
            groupValue: _selectedClient,
            onChanged: (value) => setState(() => _selectedClient = value),
            child: Column(
              children: [
                for (final client in _clients)
                  RadioListTile<ClientModel>(
                    title: Text(client.name),
                    subtitle: Text(client.phone),
                    value: client,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AppSectionTitle('Serviço'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final service in _services)
                ChoiceChip(
                  label: Text(service.name),
                  selected: _selectedService?.id == service.id,
                  onSelected: (_) => setState(() => _selectedService = service),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Observações (opcional)',
            ),
            maxLines: 3,
          ),
          if (_saveError != null) ...[
            const SizedBox(height: 12),
            Text(
              _saveError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Colocar na fila'),
          ),
        ],
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Colocar cliente na fila')),
      body: body,
    );
  }
}

/// Atribui profissional (quando a entrada nao ja tem uma preferencia) e
/// horario a uma entrada da fila, chamando `POST /waitlist/{id}/assign`.
class AssignWaitlistPage extends StatefulWidget {
  const AssignWaitlistPage({
    super.key,
    required this.waitlistRepository,
    required this.professionalsRepository,
    required this.entry,
  });

  final WaitlistRepository waitlistRepository;
  final ProfessionalsRepository professionalsRepository;
  final WaitlistEntryModel entry;

  @override
  State<AssignWaitlistPage> createState() => _AssignWaitlistPageState();
}

class _AssignWaitlistPageState extends State<AssignWaitlistPage> {
  // Mesma simplificacao das outras telas de horario (nao ha endpoint real de
  // disponibilidade): a fila usa uma lista fixa de horarios, mas de hoje —
  // o cliente ja esta esperando ser atendido, entao faz mais sentido do que
  // "amanha" (unico caso usado no agendamento normal).
  static const _slots = ['09:00', '10:30', '13:00', '14:30', '16:00', '17:30'];
  String _selectedSlot = _slots.first;

  bool _isLoadingProfessionals = true;
  String? _loadError;
  List<ProfessionalModel> _professionals = [];
  ProfessionalModel? _selectedProfessional;

  bool _isSaving = false;
  String? _saveError;
  WaitlistEntryModel? _result;

  bool get _needsProfessionalPicker => widget.entry.professionalId == null;

  @override
  void initState() {
    super.initState();
    if (_needsProfessionalPicker) {
      _loadProfessionals();
    } else {
      _isLoadingProfessionals = false;
    }
  }

  Future<void> _loadProfessionals() async {
    setState(() {
      _isLoadingProfessionals = true;
      _loadError = null;
    });

    try {
      final professionals = await widget.professionalsRepository.index();

      if (!mounted) return;
      setState(() {
        _professionals = professionals;
        _selectedProfessional = professionals.isEmpty
            ? null
            : professionals.first;
        _isLoadingProfessionals = false;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.userMessage;
        _isLoadingProfessionals = false;
      });
    }
  }

  Future<void> _confirm() async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final parts = _selectedSlot.split(':');
    final now = DateTime.now();
    final startsAt = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    try {
      final result = await widget.waitlistRepository.assign(
        id: widget.entry.id,
        professionalId:
            widget.entry.professionalId ?? _selectedProfessional?.id,
        startsAt: startsAt,
      );

      if (!mounted) return;
      setState(() {
        _result = result;
        _isSaving = false;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _saveError = error.userMessage;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return AppScaffold(
        appBar: AppBar(title: const Text('Fila de espera')),
        body: AppMockSuccessPanel(
          title: 'Atendimento agendado',
          message:
              '${widget.entry.clientName ?? 'Cliente'} foi encaixado as $_selectedSlot.',
          buttonLabel: 'Concluir',
          onDone: () => Navigator.of(context).pop(),
        ),
      );
    }

    final Widget body;

    if (_needsProfessionalPicker && _isLoadingProfessionals) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_needsProfessionalPicker && _loadError != null) {
      body = AppLoadingError(message: _loadError!, onRetry: _loadProfessionals);
    } else {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Cliente'),
                  trailing: Text(widget.entry.clientName ?? '-'),
                ),
                ListTile(
                  title: const Text('Serviço'),
                  trailing: Text(widget.entry.serviceName ?? '-'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_needsProfessionalPicker) ...[
            const AppSectionTitle('Profissional'),
            Text(widget.entry.professionalName ?? '-'),
          ] else ...[
            const AppSectionTitle('Escolher profissional'),
            RadioGroup<ProfessionalModel>(
              groupValue: _selectedProfessional,
              onChanged: (value) =>
                  setState(() => _selectedProfessional = value),
              child: Column(
                children: [
                  for (final professional in _professionals)
                    RadioListTile<ProfessionalModel>(
                      title: Text(professional.name),
                      value: professional,
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const AppSectionTitle('Horário disponível (hoje)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final slot in _slots)
                ChoiceChip(
                  label: Text(slot),
                  selected: _selectedSlot == slot,
                  onSelected: (_) => setState(() => _selectedSlot = slot),
                ),
            ],
          ),
          if (_saveError != null) ...[
            const SizedBox(height: 16),
            Text(
              _saveError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSaving ? null : _confirm,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Atribuir horário'),
          ),
        ],
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Atribuir horário')),
      body: body,
    );
  }
}

/// Banner exibido no inicio do dono enquanto o trial esta rodando ou ja
/// venceu, sempre com um caminho direto pra tela de planos.
/// Selo exibido no inicio do dashboard do dono para saloes marcados como
/// fundadores pelo administrador da plataforma (roadmap Fase 5). Faz parte
/// do clube dos fundadores, entao o aviso de vencimento de trial nao faz
/// mais sentido pra ele e e suprimido em favor deste selo.
class _FounderBadge extends StatelessWidget {
  const _FounderBadge();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.workspace_premium,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Salão Fundador do Clube do Salão')),
          ],
        ),
      ),
    );
  }
}

class _SaasPlanBanner extends StatelessWidget {
  const _SaasPlanBanner({required this.subscription, required this.onTap});

  final SaasSubscriptionModel subscription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isExpired = subscription.isExpired;

    return Card(
      color: isExpired
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                isExpired ? Icons.error_outline : Icons.hourglass_top,
                color: isExpired
                    ? Theme.of(context).colorScheme.onErrorContainer
                    : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isExpired
                      ? 'Seu período de teste expirou. Escolha um plano para continuar.'
                      : 'Faltam ${subscription.trialDaysRemaining} dias do seu teste gratuito. Toque para ver os planos.',
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tela de planos SaaS do estabelecimento: mostra o tier atual (com limites
/// e uso) e permite trocar entre os 3 tiers pagos (spec, secao 3).
class SaasPlanPage extends StatefulWidget {
  const SaasPlanPage({
    super.key,
    required this.tenantRepository,
    required this.saasSubscriptionRepository,
  });

  final TenantRepository tenantRepository;
  final SaasSubscriptionRepository saasSubscriptionRepository;

  @override
  State<SaasPlanPage> createState() => _SaasPlanPageState();
}

class _SaasPlanPageState extends State<SaasPlanPage> {
  bool _isLoading = true;
  String? _errorMessage;
  SaasSubscriptionModel? _subscription;
  List<SaasPlanModel> _plans = [];
  String? _switchingPlanCode;

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
      final tenant = await widget.tenantRepository.show();
      final plans = await widget.saasSubscriptionRepository.plans();

      if (!mounted) return;
      setState(() {
        _subscription = tenant.saasSubscription;
        _plans = plans;
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

  Future<void> _switchPlan(SaasPlanModel plan) async {
    setState(() => _switchingPlanCode = plan.code);

    try {
      await widget.saasSubscriptionRepository.switchPlan(plan.code);

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AppScaffold(
            appBar: AppBar(title: const Text('Plano atualizado')),
            body: AppMockSuccessPanel(
              title: 'Plano ${plan.name} ativado',
              message: 'Seu estabelecimento já está no novo plano.',
              buttonLabel: 'Concluir',
              onDone: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      );

      if (!mounted) return;
      _load();
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.userMessage)));
    } finally {
      if (mounted) setState(() => _switchingPlanCode = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else {
      final subscription = _subscription!;
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SaasSubscriptionCard(subscription: subscription),
          const SizedBox(height: 20),
          const AppSectionTitle('Planos disponíveis'),
          for (final plan in _plans)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: subscription.plan?.code == plan.code
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: ListTile(
                leading: const Icon(Icons.workspace_premium),
                title: Text(plan.name),
                subtitle: Text(plan.limitsLabel),
                trailing: _switchingPlanCode == plan.code
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : subscription.plan?.code == plan.code
                    ? const Text('Plano atual')
                    : Text('${formatCents(plan.priceCents)}/mes'),
                onTap:
                    _switchingPlanCode != null ||
                        subscription.plan?.code == plan.code
                    ? null
                    : () => _switchPlan(plan),
              ),
            ),
        ],
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Meu plano')),
      body: body,
    );
  }
}

class _SaasSubscriptionCard extends StatelessWidget {
  const _SaasSubscriptionCard({required this.subscription});

  final SaasSubscriptionModel subscription;

  @override
  Widget build(BuildContext context) {
    final isExpired = subscription.isExpired;
    final isTrial = subscription.isTrial && !isExpired;

    return Card(
      color: isExpired
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isExpired ? 'Período de teste expirado' : subscription.planName,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              isExpired
                  ? 'Escolha um plano abaixo para continuar usando o Clube do Salao.'
                  : isTrial
                  ? 'Faltam ${subscription.trialDaysRemaining} dias do seu teste gratuito.'
                  : '${formatCents(subscription.priceCents)}/mes',
            ),
            const SizedBox(height: 12),
            Text(
              '${subscription.usage.professionals ?? 0} de ${subscription.limits.professionals?.toString() ?? "ilimitado"} profissionais',
            ),
            Text(
              '${subscription.usage.clientSubscriptions ?? 0} de ${subscription.limits.clientSubscriptions?.toString() ?? "ilimitado"} clientes assinantes',
            ),
            Text(
              '${subscription.usage.units ?? 1} de ${subscription.limits.units?.toString() ?? "ilimitado"} unidades',
            ),
          ],
        ),
      ),
    );
  }
}
