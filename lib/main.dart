import 'dart:async';

import 'package:clube_do_salao/core/app_transaction.dart';
import 'package:clube_do_salao/core/error_reporter.dart';
import 'package:flutter/material.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    AppErrorReporter.configure();

    runApp(const ClubeDoSalaoApp());
  }, AppErrorReporter.reportZoneError);
}

enum UserRole {
  owner('Proprietario', Icons.storefront),
  professional('Profissional', Icons.content_cut),
  customer('Cliente', Icons.person);

  const UserRole(this.label, this.icon);

  final String label;
  final IconData icon;
}

class ClubeDoSalaoApp extends StatelessWidget {
  const ClubeDoSalaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF176B5B),
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clube do Salao',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF7F5F0),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      home: const RoleGatePage(),
    );
  }
}

class RoleGatePage extends StatefulWidget {
  const RoleGatePage({super.key});

  @override
  State<RoleGatePage> createState() => _RoleGatePageState();
}

class _RoleGatePageState extends State<RoleGatePage> {
  UserRole selectedRole = UserRole.owner;

  /// Altera o perfil usando commit/rollback de estado local.
  ///
  /// Quando a API entrar no fluxo, este mesmo padrao permite desfazer selecoes
  /// otimistas caso uma validacao remota falhe.
  void _selectRole(UserRole role) {
    final transaction = AppStateTransaction<UserRole>(selectedRole)
      ..stage(role);

    try {
      setState(() => selectedRole = transaction.commit());
    } catch (error, stackTrace) {
      setState(() => selectedRole = transaction.rollback());
      AppErrorReporter.report(error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              Icon(
                Icons.spa,
                size: 42,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Clube do Salao',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Assinaturas, agenda e clientes em um unico app.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              Text(
                'Entrar como',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: UserRole.values.map((role) {
                  final selected = selectedRole == role;
                  return ChoiceChip(
                    avatar: Icon(role.icon, size: 18),
                    label: Text(role.label),
                    selected: selected,
                    onSelected: (_) => _selectRole(role),
                  );
                }).toList(),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DashboardShell(role: selectedRole),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continuar'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key, required this.role});

  final UserRole role;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = _pagesFor(widget.role);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.role.label),
        actions: [
          IconButton(
            tooltip: 'Notificacoes',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: pages[currentIndex].child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => setState(() => currentIndex = index),
        destinations: [
          for (final page in pages)
            NavigationDestination(icon: Icon(page.icon), label: page.label),
        ],
      ),
    );
  }

  List<_ShellPage> _pagesFor(UserRole role) {
    return switch (role) {
      UserRole.owner => const [
        _ShellPage('Inicio', Icons.dashboard, OwnerHomePage()),
        _ShellPage('Agenda', Icons.calendar_month, AgendaPage()),
        _ShellPage('Planos', Icons.workspace_premium, PlansPage()),
        _ShellPage('Clientes', Icons.groups, ClientsPage()),
      ],
      UserRole.professional => const [
        _ShellPage('Hoje', Icons.today, ProfessionalHomePage()),
        _ShellPage('Agenda', Icons.calendar_month, AgendaPage()),
        _ShellPage('Perfil', Icons.badge, ProfessionalProfilePage()),
      ],
      UserRole.customer => const [
        _ShellPage('Clube', Icons.workspace_premium, CustomerHomePage()),
        _ShellPage('Agendar', Icons.add_task, BookingPage()),
        _ShellPage('Perfil', Icons.person, CustomerProfilePage()),
      ],
    };
  }
}

class _ShellPage {
  const _ShellPage(this.label, this.icon, this.child);

  final String label;
  final IconData icon;
  final Widget child;
}

class OwnerHomePage extends StatelessWidget {
  const OwnerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _MetricGrid(
          metrics: [
            _Metric('MRR previsto', 'R\$ 2.970', Icons.payments),
            _Metric('Assinantes', '30', Icons.card_membership),
            _Metric('Agenda hoje', '18', Icons.event_available),
            _Metric('Pendentes', '4', Icons.warning_amber),
          ],
        ),
        SizedBox(height: 16),
        _SectionTitle('Proximas acoes'),
        _ActionTile(
          icon: Icons.person_add,
          title: 'Cadastrar cliente',
          subtitle: 'Inclua telefone, observacoes e historico inicial.',
        ),
        _ActionTile(
          icon: Icons.workspace_premium,
          title: 'Criar plano de assinatura',
          subtitle: 'Defina servicos, limites, dias e horarios permitidos.',
        ),
        _ActionTile(
          icon: Icons.price_check,
          title: 'Confirmar pagamento manual',
          subtitle: 'PIX ou dinheiro validado pelo proprietario.',
        ),
      ],
    );
  }
}

class ProfessionalHomePage extends StatelessWidget {
  const ProfessionalHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ScheduleList(
      title: 'Atendimentos de hoje',
      items: [
        _ScheduleItem('09:00', 'Corte masculino', 'Carlos Mendes'),
        _ScheduleItem('10:30', 'Barba completa', 'Joao Ribeiro'),
        _ScheduleItem('14:00', 'Sobrancelha', 'Marina Alves'),
      ],
    );
  }
}

class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _SubscriptionCard(),
        SizedBox(height: 16),
        _SectionTitle('Beneficios'),
        _ActionTile(
          icon: Icons.check_circle,
          title: 'Corte ilimitado',
          subtitle: 'Disponivel de segunda a sexta.',
        ),
        _ActionTile(
          icon: Icons.percent,
          title: '20% em produtos',
          subtitle: 'Desconto aplicado no balcao.',
        ),
      ],
    );
  }
}

class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ScheduleList(
      title: 'Agenda',
      items: [
        _ScheduleItem('09:00', 'Corte masculino', 'Carlos Mendes'),
        _ScheduleItem('10:30', 'Barba completa', 'Joao Ribeiro'),
        _ScheduleItem('14:00', 'Sobrancelha', 'Marina Alves'),
        _ScheduleItem('16:30', 'Coloracao', 'Patricia Lima'),
      ],
    );
  }
}

class PlansPage extends StatelessWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _SectionTitle('Planos ativos'),
        _PlanTile('Bronze', 'R\$ 99,90/mes', '4 usos mensais'),
        _PlanTile('Prata', 'R\$ 149,90/mes', '8 usos mensais'),
        _PlanTile('Black', 'R\$ 199,90/mes', 'Uso ilimitado'),
      ],
    );
  }
}

class ClientsPage extends StatelessWidget {
  const ClientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _SectionTitle('Clientes'),
        _ClientTile('Carlos Mendes', 'Plano Bronze', 'Pagamento pago'),
        _ClientTile('Joao Ribeiro', 'Plano Black', 'Pagamento pendente'),
        _ClientTile('Marina Alves', 'Plano Prata', 'Pagamento pago'),
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
      children: const [
        _SectionTitle('Novo agendamento'),
        _ActionTile(
          icon: Icons.content_cut,
          title: 'Escolher servico',
          subtitle: 'Corte masculino incluso no seu plano.',
        ),
        _ActionTile(
          icon: Icons.badge,
          title: 'Escolher profissional',
          subtitle: 'Veja horarios livres por profissional.',
        ),
        _ActionTile(
          icon: Icons.event,
          title: 'Confirmar horario',
          subtitle: 'Receba confirmacao e lembrete no app.',
        ),
      ],
    );
  }
}

class ProfessionalProfilePage extends StatelessWidget {
  const ProfessionalProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProfileSummary(
      title: 'Perfil profissional',
      rows: [
        _InfoRow('Especialidade', 'Cortes e barba'),
        _InfoRow('Comissao', '40%'),
        _InfoRow('Atendimentos no mes', '86'),
      ],
    );
  }
}

class CustomerProfilePage extends StatelessWidget {
  const CustomerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProfileSummary(
      title: 'Meu perfil',
      rows: [
        _InfoRow('Plano', 'Bronze'),
        _InfoRow('Renovacao', '15/07/2026'),
        _InfoRow('Usos no mes', '2 de 4'),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: metrics.map((metric) => _MetricCard(metric)).toList(),
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.metric);

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(metric.icon, color: Theme.of(context).colorScheme.primary),
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
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}

class _ScheduleList extends StatelessWidget {
  const _ScheduleList({required this.title, required this.items});

  final String title;
  final List<_ScheduleItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle(title),
        for (final item in items)
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(item.time.substring(0, 2))),
              title: Text(item.service),
              subtitle: Text(item.client),
              trailing: Text(item.time),
            ),
          ),
      ],
    );
  }
}

class _ScheduleItem {
  const _ScheduleItem(this.time, this.service, this.client);

  final String time;
  final String service;
  final String client;
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
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
          ],
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile(this.name, this.price, this.limit);

  final String name;
  final String price;
  final String limit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.workspace_premium),
        title: Text(name),
        subtitle: Text(limit),
        trailing: Text(price),
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  const _ClientTile(this.name, this.plan, this.payment);

  final String name;
  final String plan;
  final String payment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person),
        title: Text(name),
        subtitle: Text(plan),
        trailing: Text(payment),
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.title, required this.rows});

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle(title),
        Card(
          child: Column(
            children: [
              for (final row in rows)
                ListTile(title: Text(row.label), trailing: Text(row.value)),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;
}
