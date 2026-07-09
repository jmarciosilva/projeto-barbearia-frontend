import 'package:clube_do_salao/core/app_exception.dart';
import 'package:clube_do_salao/core/formatting.dart';
import 'package:clube_do_salao/models/appointment_model.dart';
import 'package:clube_do_salao/models/payment_model.dart';
import 'package:clube_do_salao/models/professional_finance_model.dart';
import 'package:clube_do_salao/models/professional_model.dart';
import 'package:clube_do_salao/models/professional_schedule_override_model.dart';
import 'package:clube_do_salao/pages/account_settings_page.dart';
import 'package:clube_do_salao/pages/payment_confirmation_page.dart';
import 'package:clube_do_salao/services/appointments_repository.dart';
import 'package:clube_do_salao/services/auth_session.dart';
import 'package:clube_do_salao/services/payments_repository.dart';
import 'package:clube_do_salao/services/professionals_repository.dart';
import 'package:clube_do_salao/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Painel do profissional (parecido com o do proprietario): resumo do mes
/// (atendimentos, avulso vs assinatura, receita gerada) seguido dos
/// atendimentos de hoje. O backend ja filtra pela propria agenda, nunca
/// mostra a de colegas.
class ProfessionalHomePage extends StatefulWidget {
  const ProfessionalHomePage({
    super.key,
    required this.appointmentsRepository,
    required this.professionalsRepository,
    required this.paymentsRepository,
  });

  final AppointmentsRepository appointmentsRepository;
  final ProfessionalsRepository professionalsRepository;
  final PaymentsRepository paymentsRepository;

  @override
  State<ProfessionalHomePage> createState() => _ProfessionalHomePageState();
}

class _ProfessionalHomePageState extends State<ProfessionalHomePage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<AppointmentModel> _appointments = [];
  ProfessionalFinanceModel? _monthFinance;

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
      final results = await Future.wait([
        widget.appointmentsRepository.index(from: startOfDay, to: endOfDay),
        widget.professionalsRepository.myFinance(),
      ]);
      final appointments = results[0] as List<AppointmentModel>;
      final monthFinance = results[1] as ProfessionalFinanceModel;

      if (!mounted) return;
      setState(() {
        _appointments = appointments;
        _monthFinance = monthFinance;
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return AppLoadingError(message: _errorMessage!, onRetry: _load);
    }

    final finance = _monthFinance!;
    final avulsoAppointments = finance.appointments
        .where((appointment) => !appointment.hasSubscription)
        .toList();
    final planoAppointments = finance.appointments
        .where((appointment) => appointment.hasSubscription)
        .toList();

    void openMonthDetail(
      String title,
      List<ProfessionalFinanceAppointmentModel> appointments, {
      int? commissionPercentage,
    }) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProfessionalMonthAppointmentsPage(
            title: title,
            appointments: appointments,
            commissionPercentage: commissionPercentage,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const AppSectionTitle('Este mês'),
        AppMetricGrid(
          metrics: [
            AppMetric(
              'Atendimentos',
              '${finance.completedCount}',
              Icons.event_available,
              onTap: () =>
                  openMonthDetail('Atendimentos do mês', finance.appointments),
            ),
            AppMetric(
              'Avulso',
              '${finance.avulsoCount}',
              Icons.content_cut,
              onTap: () => openMonthDetail(
                'Atendimentos avulsos do mês',
                avulsoAppointments,
              ),
            ),
            AppMetric(
              'Assinatura',
              '${finance.planoCount}',
              Icons.card_membership,
              onTap: () => openMonthDetail(
                'Atendimentos por assinatura do mês',
                planoAppointments,
              ),
            ),
            AppMetric(
              'Receita gerada',
              formatCents(finance.grossCents),
              Icons.payments,
              onTap: () =>
                  openMonthDetail('Receita gerada no mês', finance.appointments),
            ),
            AppMetric(
              'Comissão do Mês',
              formatCents(finance.commissionCents),
              Icons.percent,
              onTap: () => openMonthDetail(
                'Comissão do mês',
                finance.appointments,
                commissionPercentage: finance.commissionPercentage,
              ),
            ),
            AppMetric(
              'A receber',
              formatCents(finance.netCents),
              Icons.wallet,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ProfessionalAdvancesPage(advances: finance.advances),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const AppSectionTitle('Atendimentos de hoje'),
        AppDayTimeline(
          appointments: _appointments,
          onAppointmentTap: _openDetail,
          emptyMessage: 'Nenhum atendimento para hoje.',
        ),
      ],
    );
  }
}

/// Detalhe por tras dos cards "Atendimentos"/"Avulso"/"Assinatura"/"Receita
/// gerada"/"Comissão do Mês" do painel do profissional (mesmo padrao ja
/// usado no dashboard do dono para "Prevista hoje"/"Avulsa do mês"), pra o
/// profissional confiar no numero em vez de so ver um total sem explicacao.
/// Reaproveita a lista de atendimentos que ja vem em
/// `GET /me/professional/finance`, sem chamada nova a API. Cada card usa a
/// mesma sinalizacao visual de atendimento concluido (icone/cor verde) do
/// resto do app (`AppDayTimeline`) — todo item aqui e sempre concluido, por
/// isso nao varia por status.
class ProfessionalMonthAppointmentsPage extends StatelessWidget {
  const ProfessionalMonthAppointmentsPage({
    super.key,
    required this.title,
    required this.appointments,
    this.commissionPercentage,
  });

  final String title;
  final List<ProfessionalFinanceAppointmentModel> appointments;

  /// Quando informado, cada linha (e o total) mostram o valor de comissao
  /// (preco do servico x percentual) em vez do preco cheio — usado pelo
  /// card "Comissão do Mês".
  final int? commissionPercentage;

  int _valueCents(ProfessionalFinanceAppointmentModel appointment) {
    final price = appointment.servicePriceCents ?? 0;
    final percentage = commissionPercentage;

    return percentage == null ? price : (price * percentage / 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final totalCents = appointments.fold<int>(
      0,
      (sum, appointment) => sum + _valueCents(appointment),
    );
    // Decrescente: atendimento mais recente primeiro, mesmo padrao usado no
    // resto do app (AppDayTimeline).
    final sortedAppointments = appointments.toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      appBar: AppBar(title: Text(title)),
      body: appointments.isEmpty
          ? const Center(child: Text('Nenhum atendimento neste período.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(
                      '${appointments.length} atendimento${appointments.length == 1 ? '' : 's'}',
                    ),
                    trailing: Text(
                      formatCents(totalCents),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                for (final appointment in sortedAppointments)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: colorScheme.primaryContainer.withValues(
                      alpha: 0.45,
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.check_circle,
                        color: colorScheme.primary,
                      ),
                      title: Text(appointment.clientName ?? 'Cliente'),
                      subtitle: Text(
                        '${appointment.serviceName ?? 'Serviço'} - '
                        '${_formatDate(appointment.startsAt)} ${formatTime(appointment.startsAt)} - '
                        '${appointment.hasSubscription ? 'Assinatura' : 'Avulso'}',
                      ),
                      trailing: Text(formatCents(_valueCents(appointment))),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Lista de adiantamentos em ordem decrescente, reaproveitada entre o
/// "Extrato de adiantamentos" do proprio perfil (`ProfessionalProfilePage`)
/// e a tela "Adiantamentos" aberta pelo card "A receber" no painel "Hoje".
class ProfessionalAdvancesList extends StatelessWidget {
  const ProfessionalAdvancesList({super.key, required this.advances});

  final List<ProfessionalAdvanceModel> advances;

  @override
  Widget build(BuildContext context) {
    if (advances.isEmpty) {
      return const Card(
        child: ListTile(title: Text('Nenhum adiantamento no mês.')),
      );
    }

    // Decrescente: adiantamento mais recente primeiro, mesmo padrao usado
    // no resto do app (AppDayTimeline).
    final sorted = advances.toList()
      ..sort((a, b) => b.paidAt.compareTo(a.paidAt));

    return Column(
      children: [
        for (final advance in sorted)
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
}

/// Extrato de adiantamentos por tras do card "A receber" do painel "Hoje"
/// do profissional.
class ProfessionalAdvancesPage extends StatelessWidget {
  const ProfessionalAdvancesPage({super.key, required this.advances});

  final List<ProfessionalAdvanceModel> advances;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Adiantamentos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [ProfessionalAdvancesList(advances: advances)],
      ),
    );
  }
}

class ProfessionalProfilePage extends StatefulWidget {
  const ProfessionalProfilePage({
    super.key,
    required this.professionalsRepository,
    required this.appointmentsRepository,
    required this.authSession,
  });

  final ProfessionalsRepository professionalsRepository;
  final AppointmentsRepository appointmentsRepository;
  final AuthSession authSession;

  @override
  State<ProfessionalProfilePage> createState() =>
      _ProfessionalProfilePageState();
}

class _ProfessionalProfilePageState extends State<ProfessionalProfilePage> {
  bool _isLoading = true;
  String? _errorMessage;
  ProfessionalModel? _professional;
  ProfessionalFinanceModel? _monthFinance;
  ProfessionalFinanceModel? _weekFinance;
  int _completedThisMonth = 0;

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
      final startOfMonth = DateTime(now.year, now.month);
      final startOfNextMonth = DateTime(now.year, now.month + 1);

      final professional = await widget.professionalsRepository.me();
      final monthFinance = await widget.professionalsRepository.myFinance();
      final weekFinance = await widget.professionalsRepository.myFinance(
        period: 'week',
      );
      final appointments = await widget.appointmentsRepository.index(
        from: startOfMonth,
        to: startOfNextMonth,
      );

      if (!mounted) return;
      setState(() {
        _professional = professional;
        _monthFinance = monthFinance;
        _weekFinance = weekFinance;
        _completedThisMonth = appointments
            .where((appointment) => appointment.status == 'completed')
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

    final professional = _professional!;
    final monthFinance = _monthFinance!;
    final weekFinance = _weekFinance!;

    return AppProfileSummary(
      title: 'Perfil profissional',
      rows: [
        AppInfoRow('Especialidade', professional.specialty ?? 'Não informada'),
        AppInfoRow(
          'Comissão',
          professional.commissionPercentage == null
              ? 'Não definida'
              : '${professional.commissionPercentage}%',
        ),
        AppInfoRow('Atendimentos no mes', '$_completedThisMonth'),
        AppInfoRow('Atendimentos na semana', '${weekFinance.completedCount}'),
        AppInfoRow(
          'Comissão do mês',
          formatCents(monthFinance.commissionCents),
        ),
        AppInfoRow('Adiantamentos', formatCents(monthFinance.advancesCents)),
        AppInfoRow('A receber', formatCents(monthFinance.netCents)),
        AppInfoRow('Dia de pagamento', 'Dia ${monthFinance.paymentDay}'),
      ],
      footer: [
        const SizedBox(height: 16),
        const AppSectionTitle('Extrato de adiantamentos'),
        ProfessionalAdvancesList(advances: monthFinance.advances),
        const SizedBox(height: 16),
        AppActionTile(
          icon: Icons.edit,
          title: 'Editar perfil',
          subtitle: 'Atualize nome, especialidade e dados de contato.',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EditProfessionalProfilePage(
                  professionalsRepository: widget.professionalsRepository,
                  professional: professional,
                ),
              ),
            );
            _load();
          },
        ),
        AppActionTile(
          icon: Icons.schedule,
          title: 'Ajuste de horário',
          subtitle: 'Registre quando chegou/saiu diferente do horário normal.',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProfessionalScheduleOverridePage(
                  professionalsRepository: widget.professionalsRepository,
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

/// Horarios fixos usados para remarcar (amanha), mesma simplificacao ja
/// usada no fluxo de agendamento em `ChooseTimePage` — nao existe endpoint
/// real de disponibilidade nesta fase.
const _rescheduleSlots = ['09:00', '10:30', '13:00', '14:30', '16:00', '17:30'];

/// Detalhe de um atendimento da agenda, com acoes reais de concluir,
/// cancelar e remarcar. `allowComplete` fica desligado na visao do cliente,
/// que nunca pode se autoconcluir um atendimento (regra tambem aplicada no
/// backend, aqui e so para nao mostrar um botao que sempre falharia).
class AppointmentDetailPage extends StatefulWidget {
  const AppointmentDetailPage({
    super.key,
    required this.appointment,
    required this.appointmentsRepository,
    required this.paymentsRepository,
    this.allowComplete = true,
    this.canConfirmPayment = false,
  });

  final AppointmentModel appointment;
  final AppointmentsRepository appointmentsRepository;
  final PaymentsRepository paymentsRepository;
  final bool allowComplete;

  /// Libera o atalho "Confirmar pagamento" apos concluir um atendimento
  /// avulso. Dono e profissional podem confirmar (`POST /payments/{id}/mark-paid`
  /// e `role:owner,professional` no backend, que restringe o profissional ao
  /// proprio atendimento); cliente nunca recebe `true` aqui (o botao daria
  /// 403 se aparecesse pra ele).
  final bool canConfirmPayment;

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  String? _resultTitle;
  String? _resultMessage;
  bool _isSaving = false;
  String? _errorMessage;
  AppointmentModel? _completedAppointment;

  bool get _isScheduled => widget.appointment.status == 'scheduled';

  Future<void> _complete() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final appointment = widget.appointment;
      final completed = await widget.appointmentsRepository.complete(
        appointment.id,
      );

      if (!mounted) return;
      setState(() {
        _resultTitle = 'Atendimento concluído';
        _resultMessage =
            '${appointment.serviceName ?? 'Atendimento'} de ${appointment.clientName ?? 'cliente'} foi marcado como concluído.';
        _completedAppointment = completed;
        _isSaving = false;
      });
    } on QueuedForSyncException catch (queued) {
      // Sem conexao: ainda nao existe um atendimento/pagamento real do
      // servidor pra oferecer "Confirmar pagamento" em seguida — so volta
      // com a confirmacao neutra, o dono confirma o pagamento depois que
      // sincronizar.
      if (!mounted) return;
      setState(() => _isSaving = false);
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

  Future<void> _confirmPayment() async {
    final completed = _completedAppointment;
    if (completed?.paymentId == null) return;

    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentConfirmationPage(
          paymentsRepository: widget.paymentsRepository,
          payment: PaymentModel(
            id: completed!.paymentId!,
            amountCents: completed.paymentAmountCents ?? 0,
            method: completed.paymentMethod ?? 'pix',
            status: completed.paymentStatus ?? 'pending',
            appointmentId: completed.id,
            clientName: completed.clientName,
            serviceName: completed.serviceName,
          ),
        ),
      ),
    );

    // `true` (pago) e `false` (fiado) sao os dois desfechos do fluxo de
    // pagamento; so `null` (usuario voltou sem concluir) deve manter esta
    // tela aberta em vez de retornar direto pra agenda.
    if (!mounted || confirmed == null) return;
    Navigator.of(context).pop();
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar agendamento'),
        content: const Text(
          'Tem certeza que deseja cancelar este agendamento?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar agendamento'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.appointmentsRepository.cancel(widget.appointment.id);

      if (!mounted) return;
      setState(() {
        _resultTitle = 'Agendamento cancelado';
        _resultMessage = 'O horário foi liberado na agenda.';
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

  Future<void> _pickRescheduleSlot() async {
    final slot = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: AppSectionTitle('Novo horário (amanhã)'),
            ),
            for (final slot in _rescheduleSlots)
              ListTile(
                title: Text(slot),
                onTap: () => Navigator.of(context).pop(slot),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (slot == null || !mounted) return;

    final parts = slot.split(':');
    final now = DateTime.now();
    final startsAt = DateTime(
      now.year,
      now.month,
      now.day + 1,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.appointmentsRepository.reschedule(
        widget.appointment.id,
        startsAt,
      );

      if (!mounted) return;
      setState(() {
        _resultTitle = 'Agendamento remarcado';
        _resultMessage = 'Novo horário: $slot de amanhã.';
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

  bool get _canOfferPaymentConfirmation =>
      widget.canConfirmPayment &&
      _completedAppointment?.paymentId != null &&
      _completedAppointment?.paymentStatus == 'pending';

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;

    return AppScaffold(
      appBar: AppBar(title: const Text('Detalhe do atendimento')),
      body: _resultTitle != null
          ? AppMockSuccessPanel(
              title: _resultTitle!,
              message: _resultMessage!,
              buttonLabel: 'Voltar para a agenda',
              onDone: () => Navigator.of(context).pop(),
              secondaryButtonLabel: _canOfferPaymentConfirmation
                  ? 'Confirmar pagamento'
                  : null,
              onSecondary: _canOfferPaymentConfirmation
                  ? _confirmPayment
                  : null,
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Cliente'),
                        trailing: Text(appointment.clientName ?? '-'),
                      ),
                      ListTile(
                        title: const Text('Serviço'),
                        trailing: Text(appointment.serviceName ?? '-'),
                      ),
                      ListTile(
                        title: const Text('Horário'),
                        trailing: Text(formatTime(appointment.startsAt)),
                      ),
                      ListTile(
                        title: const Text('Duração'),
                        trailing: Text(
                          formatDuration(
                            appointment.endsAt.difference(appointment.startsAt),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const AppSectionTitle('Observações'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      appointment.notes ?? 'Sem observações registradas.',
                    ),
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
                if (_isScheduled) ...[
                  const SizedBox(height: 24),
                  if (widget.allowComplete) ...[
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _complete,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Concluir atendimento'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _pickRescheduleSlot,
                    icon: const Icon(Icons.event_repeat),
                    label: const Text('Remarcar'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _cancel,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancelar agendamento'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

/// Autoedicao do perfil profissional. Comissao nao entra aqui — continua
/// decisao exclusiva do proprietario.
class EditProfessionalProfilePage extends StatefulWidget {
  const EditProfessionalProfilePage({
    super.key,
    required this.professionalsRepository,
    required this.professional,
  });

  final ProfessionalsRepository professionalsRepository;
  final ProfessionalModel professional;

  @override
  State<EditProfessionalProfilePage> createState() =>
      _EditProfessionalProfilePageState();
}

class _EditProfessionalProfilePageState
    extends State<EditProfessionalProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.professional.name,
  );
  late final _emailController = TextEditingController(
    text: widget.professional.email ?? '',
  );
  late final _specialtyController = TextEditingController(
    text: widget.professional.specialty ?? '',
  );
  late final _phoneController = TextEditingController(
    text: widget.professional.phone ?? '',
  );

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _specialtyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.professionalsRepository.updateMe(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        specialty: _specialtyController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perfil atualizado.')));
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
      appBar: AppBar(title: const Text('Editar perfil')),
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
                labelText: 'E-mail de contato',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _specialtyController,
              decoration: const InputDecoration(labelText: 'Especialidade'),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Informe a especialidade'
                  : null,
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

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

/// Ajuste pontual do proprio horario de trabalho para uma data especifica
/// (ex: chegou mais tarde hoje), sem alterar o horario recorrente cadastrado
/// pelo dono (ver `WorkingHoursEditor`). Reaproveita a mesma ideia das
/// excecoes por data do horario do salao (`business_hours_page.dart`), so
/// que aqui e o proprio profissional quem registra, para o proprio horario.
class ProfessionalScheduleOverridePage extends StatefulWidget {
  const ProfessionalScheduleOverridePage({
    super.key,
    required this.professionalsRepository,
  });

  final ProfessionalsRepository professionalsRepository;

  @override
  State<ProfessionalScheduleOverridePage> createState() =>
      _ProfessionalScheduleOverridePageState();
}

class _ProfessionalScheduleOverridePageState
    extends State<ProfessionalScheduleOverridePage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ProfessionalScheduleOverrideModel> _overrides = [];

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
      final overrides = await widget.professionalsRepository
          .myScheduleOverrides();

      if (!mounted) return;
      setState(() {
        _overrides = overrides;
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

  Future<void> _openAdd() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddProfessionalScheduleOverridePage(
          professionalsRepository: widget.professionalsRepository,
        ),
      ),
    );
    _load();
  }

  Future<void> _delete(ProfessionalScheduleOverrideModel override) async {
    try {
      await widget.professionalsRepository.deleteMyScheduleOverride(
        override.id,
      );
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
    Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = AppLoadingError(message: _errorMessage!, onRetry: _load);
    } else {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Use quando seu horario num dia especifico for diferente do '
            'normal (ex: chegou mais tarde hoje), sem mudar seu horario '
            'fixo de todo dia.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (_overrides.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Nenhum ajuste registrado.'),
            )
          else
            for (final override in _overrides)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.edit_calendar),
                  title: Text(_formatDate(DateTime.parse(override.date))),
                  subtitle: Text(
                    override.isOff
                        ? 'Não vou trabalhar neste dia'
                        : 'Das ${override.startsAt} às ${override.endsAt}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remover ajuste',
                    onPressed: () => _delete(override),
                  ),
                ),
              ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _openAdd,
            icon: const Icon(Icons.add),
            label: const Text('Registrar ajuste de horário'),
          ),
        ],
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Ajuste de horário')),
      body: body,
    );
  }
}

/// Registra o ajuste pontual: uma data, um horario de inicio/fim (ou "nao
/// vou trabalhar"). Upsert por data no backend — registrar de novo a mesma
/// data substitui o ajuste anterior.
class AddProfessionalScheduleOverridePage extends StatefulWidget {
  const AddProfessionalScheduleOverridePage({
    super.key,
    required this.professionalsRepository,
  });

  final ProfessionalsRepository professionalsRepository;

  @override
  State<AddProfessionalScheduleOverridePage> createState() =>
      _AddProfessionalScheduleOverridePageState();
}

class _AddProfessionalScheduleOverridePageState
    extends State<AddProfessionalScheduleOverridePage> {
  DateTime _selectedDate = DateTime.now();
  bool _isOff = false;
  TimeOfDay? _startsAt = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay? _endsAt = const TimeOfDay(hour: 18, minute: 0);
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial =
        (isStart ? _startsAt : _endsAt) ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startsAt = picked;
      } else {
        _endsAt = picked;
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.professionalsRepository.createMyScheduleOverride(
        date: _selectedDate,
        isOff: _isOff,
        startsAt: _isOff || _startsAt == null
            ? null
            : formatTimeOfDay(_startsAt!),
        endsAt: _isOff || _endsAt == null ? null : formatTimeOfDay(_endsAt!),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } on AppException catch (error) {
      setState(() => _errorMessage = error.userMessage);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Ajuste de horário')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.edit_calendar),
                title: const Text('Data'),
                subtitle: Text(_formatDate(_selectedDate)),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Não vou trabalhar neste dia'),
                    value: _isOff,
                    onChanged: (value) => setState(() => _isOff = value),
                  ),
                  if (!_isOff) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Início'),
                      subtitle: Text(
                        _startsAt == null
                            ? 'Toque para definir'
                            : formatTimeOfDay(_startsAt!),
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: () => _pickTime(isStart: true),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Fim'),
                      subtitle: Text(
                        _endsAt == null
                            ? 'Toque para definir'
                            : formatTimeOfDay(_endsAt!),
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ],
                ],
              ),
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
                  : const Text('Salvar ajuste'),
            ),
          ],
        ),
      ),
    );
  }
}
