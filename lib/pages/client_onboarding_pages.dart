import 'package:clube_do_salao/core/app_exception.dart';
import 'package:clube_do_salao/models/tenant_summary_model.dart';
import 'package:clube_do_salao/pages/onboarding_pages.dart';
import 'package:clube_do_salao/services/auth_session.dart';
import 'package:clube_do_salao/services/onboarding_repository.dart';
import 'package:clube_do_salao/support/business_types.dart';
import 'package:clube_do_salao/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';

/// Primeira tela do fluxo de "Criar conta": o dono e o cliente se cadastram
/// de formas bem diferentes, entao a primeira decisao e sempre "quem e voce".
class ChooseAccountTypePage extends StatelessWidget {
  const ChooseAccountTypePage({
    super.key,
    required this.authSession,
    required this.onboardingRepository,
  });

  final AuthSession authSession;
  final OnboardingRepository onboardingRepository;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Voce e o dono do salao ou um cliente?',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              _AccountTypeCard(
                icon: Icons.storefront,
                title: 'Sou dono de salao',
                subtitle: 'Quero cadastrar meu estabelecimento e gerenciar tudo.',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RegisterOwnerPage(authSession: authSession),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _AccountTypeCard(
                icon: Icons.person,
                title: 'Sou cliente',
                subtitle: 'Quero agendar horario em um salao.',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ClientInviteEntryPage(
                      authSession: authSession,
                      onboardingRepository: onboardingRepository,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  const _AccountTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// Ponto de entrada do cliente: informa o codigo de convite recebido do
/// salao, ou segue sem codigo para escolher o salao no diretorio publico.
///
/// Quando [initialCode] vem preenchido (abertura por deep link/QR), a
/// consulta acontece sozinha assim que a tela abre.
class ClientInviteEntryPage extends StatefulWidget {
  const ClientInviteEntryPage({
    super.key,
    required this.authSession,
    required this.onboardingRepository,
    this.initialCode,
  });

  final AuthSession authSession;
  final OnboardingRepository onboardingRepository;
  final String? initialCode;

  @override
  State<ClientInviteEntryPage> createState() => _ClientInviteEntryPageState();
}

class _ClientInviteEntryPageState extends State<ClientInviteEntryPage> {
  late final _codeController = TextEditingController(text: widget.initialCode);
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _lookup());
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Informe o codigo de convite');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tenant = await widget.onboardingRepository.lookupInviteCode(code);
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InviteConfirmationPage(
            authSession: widget.authSession,
            tenant: tenant,
            inviteCode: code,
          ),
        ),
      );
    } on AppException {
      setState(() {
        _errorMessage =
            'Codigo de convite invalido. Confira com o salao ou escolha um salao na lista.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Cadastro de cliente')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const AppSectionTitle('Voce recebeu um convite?'),
            Text(
              'Se o salao te enviou um link ou um QR code, digite aqui o codigo de convite.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Codigo de convite',
                hintText: 'Ex: AB3XQ9',
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isLoading ? null : _lookup,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continuar'),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TenantDirectoryPage(
                            authSession: widget.authSession,
                            onboardingRepository: widget.onboardingRepository,
                          ),
                        ),
                      ),
                child: const Text('Nao tenho codigo, quero escolher um salao'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirma o salao encontrado pelo codigo de convite antes de seguir para
/// o cadastro, para o cliente ter certeza de que e o salao certo.
class InviteConfirmationPage extends StatelessWidget {
  const InviteConfirmationPage({
    super.key,
    required this.authSession,
    required this.tenant,
    required this.inviteCode,
  });

  final AuthSession authSession;
  final TenantSummaryModel tenant;
  final String inviteCode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      appBar: AppBar(title: const Text('Confirmar convite')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(Icons.storefront, size: 32, color: colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Voce foi convidado por',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                tenant.name,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  businessTypeLabels[tenant.businessType] ?? tenant.businessType,
                  if (tenant.city != null) tenant.city!,
                ].join(' - '),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ClientRegisterPage(
                        authSession: authSession,
                        tenant: tenant,
                        inviteCode: inviteCode,
                      ),
                    ),
                  ),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                  child: const Text('E isso mesmo, continuar cadastro'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Nao e este salao'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Diretorio publico de estabelecimentos, para o cliente que nao recebeu
/// convite de ninguem escolher onde quer se cadastrar.
class TenantDirectoryPage extends StatefulWidget {
  const TenantDirectoryPage({
    super.key,
    required this.authSession,
    required this.onboardingRepository,
  });

  final AuthSession authSession;
  final OnboardingRepository onboardingRepository;

  @override
  State<TenantDirectoryPage> createState() => _TenantDirectoryPageState();
}

class _TenantDirectoryPageState extends State<TenantDirectoryPage> {
  late Future<List<TenantSummaryModel>> _future;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = widget.onboardingRepository.directory();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Escolher salao')),
      body: SafeArea(
        child: FutureBuilder<List<TenantSummaryModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return AppLoadingError(
                message: 'Nao foi possivel carregar os saloes.',
                onRetry: () =>
                    setState(() => _future = widget.onboardingRepository.directory()),
              );
            }

            final tenants = snapshot.data!.where((tenant) {
              if (_query.isEmpty) return true;
              return tenant.name.toLowerCase().contains(_query) ||
                  (tenant.city ?? '').toLowerCase().contains(_query);
            }).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nome ou cidade',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                if (tenants.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Center(child: Text('Nenhum salao encontrado.')),
                  ),
                for (final tenant in tenants)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.storefront),
                      title: Text(tenant.name),
                      subtitle: Text(
                        [
                          businessTypeLabels[tenant.businessType] ??
                              tenant.businessType,
                          if (tenant.city != null) tenant.city!,
                        ].join(' - '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ClientRegisterPage(
                            authSession: widget.authSession,
                            tenant: tenant,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Formulario final do autocadastro do cliente, ja com o salao escolhido
/// (por convite ou diretorio). Ao concluir, o app ja loga o cliente.
class ClientRegisterPage extends StatefulWidget {
  const ClientRegisterPage({
    super.key,
    required this.authSession,
    required this.tenant,
    this.inviteCode,
  });

  final AuthSession authSession;
  final TenantSummaryModel tenant;

  /// Quando nulo, o vinculo e feito por `tenant.id` (veio do diretorio).
  final String? inviteCode;

  @override
  State<ClientRegisterPage> createState() => _ClientRegisterPageState();
}

class _ClientRegisterPageState extends State<ClientRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await widget.authSession.registerClient(
      inviteCode: widget.inviteCode,
      tenantId: widget.inviteCode == null ? widget.tenant.id : null,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (widget.authSession.isAuthenticated) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting =
        widget.authSession.status == AuthStatus.authenticating;

    return AppScaffold(
      appBar: AppBar(title: const Text('Seus dados')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppSectionTitle('Cadastro em ${widget.tenant.name}'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Seu nome'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Telefone/WhatsApp'),
                keyboardType: TextInputType.phone,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Informe o telefone'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Informe o e-mail' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
                validator: (value) => (value == null || value.length < 8)
                    ? 'A senha precisa ter ao menos 8 caracteres'
                    : null,
              ),
              if (widget.authSession.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  widget.authSession.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Criar conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carrossel curto exibido uma unica vez, logo apos o autocadastro do
/// cliente, apontando os 3 destinos principais do app. Pode ser pulado.
class ClientWelcomeCarouselPage extends StatefulWidget {
  const ClientWelcomeCarouselPage({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<ClientWelcomeCarouselPage> createState() =>
      _ClientWelcomeCarouselPageState();
}

class _ClientWelcomeCarouselPageState extends State<ClientWelcomeCarouselPage> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    (
      icon: Icons.add_task,
      title: 'Agende seu horario',
      message: 'Na aba Agendar voce escolhe servico, profissional e horario.',
    ),
    (
      icon: Icons.workspace_premium,
      title: 'Acompanhe seu plano',
      message: 'Na aba Clube voce ve sua assinatura e quantas vezes ja usou.',
    ),
    (
      icon: Icons.receipt_long,
      title: 'Veja seus pagamentos',
      message: 'Na aba Pagamentos voce acompanha o que esta pendente e pago.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onDone,
                child: const Text('Pular'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  for (final slide in _slides)
                    _WelcomeSlide(
                      icon: slide.icon,
                      title: slide.title,
                      message: slide.message,
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primaryContainer,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLast
                      ? widget.onDone
                      : () => _controller.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.ease,
                        ),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                  child: Text(isLast ? 'Comecar' : 'Proximo'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeSlide extends StatelessWidget {
  const _WelcomeSlide({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(icon, size: 40, color: colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
