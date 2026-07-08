import 'package:clube_do_salao/core/formatting.dart';
import 'package:clube_do_salao/models/appointment_model.dart';
import 'package:clube_do_salao/models/professional_model.dart';
import 'package:clube_do_salao/models/waitlist_entry_model.dart';
import 'package:flutter/material.dart';

/// Scaffold padrao do app: aplica o mesmo degrade verde bem claro atras do
/// conteudo em todas as telas, mantendo a identidade visual consistente.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.45),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: body,
      ),
    );
  }
}

/// Estado de erro padrao para telas que buscam dados da API, com botao para
/// tentar novamente. Reaproveitado por todas as telas com chamada de rede.
class AppLoadingError extends StatelessWidget {
  const AppLoadingError({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Titulo de secao reutilizado nas listas de todas as telas do app.
class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// Card de acao com icone, titulo e subtitulo, usado nas telas iniciais.
///
/// Quando [onTap] e informado, a acao abre o fluxo mockado correspondente.
class AppActionTile extends StatelessWidget {
  const AppActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class AppMetric {
  const AppMetric(this.label, this.value, this.icon, {this.onTap});

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
}

class AppMetricGrid extends StatelessWidget {
  const AppMetricGrid({super.key, required this.metrics});

  final List<AppMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25,
      children: metrics.map((metric) => _MetricCard(metric)).toList(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.metric);

  final AppMetric metric;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: metric.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(metric.icon, color: Theme.of(context).colorScheme.primary),
                  if (metric.onTap != null)
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
              Text(
                metric.value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(metric.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item de agenda com dados mockados de um atendimento.
class AppScheduleItem {
  const AppScheduleItem(
    this.time,
    this.service,
    this.client, {
    this.duration = '40 min',
    this.notes = 'Sem observacoes registradas.',
  });

  final String time;
  final String service;
  final String client;
  final String duration;
  final String notes;
}

/// Lista de atendimentos do dia, usada na agenda de proprietario e profissional.
///
/// Quando [onItemTap] e informado, cada item abre o detalhe do atendimento.
class AppScheduleList extends StatelessWidget {
  const AppScheduleList({
    super.key,
    required this.title,
    required this.items,
    this.onItemTap,
  });

  final String title;
  final List<AppScheduleItem> items;
  final ValueChanged<AppScheduleItem>? onItemTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppSectionTitle(title),
        for (final item in items)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(child: Text(item.time.substring(0, 2))),
              title: Text(item.service),
              subtitle: Text(item.client),
              trailing: Text(item.time),
              onTap: onItemTap == null ? null : () => onItemTap!(item),
            ),
          ),
      ],
    );
  }
}

class AppPlanTile extends StatelessWidget {
  const AppPlanTile(this.name, this.price, this.limit, {super.key, this.onTap});

  final String name;
  final String price;
  final String limit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.workspace_premium),
        title: Text(name),
        subtitle: Text(limit),
        trailing: Text(price),
        onTap: onTap,
      ),
    );
  }
}

/// Tile de cliente na lista do proprietario.
///
/// Quando [onTap] e informado, abre o detalhe mockado do cliente.
class AppClientTile extends StatelessWidget {
  const AppClientTile(
    this.name,
    this.plan,
    this.payment, {
    super.key,
    this.onTap,
  });

  final String name;
  final String plan;
  final String payment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.person),
        title: Text(name),
        subtitle: Text(plan),
        trailing: Text(payment),
        onTap: onTap,
      ),
    );
  }
}

class AppInfoRow {
  const AppInfoRow(this.label, this.value);

  final String label;
  final String value;
}

/// Resumo de perfil em lista de linhas rotulo/valor, com rodape opcional
/// para acoes extras (ex: editar perfil).
class AppProfileSummary extends StatelessWidget {
  const AppProfileSummary({
    super.key,
    required this.title,
    required this.rows,
    this.footer = const [],
  });

  final String title;
  final List<AppInfoRow> rows;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppSectionTitle(title),
        Card(
          child: Column(
            children: [
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: Text(row.label)),
                      const SizedBox(width: 12),
                      // Valores longos (ex: e-mail) quebram linha em vez de
                      // estourar a largura do card — ListTile.trailing nao
                      // aceita widget flexivel, por isso a linha e montada
                      // na mao aqui.
                      Expanded(
                        flex: 3,
                        child: Text(row.value, textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        ...footer,
      ],
    );
  }
}

/// Painel de confirmacao exibido ao final dos fluxos mockados (cadastro,
/// pagamento, agendamento), simulando o retorno de sucesso da API.
class AppMockSuccessPanel extends StatelessWidget {
  const AppMockSuccessPanel({
    super.key,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onDone,
    this.secondaryButtonLabel,
    this.onSecondary,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onDone;

  /// Acao extra opcional (ex: "Confirmar pagamento" apos concluir um
  /// atendimento avulso), exibida abaixo do botao principal quando
  /// informada. Sem efeito nas demais telas que reaproveitam este painel.
  final String? secondaryButtonLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (secondaryButtonLabel != null && onSecondary != null) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSecondary,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                  ),
                  child: Text(secondaryButtonLabel!),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onDone,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                  ),
                  child: Text(buttonLabel),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDone,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                  ),
                  child: Text(buttonLabel),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Agenda de um dia especifico, agrupada por horario. Um mesmo horario pode
/// ter mais de um agendamento (profissionais diferentes atendendo ao mesmo
/// tempo) — cada um aparece como uma linha dentro do grupo daquele horario.
/// Entradas da fila de espera (sem horario marcado por definicao) entram no
/// grupo do horario em que o cliente entrou na fila, para dar visibilidade
/// de tudo que esta acontecendo no salao ao longo do dia num unico lugar.
///
/// Nao tem rolagem propria (nem `Scaffold`/padding fixo) de proposito: quem
/// usa decide se isso fica dentro de um `ListView`/`SingleChildScrollView`
/// junto com outra coisa (ex: o calendario do mes acima), evitando o
/// classico erro de `ListView` dentro de `ListView`.
class AppDayTimeline extends StatelessWidget {
  const AppDayTimeline({
    super.key,
    required this.appointments,
    this.waitlistEntries = const [],
    required this.onAppointmentTap,
    this.onWaitlistTap,
    this.emptyMessage = 'Nada agendado para este dia.',
    this.showClientNames = true,
  });

  final List<AppointmentModel> appointments;
  final List<WaitlistEntryModel> waitlistEntries;
  final ValueChanged<AppointmentModel> onAppointmentTap;
  final ValueChanged<WaitlistEntryModel>? onWaitlistTap;
  final String emptyMessage;

  /// Quando `false`, esconde o nome do cliente (e o toque/detalhe do card):
  /// usado na agenda do salao inteiro vista pelo cliente, que so pode ver
  /// quais horarios estao ocupados, nunca quem e o outro cliente.
  final bool showClientNames;

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty && waitlistEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(child: Text(emptyMessage)),
      );
    }

    final slots = <String, _DaySlot>{};

    for (final appointment in appointments) {
      final key = formatTime(appointment.startsAt);
      slots.putIfAbsent(key, () => _DaySlot(appointment.startsAt)).appointments.add(appointment);
    }
    for (final entry in waitlistEntries) {
      final key = formatTime(entry.createdAt);
      slots.putIfAbsent(key, () => _DaySlot(entry.createdAt)).waitlistEntries.add(entry);
    }

    final sortedKeys = slots.keys.toList()
      ..sort((a, b) => slots[a]!.time.compareTo(slots[b]!.time));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final key in sortedKeys) ...[
          AppSectionTitle(key),
          for (final appointment in slots[key]!.appointments)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.event),
                title: Text(appointment.serviceName ?? 'Serviço'),
                subtitle: Text(
                  showClientNames
                      ? '${appointment.clientName ?? 'Cliente'} - ${appointment.professionalName ?? 'Profissional'}'
                      : appointment.professionalName ?? 'Profissional',
                ),
                trailing: showClientNames
                    ? const Icon(Icons.chevron_right)
                    : null,
                onTap: showClientNames
                    ? () => onAppointmentTap(appointment)
                    : null,
              ),
            ),
          for (final entry in slots[key]!.waitlistEntries)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.groups),
                title: Text(entry.clientName ?? 'Cliente'),
                subtitle: Text(
                  'Entrou na fila de espera - ${entry.serviceName ?? 'Serviço'}',
                ),
                trailing: onWaitlistTap == null
                    ? null
                    : const Icon(Icons.chevron_right),
                onTap: onWaitlistTap == null
                    ? null
                    : () => onWaitlistTap!(entry),
              ),
            ),
        ],
      ],
    );
  }
}

const weekdayLabels = [
  'Domingo',
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
];

String formatTimeOfDay(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

TimeOfDay parseTimeOfDay(String raw) {
  final parts = raw.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

/// Editor do horario de trabalho do profissional por dia da semana (0 =
/// domingo), usado tanto no cadastro quanto na edicao. Reporta a lista
/// completa a cada alteracao via [onChanged]; dias desabilitados nao entram
/// na lista (profissional nao trabalha naquele dia).
class WorkingHoursEditor extends StatefulWidget {
  const WorkingHoursEditor({
    super.key,
    required this.initialWorkingHours,
    required this.onChanged,
  });

  final List<ProfessionalWorkingHourModel> initialWorkingHours;
  final ValueChanged<List<ProfessionalWorkingHourModel>> onChanged;

  @override
  State<WorkingHoursEditor> createState() => _WorkingHoursEditorState();
}

class _WorkingHoursEditorState extends State<WorkingHoursEditor> {
  late final List<bool> _enabled = List.generate(
    7,
    (weekday) => widget.initialWorkingHours.any((h) => h.weekday == weekday),
  );
  late final List<TimeOfDay> _starts = List.generate(7, (weekday) {
    final match = widget.initialWorkingHours
        .where((h) => h.weekday == weekday)
        .firstOrNull;
    return match == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : parseTimeOfDay(match.startsAt);
  });
  late final List<TimeOfDay> _ends = List.generate(7, (weekday) {
    final match = widget.initialWorkingHours
        .where((h) => h.weekday == weekday)
        .firstOrNull;
    return match == null
        ? const TimeOfDay(hour: 18, minute: 0)
        : parseTimeOfDay(match.endsAt);
  });

  void _notify() {
    widget.onChanged([
      for (var weekday = 0; weekday < 7; weekday++)
        if (_enabled[weekday])
          ProfessionalWorkingHourModel(
            weekday: weekday,
            startsAt: formatTimeOfDay(_starts[weekday]),
            endsAt: formatTimeOfDay(_ends[weekday]),
          ),
    ]);
  }

  Future<void> _pickTime(int weekday, {required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _starts[weekday] : _ends[weekday],
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _starts[weekday] = picked;
      } else {
        _ends[weekday] = picked;
      }
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var weekday = 0; weekday < 7; weekday++)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(weekdayLabels[weekday]),
                  value: _enabled[weekday],
                  onChanged: (value) {
                    setState(() => _enabled[weekday] = value);
                    _notify();
                  },
                ),
                if (_enabled[weekday]) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Início'),
                    subtitle: Text(formatTimeOfDay(_starts[weekday])),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _pickTime(weekday, isStart: true),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Fim'),
                    subtitle: Text(formatTimeOfDay(_ends[weekday])),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _pickTime(weekday, isStart: false),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _DaySlot {
  _DaySlot(this.time);

  final DateTime time;
  final List<AppointmentModel> appointments = [];
  final List<WaitlistEntryModel> waitlistEntries = [];
}
