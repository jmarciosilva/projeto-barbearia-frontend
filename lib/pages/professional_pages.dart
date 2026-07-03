import 'package:clube_do_salao/core/app_exception.dart';
import 'package:clube_do_salao/core/formatting.dart';
import 'package:clube_do_salao/models/appointment_model.dart';
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
      final appointments = await widget.appointmentsRepository.index(
        from: startOfMonth,
        to: startOfNextMonth,
      );

      if (!mounted) return;
      setState(() {
        _professional = professional;
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
      ],
      footer: [
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

/// Detalhe de um atendimento da agenda, com acao real de concluir.
class AppointmentDetailPage extends StatefulWidget {
  const AppointmentDetailPage({
    super.key,
    required this.appointment,
    required this.appointmentsRepository,
  });

  final AppointmentModel appointment;
  final AppointmentsRepository appointmentsRepository;

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  bool _completed = false;
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _complete() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.appointmentsRepository.complete(widget.appointment.id);

      if (!mounted) return;
      setState(() {
        _completed = true;
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
      body: _completed
          ? AppMockSuccessPanel(
              title: 'Atendimento concluido',
              message:
                  '${appointment.serviceName ?? 'Atendimento'} de ${appointment.clientName ?? 'cliente'} foi marcado como concluido.',
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
                            appointment.endsAt.difference(
                              appointment.startsAt,
                            ),
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
                const SizedBox(height: 24),
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
