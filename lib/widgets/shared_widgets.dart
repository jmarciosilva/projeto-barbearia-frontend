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
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class AppMetric {
  const AppMetric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
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
  const AppPlanTile(this.name, this.price, this.limit, {super.key});

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
                ListTile(title: Text(row.label), trailing: Text(row.value)),
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
  });

  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onDone;

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
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onDone,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
