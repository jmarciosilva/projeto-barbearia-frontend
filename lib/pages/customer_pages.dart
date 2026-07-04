import 'package:clube_do_salao/core/app_exception.dart';
import 'package:clube_do_salao/core/formatting.dart';
import 'package:clube_do_salao/models/appointment_model.dart';
import 'package:clube_do_salao/models/client_model.dart';
import 'package:clube_do_salao/models/client_subscription_model.dart';
import 'package:clube_do_salao/models/professional_model.dart';
import 'package:clube_do_salao/models/service_model.dart';
import 'package:clube_do_salao/models/subscription_plan_model.dart';
import 'package:clube_do_salao/pages/professional_pages.dart' show AppointmentDetailPage;
import 'package:clube_do_salao/services/appointments_repository.dart';
import 'package:clube_do_salao/services/client_subscriptions_repository.dart';
import 'package:clube_do_salao/services/clients_repository.dart';
import 'package:clube_do_salao/services/professionals_repository.dart';
import 'package:clube_do_salao/services/services_repository.dart';
import 'package:clube_do_salao/services/subscription_plans_repository.dart';
import 'package:clube_do_salao/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';

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
              subtitle: service.discountPercentage != null &&
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
                    ? (plan == null ? 'Contrate um plano para comecar.' : 'Uso ilimitado neste mes.')
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
  const CustomerProfilePage({super.key, required this.clientsRepository});

  final ClientsRepository clientsRepository;

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
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

    final subscription = _client!.activeSubscription;

    return AppProfileSummary(
      title: 'Meu perfil',
      rows: [
        AppInfoRow('Plano', subscription?.plan?.name ?? 'Sem plano ativo'),
        AppInfoRow('Renovacao', subscription?.renewsOn ?? '-'),
        AppInfoRow(
          'Usos no mes',
          subscription?.plan?.usageLimit == null
              ? '-'
              : '${subscription!.usagesThisMonth()} de ${subscription.plan!.usageLimit}',
        ),
      ],
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
  });

  final ClientsRepository clientsRepository;
  final ServicesRepository servicesRepository;
  final ProfessionalsRepository professionalsRepository;
  final AppointmentsRepository appointmentsRepository;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppActionTile(
          icon: Icons.event_note,
          title: 'Meus agendamentos',
          subtitle: 'Veja, cancele ou remarque seus horarios.',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MyAppointmentsPage(
                appointmentsRepository: appointmentsRepository,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const AppSectionTitle('Novo agendamento'),
        const AppActionTile(
          icon: Icons.content_cut,
          title: 'Escolher servico',
          subtitle: 'Veja os servicos disponiveis no salao.',
        ),
        const AppActionTile(
          icon: Icons.badge,
          title: 'Escolher profissional',
          subtitle: 'Veja quem esta disponivel para atender.',
        ),
        const AppActionTile(
          icon: Icons.event,
          title: 'Confirmar horario',
          subtitle: 'Receba confirmacao na hora.',
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

class ChooseServicePage extends StatefulWidget {
  const ChooseServicePage({
    super.key,
    required this.clientsRepository,
    required this.servicesRepository,
    required this.professionalsRepository,
    required this.appointmentsRepository,
  });

  final ClientsRepository clientsRepository;
  final ServicesRepository servicesRepository;
  final ProfessionalsRepository professionalsRepository;
  final AppointmentsRepository appointmentsRepository;

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
      final results = await Future.wait([
        widget.servicesRepository.index(),
        widget.clientsRepository.me(),
      ]);

      if (!mounted) return;
      setState(() {
        _services = results[0] as List<ServiceModel>;
        _client = results[1] as ClientModel;
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
      body = const Center(child: Text('Nenhum servico disponivel.'));
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
                subtitle: Text(formatDuration(Duration(minutes: service.durationMinutes))),
                value: service,
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChooseProfessionalPage(
                    professionalsRepository: widget.professionalsRepository,
                    appointmentsRepository: widget.appointmentsRepository,
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
      appBar: AppBar(title: const Text('Escolher servico')),
      body: body,
    );
  }
}

class ChooseProfessionalPage extends StatefulWidget {
  const ChooseProfessionalPage({
    super.key,
    required this.professionalsRepository,
    required this.appointmentsRepository,
    required this.service,
    required this.client,
  });

  final ProfessionalsRepository professionalsRepository;
  final AppointmentsRepository appointmentsRepository;
  final ServiceModel service;
  final ClientModel client;

  @override
  State<ChooseProfessionalPage> createState() =>
      _ChooseProfessionalPageState();
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
      final professionals = await widget.professionalsRepository.index();

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
      body = const Center(child: Text('Nenhum profissional disponivel.'));
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
                subtitle: Text(professional.specialty ?? 'Disponivel'),
                value: professional,
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChooseTimePage(
                    appointmentsRepository: widget.appointmentsRepository,
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
    required this.service,
    required this.professional,
    required this.client,
  });

  final AppointmentsRepository appointmentsRepository;
  final ServiceModel service;
  final ProfessionalModel professional;
  final ClientModel client;

  @override
  State<ChooseTimePage> createState() => _ChooseTimePageState();
}

class _ChooseTimePageState extends State<ChooseTimePage> {
  // Nao existe endpoint de disponibilidade real ainda; a lista de horarios
  // continua fixa. A confirmacao abaixo, porem, e uma chamada real — se o
  // horario ja estiver ocupado ou violar alguma regra do plano, o erro
  // verdadeiro da API aparece aqui embaixo.
  static const _slots = ['09:00', '10:30', '13:00', '14:30', '16:00', '17:30'];
  String _selected = _slots.first;
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _confirm() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final parts = _selected.split(':');
    final now = DateTime.now();
    final startsAt = DateTime(
      now.year,
      now.month,
      now.day + 1,
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
      setState(() => _errorMessage = error.userMessage);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Confirmar horario')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionTitle('Horarios disponiveis (amanha)'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final slot in _slots)
                  ChoiceChip(
                    label: Text(slot),
                    selected: _selected == slot,
                    onSelected: (_) => setState(() => _selected = slot),
                  ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const Spacer(),
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
    return AppScaffold(
      appBar: AppBar(title: const Text('Agendamento confirmado')),
      body: AppMockSuccessPanel(
        title: 'Agendamento confirmado',
        message:
            '${appointment.serviceName ?? 'Atendimento'} com ${appointment.professionalName ?? 'profissional'} as ${formatTime(appointment.startsAt)}.',
        buttonLabel: 'Voltar ao inicio',
        onDone: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
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
  State<SubscriptionDetailPage> createState() =>
      _SubscriptionDetailPageState();
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
          'Tem certeza que deseja cancelar sua assinatura? Voce perde acesso '
          'aos beneficios do plano imediatamente.',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assinatura cancelada.')),
      );
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
        body = const Center(child: Text('Voce ainda nao tem um plano ativo.'));
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
            const AppSectionTitle('Historico de uso'),
            if (subscription.usages.isEmpty)
              const Card(
                child: ListTile(title: Text('Nenhum uso registrado ainda.')),
              )
            else
              for (final usage in subscription.usages)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(usage.serviceName ?? 'Servico'),
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
              subtitle: 'Veja outras opcoes disponiveis no salao.',
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
              message: 'Sua assinatura ja esta ativa.',
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
      body = const Center(child: Text('Nenhum plano disponivel no momento.'));
    } else {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppSectionTitle('Planos disponiveis'),
          for (final plan in _plans)
            Card(
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
      final appointments = await widget.appointmentsRepository.index();

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
          allowComplete: false,
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
    } else if (_appointments.isEmpty) {
      body = const Center(child: Text('Voce ainda nao tem agendamentos.'));
    } else {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final appointment in _appointments)
            Card(
              child: ListTile(
                leading: const Icon(Icons.event),
                title: Text(appointment.serviceName ?? 'Servico'),
                subtitle: Text(
                  '${appointment.professionalName ?? 'Profissional'} - ${formatTime(appointment.startsAt)}',
                ),
                trailing: Text(_statusLabel(appointment.status)),
                onTap: () => _openDetail(appointment),
              ),
            ),
        ],
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Meus agendamentos')),
      body: body,
    );
  }

  String _statusLabel(String status) => switch (status) {
    'completed' => 'Concluido',
    'canceled' => 'Cancelado',
    'no_show' => 'Faltou',
    _ => 'Agendado',
  };
}
