import 'package:clube_do_salao/core/app_exception.dart';
import 'package:clube_do_salao/core/formatting.dart';
import 'package:clube_do_salao/models/appointment_model.dart';
import 'package:clube_do_salao/models/client_model.dart';
import 'package:clube_do_salao/models/client_subscription_model.dart';
import 'package:clube_do_salao/models/payment_model.dart';
import 'package:clube_do_salao/models/professional_model.dart';
import 'package:clube_do_salao/models/service_model.dart';
import 'package:clube_do_salao/models/subscription_plan_model.dart';
import 'package:clube_do_salao/models/tenant_model.dart';
import 'package:clube_do_salao/models/tenant_schedule_override_model.dart';
import 'package:clube_do_salao/models/waitlist_entry_model.dart';
import 'package:clube_do_salao/pages/account_settings_page.dart';
import 'package:clube_do_salao/pages/professional_pages.dart'
    show AppointmentDetailPage;
import 'package:clube_do_salao/services/appointments_repository.dart';
import 'package:clube_do_salao/services/auth_session.dart';
import 'package:clube_do_salao/services/client_subscriptions_repository.dart';
import 'package:clube_do_salao/services/clients_repository.dart';
import 'package:clube_do_salao/services/professionals_repository.dart';
import 'package:clube_do_salao/services/payments_repository.dart';
import 'package:clube_do_salao/services/services_repository.dart';
import 'package:clube_do_salao/services/waitlist_repository.dart';
import 'package:clube_do_salao/services/subscription_plans_repository.dart';
import 'package:clube_do_salao/services/tenant_repository.dart';
import 'package:clube_do_salao/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({
    super.key,
    required this.clientsRepository,
    required this.plansRepository,
    required this.clientSubscriptionsRepository,
  });

  final ClientsRepository clientsRepository;
  final SubscriptionPlansRepository plansRepository;
  final ClientSubscriptionsRepository clientSubscriptionsRepository;

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  bool _isLoading = true;
  String? _errorMessage;
  ClientModel? _client;

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
      final client = await widget.clientsRepository.me();

      if (!mounted) return;
      setState(() {
        _client = client;
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

    final subscription = _client!.activeSubscription;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SubscriptionCard(
          subscription: subscription,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SubscriptionDetailPage(
                  clientsRepository: widget.clientsRepository,
                  plansRepository: widget.plansRepository,
                  clientSubscriptionsRepository:
                      widget.clientSubscriptionsRepository,
                ),
              ),
            );
            _load();
          },
        ),
        const SizedBox(height: 16),
        const AppSectionTitle('Beneficios'),
        if (subscription?.plan == null)
          AppActionTile(
            icon: Icons.info_outline,
            title: 'Nenhum plano ativo',
            subtitle: 'Toque para contratar uma assinatura.',
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChoosePlanPage(
                    plansRepository: widget.plansRepository,
                    clientSubscriptionsRepository:
                        widget.clientSubscriptionsRepository,
                  ),
                ),
              );
              _load();
            },
          )
        else
          for (final service in subscription!.plan!.services)
            AppActionTile(
              icon: Icons.check_circle,
              title: service.name,
              subtitle:
                  service.discountPercentage != null &&
                      service.discountPercentage! > 0
                  ? '${service.discountPercentage}% de desconto'
                  : 'Incluso no seu plano',
            ),
      ],
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.subscription, this.onTap});

  final ClientSubscriptionModel? subscription;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final plan = subscription?.plan;

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan == null ? 'Sem plano ativo' : 'Plano ${plan.name}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                plan == null || plan.usageLimit == null
                    ? (plan == null
                          ? 'Contrate um plano para comecar.'
                          : 'Uso ilimitado neste mes.')
                    : '${subscription!.usagesThisMonth()} de ${plan.usageLimit} usos neste mes',
              ),
              if (plan != null && plan.usageLimit != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (subscription!.usagesThisMonth() / plan.usageLimit!)
                      .clamp(0, 1)
                      .toDouble(),
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
              if (subscription != null &&
                  subscription!.paymentStatus != 'paid') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      subscription!.paymentStatus == 'overdue'
                          ? Icons.error_outline
                          : Icons.info_outline,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(subscription!.paymentStatusLabel)),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Ver detalhes',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({
    super.key,
    required this.clientsRepository,
    required this.authSession,
  });

  final ClientsRepository clientsRepository;
  final AuthSession authSession;

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class CustomerPaymentsPage extends StatefulWidget {
  const CustomerPaymentsPage({super.key, required this.paymentsRepository});

  final PaymentsRepository paymentsRepository;

  @override
  State<CustomerPaymentsPage> createState() => _CustomerPaymentsPageState();
}

class _CustomerPaymentsPageState extends State<CustomerPaymentsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<PaymentModel> _payments = [];

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
      final payments = await widget.paymentsRepository.mine();

      if (!mounted) return;
      setState(() {
        _payments = payments;
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

    final pending = _payments
        .where((payment) => payment.status == 'pending')
        .toList();
    final paid = _payments
        .where((payment) => payment.status == 'paid')
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const AppSectionTitle('Pagamentos pendentes'),
        if (pending.isEmpty)
          const Card(child: ListTile(title: Text('Nada pendente no salao.')))
        else
          for (final payment in pending) _CustomerPaymentTile(payment: payment),
        const SizedBox(height: 16),
        const AppSectionTitle('Pagamentos efetuados'),
        if (paid.isEmpty)
          const Card(child: ListTile(title: Text('Nenhum pagamento quitado.')))
        else
          for (final payment in paid) _CustomerPaymentTile(payment: payment),
      ],
    );
  }
}

class _CustomerPaymentTile extends StatelessWidget {
  const _CustomerPaymentTile({required this.payment});

  final PaymentModel payment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          payment.status == 'paid'
              ? Icons.check_circle_outline
              : Icons.schedule,
        ),
        title: Text(formatCents(payment.amountCents)),
        subtitle: Text(
          [
            payment.statusLabel,
            'pendente ${formatCents(payment.remainingCents)}',
            if (payment.serviceName != null) payment.serviceName!,
          ].join(' - '),
        ),
      ),
    );
  }
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  bool _isLoading = true;
  String? _errorMessage;
  ClientModel? _client;

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
      final client = await widget.clientsRepository.me();

      if (!mounted) return;
      setState(() {
        _client = client;
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

    final client = _client!;
    final subscription = client.activeSubscription;

    return AppProfileSummary(
      title: 'Meu perfil',
      rows: [
        AppInfoRow('Nome', client.name),
        AppInfoRow('Telefone', client.phone),
        AppInfoRow('E-mail', client.email ?? 'Não informado'),
        AppInfoRow('Plano', subscription?.plan?.name ?? 'Sem plano ativo'),
        AppInfoRow('Renovacao', subscription?.renewsOn ?? '-'),
        AppInfoRow(
          'Usos no mes',
          subscription?.plan?.usageLimit == null
              ? '-'
              : '${subscription!.usagesThisMonth()} de ${subscription.plan!.usageLimit}',
        ),
      ],
      footer: [
        const SizedBox(height: 16),
        AppActionTile(
          icon: Icons.edit,
          title: 'Editar dados pessoais',
          subtitle: 'Atualize nome, telefone e e-mail de contato.',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EditClientProfilePage(
                  clientsRepository: widget.clientsRepository,
                  client: client,
                ),
              ),
            );
            _load();
          },
        ),
        AppActionTile(
          icon: Icons.lock_outline,
          title: 'Meus dados de acesso',
          subtitle: 'Altere seu e-mail e/ou senha de login.',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AccountSettingsPage(authSession: widget.authSession),
            ),
          ),
        ),
      ],
    );
  }
}

/// Autoedicao dos dados de contato do proprio cliente (`PATCH /me/client`).
/// Nao mexe em e-mail/senha de login — isso fica em `AccountSettingsPage`,
/// mesmo padrao ja usado em `EditProfessionalProfilePage`.
class EditClientProfilePage extends StatefulWidget {
  const EditClientProfilePage({
    super.key,
    required this.clientsRepository,
    required this.client,
  });

  final ClientsRepository clientsRepository;
  final ClientModel client;

  @override
  State<EditClientProfilePage> createState() => _EditClientProfilePageState();
}

class _EditClientProfilePageState extends State<EditClientProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.client.name);
  late final _phoneController = TextEditingController(text: widget.client.phone);
  late final _emailController = TextEditingController(
    text: widget.client.email ?? '',
  );

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.clientsRepository.updateMe(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dados atualizados.')));
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
      appBar: AppBar(title: const Text('Editar dados pessoais')),
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
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Informe o telefone' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail de contato (opcional)',
              ),
              keyboardType: TextInputType.emailAddress,
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

class BookingPage extends StatelessWidget {
  const BookingPage({
    super.key,
    required this.clientsRepository,
    required this.servicesRepository,
    required this.professionalsRepository,
    required this.appointmentsRepository,
    required this.waitlistRepository,
    required this.tenantRepository,
  });

  final ClientsRepository clientsRepository;
  final ServicesRepository servicesRepository;
  final ProfessionalsRepository professionalsRepository;
  final AppointmentsRepository appointmentsRepository;
  final WaitlistRepository waitlistRepository;
  final TenantRepository tenantRepository;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppActionTile(
          icon: Icons.event_note,
          title: 'Meus agendamentos',
          subtitle: 'Veja, cancele ou remarque seus horários.',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MyAppointmentsPage(
                appointmentsRepository: appointmentsRepository,
              ),
            ),
          ),
        ),
        AppActionTile(
          icon: Icons.groups,
          title: 'Fila de espera',
          subtitle: 'Peça atendimento no estabelecimento sem escolher horário.',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MyWaitlistPage(
                waitlistRepository: waitlistRepository,
                servicesRepository: servicesRepository,
              ),
            ),
          ),
        ),
        AppActionTile(
          icon: Icons.calendar_month,
          title: 'Agenda do salão',
          subtitle: 'Veja os horários já ocupados para se programar.',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SalonSchedulePage(
                appointmentsRepository: appointmentsRepository,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const AppSectionTitle('Novo agendamento'),
        const AppActionTile(
          icon: Icons.content_cut,
          title: 'Escolher serviço',
          subtitle: 'Veja os serviços disponíveis no salão.',
        ),
        const AppActionTile(
          icon: Icons.badge,
          title: 'Escolher profissional',
          subtitle: 'Veja quem está disponível para atender.',
        ),
        const AppActionTile(
          icon: Icons.event,
          title: 'Confirmar horário',
          subtitle: 'Receba confirmação na hora.',
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChooseServicePage(
                clientsRepository: clientsRepository,
                servicesRepository: servicesRepository,
                professionalsRepository: professionalsRepository,
                appointmentsRepository: appointmentsRepository,
                tenantRepository: tenantRepository,
              ),
            ),
          ),
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Iniciar agendamento'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ],
    );
  }
}

/// Primeira tela do fluxo de agendamento. Uso duplo: cliente logado
/// agendando para si mesmo (sem [client] informado, resolve o proprio
/// cadastro via `clientsRepository.me()`) ou dono/profissional agendando
/// manualmente em nome de um cliente ja escolhido (passa [client] pronto,
/// pulando a chamada `.me()` que so funciona para o papel `customer`).
class ChooseServicePage extends StatefulWidget {
  const ChooseServicePage({
    super.key,
    required this.clientsRepository,
    required this.servicesRepository,
    required this.professionalsRepository,
    required this.appointmentsRepository,
    required this.tenantRepository,
    this.client,
  });

  final ClientsRepository clientsRepository;
  final ServicesRepository servicesRepository;
  final ProfessionalsRepository professionalsRepository;
  final AppointmentsRepository appointmentsRepository;
  final TenantRepository tenantRepository;
  final ClientModel? client;

  @override
  State<ChooseServicePage> createState() => _ChooseServicePageState();
}

class _ChooseServicePageState extends State<ChooseServicePage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ServiceModel> _services = [];
  ClientModel? _client;
  ServiceModel? _selected;

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
      final client = widget.client ?? await widget.clientsRepository.me();

      if (!mounted) return;
      setState(() {
        _services = services;
        _client = client;
        _selected = _services.isEmpty ? null : _services.first;
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
    final Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else if (_services.isEmpty) {
      body = const Center(child: Text('Nenhum serviço disponível.'));
    } else {
      body = RadioGroup<ServiceModel>(
        groupValue: _selected,
        onChanged: (value) => setState(() => _selected = value),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final service in _services)
              RadioListTile<ServiceModel>(
                title: Text(service.name),
                subtitle: Text(
                  formatDuration(Duration(minutes: service.durationMinutes)),
                ),
                value: service,
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChooseProfessionalPage(
                    professionalsRepository: widget.professionalsRepository,
                    appointmentsRepository: widget.appointmentsRepository,
                    tenantRepository: widget.tenantRepository,
                    service: _selected!,
                    client: _client!,
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
      appBar: AppBar(title: const Text('Escolher serviço')),
      body: body,
    );
  }
}

class ChooseProfessionalPage extends StatefulWidget {
  const ChooseProfessionalPage({
    super.key,
    required this.professionalsRepository,
    required this.appointmentsRepository,
    required this.tenantRepository,
    required this.service,
    required this.client,
  });

  final ProfessionalsRepository professionalsRepository;
  final AppointmentsRepository appointmentsRepository;
  final TenantRepository tenantRepository;
  final ServiceModel service;
  final ClientModel client;

  @override
  State<ChooseProfessionalPage> createState() => _ChooseProfessionalPageState();
}

class _ChooseProfessionalPageState extends State<ChooseProfessionalPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ProfessionalModel> _professionals = [];
  ProfessionalModel? _selected;

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
      final allProfessionals = await widget.professionalsRepository.index();
      // So lista quem de fato atende o servico escolhido — sem isso, a tela
      // deixava escolher qualquer profissional e o erro real ("Profissional
      // nao realiza este servico") so aparecia depois, na confirmacao.
      final professionals = allProfessionals
          .where((professional) => professional.serviceIds.contains(widget.service.id))
          .toList();

      if (!mounted) return;
      setState(() {
        _professionals = professionals;
        _selected = professionals.isEmpty ? null : professionals.first;
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
    final Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else if (_professionals.isEmpty) {
      body = const Center(
        child: Text('Nenhum profissional habilitado para este serviço.'),
      );
    } else {
      body = RadioGroup<ProfessionalModel>(
        groupValue: _selected,
        onChanged: (value) => setState(() => _selected = value),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final professional in _professionals)
              RadioListTile<ProfessionalModel>(
                secondary: const CircleAvatar(child: Icon(Icons.badge)),
                title: Text(professional.name),
                subtitle: Text(professional.specialty ?? 'Disponível'),
                value: professional,
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChooseTimePage(
                    appointmentsRepository: widget.appointmentsRepository,
                    tenantRepository: widget.tenantRepository,
                    service: widget.service,
                    professional: _selected!,
                    client: widget.client,
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
      appBar: AppBar(title: const Text('Escolher profissional')),
      body: body,
    );
  }
}

class ChooseTimePage extends StatefulWidget {
  const ChooseTimePage({
    super.key,
    required this.appointmentsRepository,
    required this.tenantRepository,
    required this.service,
    required this.professional,
    required this.client,
  });

  final AppointmentsRepository appointmentsRepository;
  final TenantRepository tenantRepository;
  final ServiceModel service;
  final ProfessionalModel professional;
  final ClientModel client;

  @override
  State<ChooseTimePage> createState() => _ChooseTimePageState();
}

class _ChooseTimePageState extends State<ChooseTimePage> {
  // Fallback usado so quando o dono nunca configurou horario de funcionamento
  // (ver `BusinessHoursPage`) — mantem o app utilizavel antes disso.
  static const _legacyFixedSlots = [
    '09:00',
    '10:30',
    '13:00',
    '14:30',
    '16:00',
    '17:30',
  ];
  static const _weekdayLabels = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
  static const _slotStepMinutes = 30;

  final List<DateTime> _days = List.generate(
    7,
    (i) => DateTime.now().add(Duration(days: i)),
  );

  bool _isLoading = true;
  String? _loadErrorMessage;
  TenantModel? _tenant;
  List<TenantScheduleOverrideModel> _overrides = [];

  late DateTime _selectedDay = _days.first;
  String? _selected;
  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadErrorMessage = null;
    });

    try {
      final results = await Future.wait([
        widget.tenantRepository.show(),
        widget.tenantRepository.listScheduleOverrides(),
      ]);

      if (!mounted) return;
      setState(() {
        _tenant = results[0] as TenantModel;
        _overrides = results[1] as List<TenantScheduleOverrideModel>;
        _selectedDay = _days.firstWhere(
          (day) => _availableSlots(day).isNotEmpty,
          orElse: () => _days.first,
        );
        final slots = _availableSlots(_selectedDay);
        _selected = slots.isEmpty ? null : slots.first;
        _isLoading = false;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadErrorMessage = error.userMessage;
        _isLoading = false;
      });
    }
  }

  TenantScheduleOverrideModel? _overrideFor(DateTime day) {
    for (final override in _overrides) {
      if (DateUtils.isSameDay(override.date, day)) return override;
    }
    return null;
  }

  /// Gera os horarios possiveis para [day] considerando abertura, fechamento
  /// e pausa do salao (com excecao pontual por data quando existir), e o
  /// tempo de duracao do servico escolhido. Sem nada configurado, cai na
  /// lista fixa antiga filtrando so os horarios ja passados hoje.
  List<String> _availableSlots(DateTime day) {
    final override = _overrideFor(day);
    if (override != null && override.isClosed) return [];

    final opensAtRaw = override?.opensAt ?? _tenant?.openingTime;
    final closesAtRaw = override?.closesAt ?? _tenant?.closingTime;

    if (opensAtRaw == null || closesAtRaw == null) {
      return _legacyFixedSlots.where((slot) => !_isPast(day, slot)).toList();
    }

    final opensMinutes = _minutesSinceMidnight(opensAtRaw);
    final closesMinutes = _minutesSinceMidnight(closesAtRaw);
    final breakStartMinutes = _tenant?.breakStartTime == null
        ? null
        : _minutesSinceMidnight(_tenant!.breakStartTime!);
    final breakEndMinutes = _tenant?.breakEndTime == null
        ? null
        : _minutesSinceMidnight(_tenant!.breakEndTime!);
    final serviceDuration = widget.service.durationMinutes;
    final isToday = DateUtils.isSameDay(day, DateTime.now());
    final nowMinutes = isToday
        ? DateTime.now().hour * 60 + DateTime.now().minute
        : null;

    final slots = <String>[];
    for (
      var cursor = opensMinutes;
      cursor + serviceDuration <= closesMinutes;
      cursor += _slotStepMinutes
    ) {
      final slotEnd = cursor + serviceDuration;
      final overlapsBreak = breakStartMinutes != null &&
          breakEndMinutes != null &&
          cursor < breakEndMinutes &&
          slotEnd > breakStartMinutes;
      final isPast = nowMinutes != null && cursor <= nowMinutes;

      if (!overlapsBreak && !isPast) {
        final hour = (cursor ~/ 60).toString().padLeft(2, '0');
        final minute = (cursor % 60).toString().padLeft(2, '0');
        slots.add('$hour:$minute');
      }
    }

    return slots;
  }

  bool _isPast(DateTime day, String slot) {
    if (!DateUtils.isSameDay(day, DateTime.now())) return false;

    final parts = slot.split(':');
    final slotTime = DateTime(
      day.year,
      day.month,
      day.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    return !slotTime.isAfter(DateTime.now());
  }

  int _minutesSinceMidnight(String raw) {
    final parts = raw.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _dayLabel(DateTime day) {
    if (DateUtils.isSameDay(day, DateTime.now())) return 'Hoje';
    if (DateUtils.isSameDay(day, DateTime.now().add(const Duration(days: 1)))) {
      return 'Amanhã';
    }
    return '${_weekdayLabels[day.weekday - 1]} ${day.day}';
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDay = day;
      final slots = _availableSlots(day);
      _selected = slots.isEmpty ? null : slots.first;
    });
  }

  Future<void> _confirm() async {
    if (_selected == null) return;

    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    final parts = _selected!.split(':');
    final startsAt = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    try {
      final appointment = await widget.appointmentsRepository.create(
        clientId: widget.client.id,
        professionalId: widget.professional.id,
        serviceId: widget.service.id,
        startsAt: startsAt,
        clientSubscriptionId: widget.client.activeSubscription?.id,
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingConfirmationPage(appointment: appointment),
        ),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _saveErrorMessage = error.userMessage);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppScaffold(
        appBar: AppBar(title: const Text('Confirmar horário')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadErrorMessage != null) {
      return AppScaffold(
        appBar: AppBar(title: const Text('Confirmar horário')),
        body: AppLoadingError(message: _loadErrorMessage!, onRetry: _load),
      );
    }

    final slots = _availableSlots(_selectedDay);

    return AppScaffold(
      appBar: AppBar(title: const Text('Confirmar horário')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionTitle('Escolha o dia'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final day in _days)
                          ChoiceChip(
                            label: Text(_dayLabel(day)),
                            selected: DateUtils.isSameDay(day, _selectedDay),
                            onSelected: (_) => _onDaySelected(day),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const AppSectionTitle('Horários disponíveis'),
                    if (slots.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Nenhum horário disponível para este dia.'),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final slot in slots)
                            ChoiceChip(
                              label: Text(slot),
                              selected: _selected == slot,
                              onSelected: (_) => setState(() => _selected = slot),
                            ),
                        ],
                      ),
                    if (_saveErrorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _saveErrorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSaving || _selected == null ? null : _confirm,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirmar agendamento'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tela final do fluxo de agendamento, alcancada so depois do `POST
/// /appointments` ter sucesso de verdade. "Voltar ao inicio" desfaz toda a
/// pilha de telas do fluxo e retorna ao shell de navegacao, que e sempre a
/// primeira rota (o app troca entre login e dashboard na raiz da
/// `MaterialApp`, nao empilhando uma sobre a outra).
class BookingConfirmationPage extends StatelessWidget {
  const BookingConfirmationPage({super.key, required this.appointment});

  final AppointmentModel appointment;

  @override
  Widget build(BuildContext context) {
    final paymentAmount = appointment.paymentAmountCents;

    return AppScaffold(
      appBar: AppBar(title: const Text('Agendamento confirmado')),
      body: AppMockSuccessPanel(
        title: 'Agendamento confirmado',
        message: paymentAmount == null
            ? '${appointment.serviceName ?? 'Atendimento'} com ${appointment.professionalName ?? 'profissional'} as ${formatTime(appointment.startsAt)}.'
            : '${appointment.serviceName ?? 'Atendimento'} com ${appointment.professionalName ?? 'profissional'} as ${formatTime(appointment.startsAt)}.\n\n'
                  'Agendamento avulso: ${formatCents(paymentAmount)} pendentes de pagamento no salao.',
        buttonLabel: 'Voltar ao inicio',
        onDone: () => Navigator.of(context).popUntil((route) => route.isFirst),
      ),
    );
  }
}

class SubscriptionDetailPage extends StatefulWidget {
  const SubscriptionDetailPage({
    super.key,
    required this.clientsRepository,
    required this.plansRepository,
    required this.clientSubscriptionsRepository,
  });

  final ClientsRepository clientsRepository;
  final SubscriptionPlansRepository plansRepository;
  final ClientSubscriptionsRepository clientSubscriptionsRepository;

  @override
  State<SubscriptionDetailPage> createState() => _SubscriptionDetailPageState();
}

class _SubscriptionDetailPageState extends State<SubscriptionDetailPage> {
  bool _isLoading = true;
  String? _errorMessage;
  bool _isCanceling = false;
  ClientModel? _client;

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
      final client = await widget.clientsRepository.me();

      if (!mounted) return;
      setState(() {
        _client = client;
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

  Future<void> _openChoosePlan() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChoosePlanPage(
          plansRepository: widget.plansRepository,
          clientSubscriptionsRepository: widget.clientSubscriptionsRepository,
        ),
      ),
    );
    _load();
  }

  Future<void> _cancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar assinatura'),
        content: const Text(
          'Tem certeza que deseja cancelar sua assinatura? Você perde acesso '
          'aos benefícios do plano imediatamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar assinatura'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCanceling = true);

    try {
      await widget.clientSubscriptionsRepository.cancelSelf();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Assinatura cancelada.')));
      await _load();
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.userMessage)));
    } finally {
      if (mounted) setState(() => _isCanceling = false);
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
      final subscription = _client!.activeSubscription;

      if (subscription == null) {
        body = const Center(child: Text('Você ainda não tem um plano ativo.'));
      } else {
        body = ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Plano'),
                    trailing: Text(subscription.plan?.name ?? '-'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.payments_outlined),
                    title: const Text('Pagamento'),
                    trailing: Text(subscription.paymentStatusLabel),
                  ),
                  ListTile(
                    leading: const Icon(Icons.autorenew),
                    title: const Text('Cobranca'),
                    trailing: const Text('Manual'),
                  ),
                  ListTile(
                    title: const Text('Renovacao'),
                    trailing: Text(subscription.renewsOn ?? '-'),
                  ),
                  ListTile(
                    title: const Text('Usos no mes'),
                    trailing: Text(
                      subscription.plan?.usageLimit == null
                          ? 'Ilimitado'
                          : '${subscription.usagesThisMonth()} de ${subscription.plan!.usageLimit}',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const AppSectionTitle('Financeiro'),
            if (subscription.paymentStatus == 'overdue')
              const Card(
                child: ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Assinatura bloqueada'),
                  subtitle: Text(
                    'Regularize o pagamento para voltar a agendar pelo plano.',
                  ),
                ),
              )
            else if (subscription.paymentStatus == 'pending')
              const Card(
                child: ListTile(
                  leading: Icon(Icons.schedule),
                  title: Text('Pagamento pendente'),
                  subtitle: Text(
                    'A confirmação aparece aqui assim que a cobrança for processada.',
                  ),
                ),
              )
            else
              const Card(
                child: ListTile(
                  leading: Icon(Icons.check_circle_outline),
                  title: Text('Pagamento em dia'),
                  subtitle: Text('Sua assinatura está liberada para uso.'),
                ),
              ),
            if (subscription.payments.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final payment in subscription.payments)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(
                      payment.status == 'paid'
                          ? Icons.check_circle_outline
                          : payment.status == 'overdue'
                          ? Icons.error_outline
                          : Icons.schedule,
                    ),
                    title: Text(formatCents(payment.amountCents)),
                    subtitle: Text(
                      [
                        payment.statusLabel,
                        payment.methodLabel,
                        if (payment.dueOn != null) 'vence ${payment.dueOn}',
                      ].join(' - '),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            const AppSectionTitle('Histórico de uso'),
            if (subscription.usages.isEmpty)
              const Card(
                child: ListTile(title: Text('Nenhum uso registrado ainda.')),
              )
            else
              for (final usage in subscription.usages)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(usage.serviceName ?? 'Serviço'),
                    subtitle: Text(
                      '${usage.usedAt.day.toString().padLeft(2, '0')}/'
                      '${usage.usedAt.month.toString().padLeft(2, '0')}/'
                      '${usage.usedAt.year}',
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            AppActionTile(
              icon: Icons.swap_horiz,
              title: 'Trocar de plano',
              subtitle: 'Veja outras opções disponíveis no salão.',
              onTap: _openChoosePlan,
            ),
            AppActionTile(
              icon: Icons.cancel_outlined,
              title: 'Cancelar assinatura',
              subtitle: _isCanceling
                  ? 'Cancelando...'
                  : 'Encerrar o plano ativo agora.',
              onTap: _isCanceling ? null : _cancelSubscription,
            ),
          ],
        );
      }
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Minha assinatura')),
      body: body,
    );
  }
}

/// Lista de planos ativos do estabelecimento para o cliente assinar ou
/// trocar. Se ja existir assinatura ativa, o backend a substitui pela nova.
class ChoosePlanPage extends StatefulWidget {
  const ChoosePlanPage({
    super.key,
    required this.plansRepository,
    required this.clientSubscriptionsRepository,
  });

  final SubscriptionPlansRepository plansRepository;
  final ClientSubscriptionsRepository clientSubscriptionsRepository;

  @override
  State<ChoosePlanPage> createState() => _ChoosePlanPageState();
}

class _ChoosePlanPageState extends State<ChoosePlanPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<SubscriptionPlanModel> _plans = [];
  int? _subscribingPlanId;

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

  Future<void> _subscribe(SubscriptionPlanModel plan) async {
    setState(() => _subscribingPlanId = plan.id);

    try {
      await widget.clientSubscriptionsRepository.subscribeSelf(plan.id);

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AppScaffold(
            appBar: AppBar(title: const Text('Assinatura confirmada')),
            body: AppMockSuccessPanel(
              title: 'Plano ${plan.name} ativado',
              message: 'Sua assinatura já está ativa.',
              buttonLabel: 'Concluir',
              onDone: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.userMessage)));
    } finally {
      if (mounted) setState(() => _subscribingPlanId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else if (_plans.isEmpty) {
      body = const Center(child: Text('Nenhum plano disponível no momento.'));
    } else {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppSectionTitle('Planos disponíveis'),
          for (final plan in _plans)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.workspace_premium),
                title: Text(plan.name),
                subtitle: Text(plan.usageLimitLabel),
                trailing: _subscribingPlanId == plan.id
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('${formatCents(plan.priceCents)}/mes'),
                onTap: _subscribingPlanId == null
                    ? () => _subscribe(plan)
                    : null,
              ),
            ),
        ],
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Escolher plano')),
      body: body,
    );
  }
}

/// Agendamentos do proprio cliente, com cancelar/remarcar (sem concluir —
/// isso continua exclusivo do dono/profissional). O backend ja escopa
/// `GET /appointments` ao cliente logado quando o papel e `customer`.
class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({super.key, required this.appointmentsRepository});

  final AppointmentsRepository appointmentsRepository;

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  DateTime _selectedDay = DateTime.now();
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
          allowComplete: false,
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
        onAppointmentTap: _openDetail,
        emptyMessage: 'Você não tem agendamentos neste dia.',
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Meus agendamentos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
    );
  }
}

/// Agenda do salao inteiro (todos os profissionais, todos os clientes),
/// somente leitura: mostra so o horario ocupado e o profissional, nunca o
/// nome de outro cliente (a API ja omite esse dado em `/appointments/salon`).
/// Ajuda o cliente a decidir entre agendar um horario livre ou entrar na
/// fila de espera.
class SalonSchedulePage extends StatefulWidget {
  const SalonSchedulePage({super.key, required this.appointmentsRepository});

  final AppointmentsRepository appointmentsRepository;

  @override
  State<SalonSchedulePage> createState() => _SalonSchedulePageState();
}

class _SalonSchedulePageState extends State<SalonSchedulePage> {
  DateTime _selectedDay = DateTime.now();
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
      final startOfDay = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final appointments = await widget.appointmentsRepository.salonSchedule(
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

  void _onDaySelected(DateTime day) {
    setState(() => _selectedDay = day);
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
        onAppointmentTap: (_) {},
        showClientNames: false,
        emptyMessage: 'Nenhum horário ocupado neste dia.',
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Agenda do salão')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Veja os horários já ocupados no salão para se programar antes '
            'de agendar ou entrar na fila de espera.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
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
    );
  }
}

/// Fila de espera do proprio cliente: lista as entradas ja pedidas e permite
/// entrar numa nova ou cancelar uma que ainda esta `waiting`.
class MyWaitlistPage extends StatefulWidget {
  const MyWaitlistPage({
    super.key,
    required this.waitlistRepository,
    required this.servicesRepository,
  });

  final WaitlistRepository waitlistRepository;
  final ServicesRepository servicesRepository;

  @override
  State<MyWaitlistPage> createState() => _MyWaitlistPageState();
}

class _MyWaitlistPageState extends State<MyWaitlistPage> {
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
      final entries = await widget.waitlistRepository.index();

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

  Future<void> _openJoin() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JoinWaitlistPage(
          waitlistRepository: widget.waitlistRepository,
          servicesRepository: widget.servicesRepository,
        ),
      ),
    );
    _load();
  }

  Future<void> _cancel(WaitlistEntryModel entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da fila'),
        content: const Text(
          'Tem certeza que deseja cancelar o pedido de atendimento?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair da fila'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.waitlistRepository.cancel(entry.id);

      if (!mounted) return;
      _load();
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
    } else if (_entries.isEmpty) {
      body = const Center(child: Text('Você não está na fila de espera.'));
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          for (final entry in _entries)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.groups),
                title: Text(entry.serviceName ?? 'Serviço'),
                subtitle: Text(
                  '${entry.professionalName ?? 'Qualquer profissional'}\n'
                  'Entrou na fila às ${formatTime(entry.createdAt)}',
                ),
                isThreeLine: true,
                trailing: entry.status == 'waiting'
                    ? IconButton(
                        tooltip: 'Sair da fila',
                        icon: const Icon(Icons.close),
                        onPressed: () => _cancel(entry),
                      )
                    : Text(entry.statusLabel),
              ),
            ),
        ],
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Fila de espera')),
      body: Stack(
        children: [
          body,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _openJoin,
              tooltip: 'Entrar na fila',
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pedido de entrada na fila: so pede o servico desejado e uma observacao
/// opcional — o produto define a fila como "qualquer profissional", entao
/// nao ha selecao de profissional nem de horario aqui.
class JoinWaitlistPage extends StatefulWidget {
  const JoinWaitlistPage({
    super.key,
    required this.waitlistRepository,
    required this.servicesRepository,
  });

  final WaitlistRepository waitlistRepository;
  final ServicesRepository servicesRepository;

  @override
  State<JoinWaitlistPage> createState() => _JoinWaitlistPageState();
}

class _JoinWaitlistPageState extends State<JoinWaitlistPage> {
  bool _isLoadingServices = true;
  String? _loadError;
  List<ServiceModel> _services = [];
  ServiceModel? _selectedService;
  final _notesController = TextEditingController();

  bool _isSaving = false;
  String? _saveError;
  WaitlistEntryModel? _result;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoadingServices = true;
      _loadError = null;
    });

    try {
      final services = await widget.servicesRepository.index();

      if (!mounted) return;
      setState(() {
        _services = services;
        _selectedService = services.isEmpty ? null : services.first;
        _isLoadingServices = false;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.userMessage;
        _isLoadingServices = false;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_selectedService == null) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final entry = await widget.waitlistRepository.create(
        serviceId: _selectedService!.id,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _result = entry;
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
          title: 'Você entrou na fila',
          message:
              'Assim que houver uma vaga, o salão confirma o horário do seu atendimento.',
          buttonLabel: 'Concluir',
          onDone: () => Navigator.of(context).pop(),
        ),
      );
    }

    final Widget body;

    if (_isLoadingServices) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_loadError != null) {
      body = AppLoadingError(message: _loadError!, onRetry: _loadServices);
    } else if (_services.isEmpty) {
      body = const Center(child: Text('Nenhum serviço disponível.'));
    } else {
      body = RadioGroup<ServiceModel>(
        groupValue: _selectedService,
        onChanged: (value) => setState(() => _selectedService = value),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const AppSectionTitle('Serviço desejado'),
            for (final service in _services)
              RadioListTile<ServiceModel>(
                title: Text(service.name),
                subtitle: Text(
                  formatDuration(Duration(minutes: service.durationMinutes)),
                ),
                value: service,
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                hintText: 'Ex: prefiro no período da tarde',
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
                  : const Text('Entrar na fila'),
            ),
          ],
        ),
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Fila de espera')),
      body: body,
    );
  }
}
