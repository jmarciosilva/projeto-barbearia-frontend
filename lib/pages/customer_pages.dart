import 'package:clube_do_salao/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';

class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SubscriptionCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SubscriptionDetailPage()),
          ),
        ),
        const SizedBox(height: 16),
        const AppSectionTitle('Beneficios'),
        const AppActionTile(
          icon: Icons.check_circle,
          title: 'Corte ilimitado',
          subtitle: 'Disponivel de segunda a sexta.',
        ),
        const AppActionTile(
          icon: Icons.percent,
          title: '20% em produtos',
          subtitle: 'Desconto aplicado no balcao.',
        ),
      ],
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
                'Plano Bronze',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text('2 de 4 usos neste mes'),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: 0.5,
                borderRadius: BorderRadius.circular(8),
              ),
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

class CustomerProfilePage extends StatelessWidget {
  const CustomerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppProfileSummary(
      title: 'Meu perfil',
      rows: [
        AppInfoRow('Plano', 'Bronze'),
        AppInfoRow('Renovacao', '15/07/2026'),
        AppInfoRow('Usos no mes', '2 de 4'),
      ],
    );
  }
}

class BookingPage extends StatelessWidget {
  const BookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const AppSectionTitle('Novo agendamento'),
        const AppActionTile(
          icon: Icons.content_cut,
          title: 'Escolher servico',
          subtitle: 'Corte masculino incluso no seu plano.',
        ),
        const AppActionTile(
          icon: Icons.badge,
          title: 'Escolher profissional',
          subtitle: 'Veja horarios livres por profissional.',
        ),
        const AppActionTile(
          icon: Icons.event,
          title: 'Confirmar horario',
          subtitle: 'Receba confirmacao e lembrete no app.',
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChooseServicePage()),
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
  const ChooseServicePage({super.key});

  @override
  State<ChooseServicePage> createState() => _ChooseServicePageState();
}

class _ChooseServicePageState extends State<ChooseServicePage> {
  static const _services = [
    'Corte masculino',
    'Barba completa',
    'Sobrancelha',
    'Coloracao',
  ];
  String _selected = _services.first;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Escolher servico')),
      body: RadioGroup<String>(
        groupValue: _selected,
        onChanged: (value) => setState(() => _selected = value!),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final service in _services)
              RadioListTile<String>(title: Text(service), value: service),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChooseProfessionalPage(service: _selected),
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChooseProfessionalPage extends StatefulWidget {
  const ChooseProfessionalPage({super.key, required this.service});

  final String service;

  @override
  State<ChooseProfessionalPage> createState() =>
      _ChooseProfessionalPageState();
}

class _ChooseProfessionalPageState extends State<ChooseProfessionalPage> {
  static const _professionals = ['Rafael Souza', 'Bianca Torres', 'Diego Santos'];
  String _selected = _professionals.first;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Escolher profissional')),
      body: RadioGroup<String>(
        groupValue: _selected,
        onChanged: (value) => setState(() => _selected = value!),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final professional in _professionals)
              RadioListTile<String>(
                secondary: const CircleAvatar(child: Icon(Icons.badge)),
                title: Text(professional),
                subtitle: const Text('Disponivel hoje'),
                value: professional,
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChooseTimePage(
                    service: widget.service,
                    professional: _selected,
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
      ),
    );
  }
}

class ChooseTimePage extends StatefulWidget {
  const ChooseTimePage({
    super.key,
    required this.service,
    required this.professional,
  });

  final String service;
  final String professional;

  @override
  State<ChooseTimePage> createState() => _ChooseTimePageState();
}

class _ChooseTimePageState extends State<ChooseTimePage> {
  static const _slots = ['09:00', '10:30', '13:00', '14:30', '16:00', '17:30'];
  String _selected = _slots.first;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Confirmar horario')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionTitle('Horarios disponiveis'),
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
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BookingConfirmationPage(
                    service: widget.service,
                    professional: widget.professional,
                    time: _selected,
                  ),
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text('Confirmar agendamento'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tela final do fluxo de agendamento mockado. "Voltar ao inicio" desfaz
/// toda a pilha de telas do fluxo e retorna ao shell de navegacao, que e
/// sempre a primeira rota (o app troca entre login e dashboard na raiz da
/// `MaterialApp`, nao empilhando uma sobre a outra).
class BookingConfirmationPage extends StatelessWidget {
  const BookingConfirmationPage({
    super.key,
    required this.service,
    required this.professional,
    required this.time,
  });

  final String service;
  final String professional;
  final String time;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Agendamento confirmado')),
      body: AppMockSuccessPanel(
        title: 'Agendamento confirmado',
        message: '$service com $professional as $time.',
        buttonLabel: 'Voltar ao inicio',
        onDone: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
      ),
    );
  }
}

class SubscriptionDetailPage extends StatelessWidget {
  const SubscriptionDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Minha assinatura')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Column(
              children: [
                ListTile(title: Text('Plano'), trailing: Text('Bronze')),
                ListTile(
                  title: Text('Renovacao'),
                  trailing: Text('15/07/2026'),
                ),
                ListTile(title: Text('Usos no mes'), trailing: Text('2 de 4')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AppSectionTitle('Historico de usos'),
          const Card(
            child: ListTile(
              leading: Icon(Icons.history),
              title: Text('Corte masculino - 20/06/2026'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.history),
              title: Text('Corte masculino - 06/06/2026'),
            ),
          ),
          const SizedBox(height: 16),
          AppActionTile(
            icon: Icons.swap_horiz,
            title: 'Trocar de plano',
            subtitle: 'Veja outras opcoes disponiveis no salao.',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fluxo de troca de plano em breve.')),
            ),
          ),
          AppActionTile(
            icon: Icons.cancel_outlined,
            title: 'Cancelar assinatura',
            subtitle: 'Encerrar o plano ao fim do ciclo atual.',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fluxo de cancelamento em breve.')),
            ),
          ),
        ],
      ),
    );
  }
}
