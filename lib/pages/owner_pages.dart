import 'package:clube_do_salao/core/app_exception.dart';
import 'package:clube_do_salao/core/formatting.dart';
import 'package:clube_do_salao/models/appointment_model.dart';
import 'package:clube_do_salao/models/client_model.dart';
import 'package:clube_do_salao/models/payment_model.dart';
import 'package:clube_do_salao/models/professional_model.dart';
import 'package:clube_do_salao/models/saas_plan_model.dart';
import 'package:clube_do_salao/models/saas_subscription_model.dart';
import 'package:clube_do_salao/models/service_model.dart';
import 'package:clube_do_salao/models/subscription_plan_model.dart';
import 'package:clube_do_salao/models/waitlist_entry_model.dart';
import 'package:clube_do_salao/pages/professional_pages.dart';
import 'package:clube_do_salao/services/appointments_repository.dart';
import 'package:clube_do_salao/services/clients_repository.dart';
import 'package:clube_do_salao/services/payments_repository.dart';
import 'package:clube_do_salao/services/professionals_repository.dart';
import 'package:clube_do_salao/services/saas_subscription_repository.dart';
import 'package:clube_do_salao/services/services_repository.dart';
import 'package:clube_do_salao/services/subscription_plans_repository.dart';
import 'package:clube_do_salao/services/tenant_repository.dart';
import 'package:clube_do_salao/services/waitlist_repository.dart';
import 'package:clube_do_salao/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';

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
  });

  final ClientsRepository clientsRepository;
  final AppointmentsRepository appointmentsRepository;
  final PaymentsRepository paymentsRepository;
  final SubscriptionPlansRepository plansRepository;
  final ServicesRepository servicesRepository;
  final ProfessionalsRepository professionalsRepository;
  final TenantRepository tenantRepository;
  final SaasSubscriptionRepository saasSubscriptionRepository;

  @override
  State<OwnerHomePage> createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends State<OwnerHomePage> {
  bool _isLoading = true;
  String? _errorMessage;
  int _activeSubscribers = 0;
  int _mrrCents = 0;
  int _todayAppointments = 0;
  int _pendingPayments = 0;
  SaasSubscriptionModel? _saasSubscription;

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

      final clients = await widget.clientsRepository.index();
      final appointments = await widget.appointmentsRepository.index(
        from: startOfDay,
        to: endOfDay,
      );
      final payments = await widget.paymentsRepository.index();
      final tenant = await widget.tenantRepository.show();

      final activeSubscriptions = clients
          .expand((client) => client.subscriptions)
          .where((subscription) => subscription.status == 'active');

      if (!mounted) return;
      setState(() {
        _activeSubscribers = activeSubscriptions.length;
        _mrrCents = activeSubscriptions.fold<int>(
          0,
          (sum, subscription) => sum + (subscription.plan?.priceCents ?? 0),
        );
        _todayAppointments = appointments.length;
        _pendingPayments = payments
            .where((payment) => payment.status == 'pending')
            .length;
        _saasSubscription = tenant.saasSubscription;
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (subscription.isExpired || subscription.isTrial)
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
        AppMetricGrid(
          metrics: [
            AppMetric('MRR previsto', formatCents(_mrrCents), Icons.payments),
            AppMetric(
              'Assinantes',
              '$_activeSubscribers',
              Icons.card_membership,
            ),
            AppMetric(
              'Agenda hoje',
              '$_todayAppointments',
              Icons.event_available,
            ),
            AppMetric('Pendentes', '$_pendingPayments', Icons.warning_amber),
          ],
        ),
        const SizedBox(height: 16),
        const AppSectionTitle('Proximas acoes'),
        AppActionTile(
          icon: Icons.workspace_premium,
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
          icon: Icons.person_add,
          title: 'Cadastrar cliente',
          subtitle: 'Inclua telefone, observacoes e historico inicial.',
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
          title: 'Criar plano de assinatura',
          subtitle: 'Defina servicos, limites, dias e horarios permitidos.',
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
          title: 'Confirmar pagamento manual',
          subtitle: 'PIX ou dinheiro validado pelo proprietario.',
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
      ],
    );
  }
}

/// Agenda do dia. O profissional ainda usa dados mockados nesta fase
/// ([appointmentsRepository] omitido); o proprietario ja recebe dados reais.
/// Agenda do dia. Proprietario ve o estabelecimento inteiro; profissional
/// ve so os proprios atendimentos (o backend ja aplica esse recorte).
class AgendaPage extends StatefulWidget {
  const AgendaPage({
    super.key,
    required this.appointmentsRepository,
    required this.waitlistRepository,
    required this.professionalsRepository,
  });

  final AppointmentsRepository appointmentsRepository;
  final WaitlistRepository waitlistRepository;
  final ProfessionalsRepository professionalsRepository;

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<AppointmentModel> _appointments = [];
  List<AppScheduleItem> _items = [];

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
        _items = appointments
            .map(
              (appointment) => AppScheduleItem(
                formatTime(appointment.startsAt),
                appointment.serviceName ?? 'Servico',
                appointment.clientName ?? 'Cliente',
                duration: formatDuration(
                  appointment.endsAt.difference(appointment.startsAt),
                ),
                notes: appointment.notes ?? 'Sem observacoes registradas.',
              ),
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

  Future<void> _openDetail(AppScheduleItem item) async {
    final appointment = _appointments[_items.indexOf(item)];

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppointmentDetailPage(
          appointment: appointment,
          appointmentsRepository: widget.appointmentsRepository,
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
    } else if (_items.isEmpty) {
      body = const Center(child: Text('Nenhum agendamento para hoje.'));
    } else {
      body = AppScheduleList(
        title: 'Agenda',
        items: _items,
        onItemTap: _openDetail,
      );
    }

    return Stack(
      children: [
        body,
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: _openWaitlist,
            icon: const Icon(Icons.groups),
            label: const Text('Fila de espera'),
          ),
        ),
      ],
    );
  }
}

class PlansPage extends StatefulWidget {
  const PlansPage({
    super.key,
    required this.plansRepository,
    required this.servicesRepository,
  });

  final SubscriptionPlansRepository plansRepository;
  final ServicesRepository servicesRepository;

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return AppLoadingError(message: _errorMessage!, onRetry: _load);
    }

    if (_plans.isEmpty) {
      return const Center(child: Text('Nenhum plano cadastrado ainda.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const AppSectionTitle('Planos ativos'),
        for (final plan in _plans)
          AppPlanTile(
            plan.name,
            '${formatCents(plan.priceCents)}/mes',
            plan.usageLimitLabel,
          ),
      ],
    );
  }
}

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key, required this.clientsRepository});

  final ClientsRepository clientsRepository;

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ClientModel> _clients = [];

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

    if (_clients.isEmpty) {
      return const Center(child: Text('Nenhum cliente cadastrado ainda.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const AppSectionTitle('Clientes'),
        for (final client in _clients)
          AppClientTile(
            client.name,
            client.activeSubscription == null
                ? 'Sem plano'
                : 'Plano ${client.activeSubscription!.plan?.name ?? '-'}',
            client.activeSubscription?.paymentStatusLabel ?? '-',
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ClientDetailPage(client: client),
                ),
              );
              _load();
            },
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
  final _notesController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cliente ${_nameController.text} cadastrado.'),
        ),
      );
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
              decoration: const InputDecoration(labelText: 'Telefone'),
              keyboardType: TextInputType.phone,
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Informe o telefone'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Observacoes'),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Plano ${_nameController.text} criado.')));
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
            const AppSectionTitle('Servicos inclusos'),
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
        _pending = payments
            .where((payment) => payment.status == 'pending')
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

/// Confirmacao de um pagamento manual (PIX ou dinheiro), chamando a API.
///
/// Retorna `true` via [Navigator.pop] quando o pagamento e confirmado, para
/// que a tela de origem possa atualizar sua lista.
class PaymentConfirmationPage extends StatefulWidget {
  const PaymentConfirmationPage({
    super.key,
    required this.paymentsRepository,
    required this.payment,
  });

  final PaymentsRepository paymentsRepository;
  final PaymentModel payment;

  @override
  State<PaymentConfirmationPage> createState() =>
      _PaymentConfirmationPageState();
}

class _PaymentConfirmationPageState extends State<PaymentConfirmationPage> {
  bool _confirmed = false;
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _confirm() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.paymentsRepository.markPaid(widget.payment.id);

      if (!mounted) return;
      setState(() {
        _confirmed = true;
        _isSaving = false;
      });
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
    final payment = widget.payment;

    return AppScaffold(
      appBar: AppBar(title: const Text('Confirmar pagamento')),
      body: _confirmed
          ? AppMockSuccessPanel(
              title: 'Pagamento confirmado',
              message:
                  '${formatCents(payment.amountCents)} de ${payment.clientName ?? 'cliente'} via ${payment.methodLabel}.',
              buttonLabel: 'Concluir',
              onDone: () => Navigator.of(context).pop(true),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Cliente'),
                        trailing: Text(payment.clientName ?? '-'),
                      ),
                      if (payment.serviceName != null)
                        ListTile(
                          title: const Text('Servico'),
                          trailing: Text(payment.serviceName!),
                        ),
                      ListTile(
                        title: const Text('Valor'),
                        trailing: Text(formatCents(payment.amountCents)),
                      ),
                      ListTile(
                        title: const Text('Forma de pagamento'),
                        trailing: Text(payment.methodLabel),
                      ),
                    ],
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _confirm,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Confirmar pagamento'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Detalhe de um cliente com os dados reais de plano e pagamento.
class ClientDetailPage extends StatelessWidget {
  const ClientDetailPage({super.key, required this.client});

  final ClientModel client;

  @override
  Widget build(BuildContext context) {
    final subscription = client.activeSubscription;

    return AppScaffold(
      appBar: AppBar(title: Text(client.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Telefone'),
                  trailing: Text(client.phone),
                ),
                if (client.email != null)
                  ListTile(
                    title: const Text('E-mail'),
                    trailing: Text(client.email!),
                  ),
                ListTile(
                  title: const Text('Plano'),
                  trailing: Text(subscription?.plan?.name ?? 'Sem plano ativo'),
                ),
                if (subscription != null)
                  ListTile(
                    title: const Text('Pagamento'),
                    trailing: Text(subscription.paymentStatusLabel),
                  ),
              ],
            ),
          ),
        ],
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
  });

  final ServicesRepository servicesRepository;
  final ProfessionalsRepository professionalsRepository;

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
          tabs: const [Tab(text: 'Servicos'), Tab(text: 'Profissionais')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ServicesPage(servicesRepository: widget.servicesRepository),
          ProfessionalsPage(
            professionalsRepository: widget.professionalsRepository,
            servicesRepository: widget.servicesRepository,
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

  @override
  Widget build(BuildContext context) {
    final Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else if (_services.isEmpty) {
      body = const Center(child: Text('Nenhum servico cadastrado ainda.'));
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          for (final service in _services)
            Card(
              child: ListTile(
                leading: const Icon(Icons.content_cut),
                title: Text(service.name),
                subtitle: Text(
                  formatDuration(Duration(minutes: service.durationMinutes)),
                ),
                trailing: Text(formatCents(service.priceCents)),
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
            tooltip: 'Cadastrar servico',
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
        SnackBar(content: Text('Servico ${_nameController.text} cadastrado.')),
      );
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
      appBar: AppBar(title: const Text('Cadastrar servico')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome do servico'),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duracao (minutos)',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Informe a duracao';
                return int.tryParse(value) == null
                    ? 'Informe um numero valido'
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

/// Lista de profissionais do estabelecimento, com atalho para cadastrar um
/// novo e para reabrir um existente e revisar servicos habilitados.
class ProfessionalsPage extends StatefulWidget {
  const ProfessionalsPage({
    super.key,
    required this.professionalsRepository,
    required this.servicesRepository,
  });

  final ProfessionalsRepository professionalsRepository;
  final ServicesRepository servicesRepository;

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
              child: ListTile(
                leading: const Icon(Icons.badge),
                title: Text(professional.name),
                subtitle: Text(professional.specialty ?? 'Sem especialidade'),
                trailing: professional.isActive
                    ? null
                    : const Text('Inativo'),
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
  });

  final ProfessionalsRepository professionalsRepository;
  final ServicesRepository servicesRepository;

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
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail (opcional)',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefone (opcional)',
              ),
              keyboardType: TextInputType.phone,
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
                labelText: 'Comissao % (opcional)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Senha de acesso ao app (opcional)',
                hintText: 'Deixe em branco para nao liberar login',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            const AppSectionTitle('Servicos habilitados'),
            Text(
              'Deixe sem selecionar para permitir qualquer servico cadastrado.',
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
  late final Set<int> _selectedServiceIds = {
    ...widget.professional.serviceIds,
  };
  late bool _isActive = widget.professional.isActive;

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
              decoration: const InputDecoration(labelText: 'Comissao %'),
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
            const AppSectionTitle('Servicos habilitados'),
            Text(
              'Deixe sem selecionar para permitir qualquer servico cadastrado.',
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

/// Fila de espera vista pelo staff: lista quem esta `waiting` e permite
/// atribuir um horario, transformando a entrada em agendamento de verdade.
class ManageWaitlistPage extends StatefulWidget {
  const ManageWaitlistPage({
    super.key,
    required this.waitlistRepository,
    required this.professionalsRepository,
  });

  final WaitlistRepository waitlistRepository;
  final ProfessionalsRepository professionalsRepository;

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
      final entries = await widget.waitlistRepository.index(
        status: 'waiting',
      );

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
        padding: const EdgeInsets.all(16),
        children: [
          for (final entry in _entries)
            Card(
              child: ListTile(
                leading: const Icon(Icons.groups),
                title: Text(entry.clientName ?? 'Cliente'),
                subtitle: Text(
                  '${entry.serviceName ?? 'Servico'} - ${entry.professionalName ?? 'Qualquer profissional'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openAssign(entry),
              ),
            ),
        ],
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Fila de espera')),
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
        professionalId: widget.entry.professionalId ?? _selectedProfessional?.id,
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
                  title: const Text('Servico'),
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
          const AppSectionTitle('Horario disponivel (hoje)'),
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
                : const Text('Atribuir horario'),
          ),
        ],
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Atribuir horario')),
      body: body,
    );
  }
}

/// Banner exibido no inicio do dono enquanto o trial esta rodando ou ja
/// venceu, sempre com um caminho direto pra tela de planos.
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
                      ? 'Seu periodo de teste expirou. Escolha um plano para continuar.'
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
              message: 'Seu estabelecimento ja esta no novo plano.',
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
          const AppSectionTitle('Planos disponiveis'),
          for (final plan in _plans)
            Card(
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

    return AppScaffold(appBar: AppBar(title: const Text('Meu plano')), body: body);
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
              isExpired ? 'Periodo de teste expirado' : subscription.planName,
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
