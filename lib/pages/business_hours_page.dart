import 'package:clube_do_salao/core/app_exception.dart';
import 'package:clube_do_salao/models/tenant_model.dart';
import 'package:clube_do_salao/models/tenant_schedule_override_model.dart';
import 'package:clube_do_salao/services/tenant_repository.dart';
import 'package:clube_do_salao/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';

String _formatTimeOfDay(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

TimeOfDay? _parseTimeOfDay(String? raw) {
  if (raw == null) return null;

  final parts = raw.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

/// Configuracao do horario de funcionamento padrao do salao (abertura,
/// fechamento e uma pausa opcional, ex: almoco) e das excecoes pontuais por
/// data (ex: fechar mais cedo num dia especifico, ou fechar o dia todo).
/// Exclusivo do dono. Ver `CreatesAppointments::assertWithinBusinessHours` no
/// backend para como isso e aplicado na hora de agendar.
class BusinessHoursPage extends StatefulWidget {
  const BusinessHoursPage({super.key, required this.tenantRepository});

  final TenantRepository tenantRepository;

  @override
  State<BusinessHoursPage> createState() => _BusinessHoursPageState();
}

class _BusinessHoursPageState extends State<BusinessHoursPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadErrorMessage;
  String? _saveErrorMessage;

  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;
  bool _hasBreak = false;
  TimeOfDay? _breakStart;
  TimeOfDay? _breakEnd;

  List<TenantScheduleOverrideModel> _overrides = [];

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
      final tenant = results[0] as TenantModel;
      final overrides = results[1] as List<TenantScheduleOverrideModel>;

      if (!mounted) return;
      setState(() {
        _openingTime = _parseTimeOfDay(tenant.openingTime);
        _closingTime = _parseTimeOfDay(tenant.closingTime);
        _breakStart = _parseTimeOfDay(tenant.breakStartTime);
        _breakEnd = _parseTimeOfDay(tenant.breakEndTime);
        _hasBreak = _breakStart != null && _breakEnd != null;
        _overrides = overrides;
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

  Future<void> _pickTime(TimeOfDay? initial, ValueChanged<TimeOfDay> onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null) onPicked(picked);
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    try {
      await widget.tenantRepository.updateBusinessHours(
        openingTime: _openingTime == null ? null : _formatTimeOfDay(_openingTime!),
        closingTime: _closingTime == null ? null : _formatTimeOfDay(_closingTime!),
        breakStartTime: _hasBreak && _breakStart != null
            ? _formatTimeOfDay(_breakStart!)
            : null,
        breakEndTime: _hasBreak && _breakEnd != null
            ? _formatTimeOfDay(_breakEnd!)
            : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horário de funcionamento atualizado.')),
      );
      Navigator.of(context).pop();
    } on AppException catch (error) {
      setState(() => _saveErrorMessage = error.userMessage);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openAddOverride() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AddScheduleOverridePage(tenantRepository: widget.tenantRepository),
      ),
    );
    _load();
  }

  Future<void> _deleteOverride(TenantScheduleOverrideModel override) async {
    try {
      await widget.tenantRepository.deleteScheduleOverride(override.id);
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
    } else if (_loadErrorMessage != null) {
      body = AppLoadingError(message: _loadErrorMessage!, onRetry: _load);
    } else {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppSectionTitle('Horário padrão'),
          Text(
            'Deixe em branco para não restringir agendamentos por horário.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.wb_sunny_outlined),
                  title: const Text('Abertura'),
                  subtitle: Text(
                    _openingTime == null
                        ? 'Não configurado'
                        : _formatTimeOfDay(_openingTime!),
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _pickTime(
                    _openingTime,
                    (time) => setState(() => _openingTime = time),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.nights_stay_outlined),
                  title: const Text('Fechamento'),
                  subtitle: Text(
                    _closingTime == null
                        ? 'Não configurado'
                        : _formatTimeOfDay(_closingTime!),
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _pickTime(
                    _closingTime,
                    (time) => setState(() => _closingTime = time),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.free_breakfast_outlined),
                  title: const Text('Fechado para pausa (ex: almoço)'),
                  value: _hasBreak,
                  onChanged: (value) => setState(() => _hasBreak = value),
                ),
                if (_hasBreak) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Início da pausa'),
                    subtitle: Text(
                      _breakStart == null
                          ? 'Toque para definir'
                          : _formatTimeOfDay(_breakStart!),
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _pickTime(
                      _breakStart,
                      (time) => setState(() => _breakStart = time),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Fim da pausa'),
                    subtitle: Text(
                      _breakEnd == null
                          ? 'Toque para definir'
                          : _formatTimeOfDay(_breakEnd!),
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _pickTime(
                      _breakEnd,
                      (time) => setState(() => _breakEnd = time),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_saveErrorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _saveErrorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar horário padrão'),
          ),
          const SizedBox(height: 24),
          const AppSectionTitle('Exceções por data'),
          Text(
            'Para fechar mais cedo ou o dia todo numa data especifica, sem mudar o horário padrão.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (_overrides.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Nenhuma exceção cadastrada.'),
            )
          else
            for (final override in _overrides)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.event_busy),
                  title: Text(_formatDate(override.date)),
                  subtitle: Text(
                    override.isClosed
                        ? 'Fechado o dia todo'
                        : 'Abre às ${override.opensAt?.substring(0, 5) ?? '--'} '
                              'e fecha às ${override.closesAt?.substring(0, 5) ?? '--'}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remover exceção',
                    onPressed: () => _deleteOverride(override),
                  ),
                ),
              ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _openAddOverride,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar exceção'),
          ),
        ],
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Horário de funcionamento')),
      body: body,
    );
  }
}

/// Cria uma excecao pontual (fechar mais cedo/mais tarde, ou fechar o dia
/// todo) para uma data especifica.
class AddScheduleOverridePage extends StatefulWidget {
  const AddScheduleOverridePage({super.key, required this.tenantRepository});

  final TenantRepository tenantRepository;

  @override
  State<AddScheduleOverridePage> createState() =>
      _AddScheduleOverridePageState();
}

class _AddScheduleOverridePageState extends State<AddScheduleOverridePage> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  bool _isClosed = true;
  TimeOfDay? _opensAt;
  TimeOfDay? _closesAt;
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime({required bool isOpening}) async {
    final initial = (isOpening ? _opensAt : _closesAt) ??
        const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);

    if (picked == null) return;

    setState(() {
      if (isOpening) {
        _opensAt = picked;
      } else {
        _closesAt = picked;
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.tenantRepository.createScheduleOverride(
        date: _selectedDate,
        isClosed: _isClosed,
        opensAt: !_isClosed && _opensAt != null ? _formatTimeOfDay(_opensAt!) : null,
        closesAt: !_isClosed && _closesAt != null
            ? _formatTimeOfDay(_closesAt!)
            : null,
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
      appBar: AppBar(title: const Text('Adicionar exceção')),
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
                    title: const Text('Fechado o dia todo'),
                    value: _isClosed,
                    onChanged: (value) => setState(() => _isClosed = value),
                  ),
                  if (!_isClosed) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Abre às'),
                      subtitle: Text(
                        _opensAt == null
                            ? 'Toque para definir'
                            : _formatTimeOfDay(_opensAt!),
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: () => _pickTime(isOpening: true),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Fecha às'),
                      subtitle: Text(
                        _closesAt == null
                            ? 'Toque para definir'
                            : _formatTimeOfDay(_closesAt!),
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: () => _pickTime(isOpening: false),
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
                  : const Text('Salvar exceção'),
            ),
          ],
        ),
      ),
    );
  }
}
