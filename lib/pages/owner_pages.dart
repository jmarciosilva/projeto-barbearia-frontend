import 'package:clube_do_salao/core/app_exception.dart';
import 'package:clube_do_salao/core/formatting.dart';
import 'package:clube_do_salao/models/appointment_model.dart';
import 'package:clube_do_salao/models/client_model.dart';
import 'package:clube_do_salao/models/payment_model.dart';
import 'package:clube_do_salao/models/service_model.dart';
import 'package:clube_do_salao/models/subscription_plan_model.dart';
import 'package:clube_do_salao/pages/professional_pages.dart';
import 'package:clube_do_salao/services/appointments_repository.dart';
import 'package:clube_do_salao/services/clients_repository.dart';
import 'package:clube_do_salao/services/payments_repository.dart';
import 'package:clube_do_salao/services/services_repository.dart';
import 'package:clube_do_salao/services/subscription_plans_repository.dart';
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
  });

  final ClientsRepository clientsRepository;
  final AppointmentsRepository appointmentsRepository;
  final PaymentsRepository paymentsRepository;
  final SubscriptionPlansRepository plansRepository;
  final ServicesRepository servicesRepository;

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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
  const AgendaPage({super.key, required this.appointmentsRepository});

  final AppointmentsRepository appointmentsRepository;

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return AppLoadingError(message: _errorMessage!, onRetry: _load);
    }

    if (_items.isEmpty) {
      return const Center(child: Text('Nenhum agendamento para hoje.'));
    }

    return AppScheduleList(
      title: 'Agenda',
      items: _items,
      onItemTap: _openDetail,
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
  });

  final SubscriptionPlansRepository plansRepository;
  final ServicesRepository servicesRepository;

  @override
  State<NewPlanPage> createState() => _NewPlanPageState();
}

class _NewPlanPageState extends State<NewPlanPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _limitController = TextEditingController();
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
            if (_isLoadingServices)
              const Center(child: CircularProgressIndicator())
            else if (_servicesError != null)
              AppLoadingError(
                message: _servicesError!,
                onRetry: _loadServices,
              )
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
                leading: const Icon(Icons.price_check),
                title: Text(payment.clientName ?? 'Cliente'),
                subtitle: Text(payment.methodLabel),
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
