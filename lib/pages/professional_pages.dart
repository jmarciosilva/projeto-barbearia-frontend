import 'package:clube_do_salao/core/app_exception.dart';
import 'package:clube_do_salao/core/formatting.dart';
import 'package:clube_do_salao/models/appointment_model.dart';
import 'package:clube_do_salao/models/professional_finance_model.dart';
import 'package:clube_do_salao/models/professional_model.dart';
import 'package:clube_do_salao/services/appointments_repository.dart';
import 'package:clube_do_salao/services/professionals_repository.dart';
import 'package:clube_do_salao/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';

/// Atendimentos de hoje do profissional logado (o backend ja filtra pela
/// propria agenda, nunca mostra a de colegas).
class ProfessionalHomePage extends StatefulWidget {
  const ProfessionalHomePage({super.key, required this.appointmentsRepository});

  final AppointmentsRepository appointmentsRepository;

  @override
  State<ProfessionalHomePage> createState() => _ProfessionalHomePageState();
}

class _ProfessionalHomePageState extends State<ProfessionalHomePage> {
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
      return const Center(child: Text('Nenhum atendimento para hoje.'));
    }

    return AppScheduleList(
      title: 'Atendimentos de hoje',
      items: _items,
      onItemTap: _openDetail,
    );
  }
}

class ProfessionalProfilePage extends StatefulWidget {
  const ProfessionalProfilePage({
    super.key,
    required this.professionalsRepository,
    required this.appointmentsRepository,
  });

  final ProfessionalsRepository professionalsRepository;
  final AppointmentsRepository appointmentsRepository;

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
        AppInfoRow('Especialidade', professional.specialty ?? 'Nao informada'),
        AppInfoRow(
          'Comissao',
          professional.commissionPercentage == null
              ? 'Nao definida'
              : '${professional.commissionPercentage}%',
        ),
        AppInfoRow('Atendimentos no mes', '$_completedThisMonth'),
        AppInfoRow('Atendimentos na semana', '${weekFinance.completedCount}'),
        AppInfoRow(
          'Comissao do mes',
          formatCents(monthFinance.commissionCents),
        ),
        AppInfoRow('Adiantamentos', formatCents(monthFinance.advancesCents)),
        AppInfoRow('A receber', formatCents(monthFinance.netCents)),
        AppInfoRow('Dia de pagamento', 'Dia ${monthFinance.paymentDay}'),
      ],
      footer: [
        const SizedBox(height: 16),
        const AppSectionTitle('Extrato de adiantamentos'),
        if (monthFinance.advances.isEmpty)
          const Card(
            child: ListTile(title: Text('Nenhum adiantamento no mes.')),
          )
        else
          for (final advance in monthFinance.advances)
            Card(
              child: ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: Text(formatCents(advance.amountCents)),
                subtitle: Text(advance.notes ?? 'Adiantamento'),
              ),
            ),
        const SizedBox(height: 16),
        AppActionTile(
          icon: Icons.edit,
          title: 'Editar perfil',
          subtitle: 'Atualize especialidade e dados de contato.',
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
    this.allowComplete = true,
  });

  final AppointmentModel appointment;
  final AppointmentsRepository appointmentsRepository;
  final bool allowComplete;

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  String? _resultTitle;
  String? _resultMessage;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isScheduled => widget.appointment.status == 'scheduled';

  Future<void> _complete() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final appointment = widget.appointment;
      await widget.appointmentsRepository.complete(appointment.id);

      if (!mounted) return;
      setState(() {
        _resultTitle = 'Atendimento concluido';
        _resultMessage =
            '${appointment.serviceName ?? 'Atendimento'} de ${appointment.clientName ?? 'cliente'} foi marcado como concluido.';
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
        _resultMessage = 'O horario foi liberado na agenda.';
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
              child: AppSectionTitle('Novo horario (amanha)'),
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
        _resultMessage = 'Novo horario: $slot de amanha.';
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
    final appointment = widget.appointment;

    return AppScaffold(
      appBar: AppBar(title: const Text('Detalhe do atendimento')),
      body: _resultTitle != null
          ? AppMockSuccessPanel(
              title: _resultTitle!,
              message: _resultMessage!,
              buttonLabel: 'Voltar para a agenda',
              onDone: () => Navigator.of(context).pop(),
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
                        title: const Text('Servico'),
                        trailing: Text(appointment.serviceName ?? '-'),
                      ),
                      ListTile(
                        title: const Text('Horario'),
                        trailing: Text(formatTime(appointment.startsAt)),
                      ),
                      ListTile(
                        title: const Text('Duracao'),
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
                const AppSectionTitle('Observacoes'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      appointment.notes ?? 'Sem observacoes registradas.',
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
              controller: _specialtyController,
              decoration: const InputDecoration(labelText: 'Especialidade'),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Informe a especialidade'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Telefone'),
              keyboardType: TextInputType.phone,
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
