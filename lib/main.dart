import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:clube_do_salao/core/error_reporter.dart';
import 'package:clube_do_salao/pages/client_onboarding_pages.dart';
import 'package:clube_do_salao/pages/customer_pages.dart';
import 'package:clube_do_salao/pages/owner_pages.dart';
import 'package:clube_do_salao/pages/professional_pages.dart';
import 'package:clube_do_salao/services/appointments_repository.dart';
import 'package:clube_do_salao/services/auth_session.dart';
import 'package:clube_do_salao/services/client_subscriptions_repository.dart';
import 'package:clube_do_salao/services/clients_repository.dart';
import 'package:clube_do_salao/services/onboarding_repository.dart';
import 'package:clube_do_salao/services/payments_repository.dart';
import 'package:clube_do_salao/services/professionals_repository.dart';
import 'package:clube_do_salao/services/saas_subscription_repository.dart';
import 'package:clube_do_salao/services/services_repository.dart';
import 'package:clube_do_salao/services/subscription_plans_repository.dart';
import 'package:clube_do_salao/services/tenant_repository.dart';
import 'package:clube_do_salao/services/waitlist_repository.dart';
import 'package:clube_do_salao/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    AppErrorReporter.configure();

    runApp(const ClubeDoSalaoApp());
  }, AppErrorReporter.reportZoneError);
}

const _logoMarkAsset = 'assets/icon/icon_foreground.png';

/// Contas de demonstracao criadas por `php artisan db:seed` no backend
/// (ver `backend/docs/api.md`). Atalho so para acelerar testes manuais.
const _demoPassword = 'demo12345';

enum UserRole {
  owner('Proprietário', Icons.storefront),
  professional('Profissional', Icons.content_cut),
  customer('Cliente', Icons.person);

  const UserRole(this.label, this.icon);

  final String label;
  final IconData icon;

  factory UserRole.fromApiValue(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.customer,
    );
  }
}

class ClubeDoSalaoApp extends StatefulWidget {
  const ClubeDoSalaoApp({super.key, AuthSession? authSession})
    : _injectedAuthSession = authSession;

  /// Permite injetar uma sessao (com backend e storage falsos) em testes.
  final AuthSession? _injectedAuthSession;

  @override
  State<ClubeDoSalaoApp> createState() => _ClubeDoSalaoAppState();
}

class _ClubeDoSalaoAppState extends State<ClubeDoSalaoApp> {
  late final AuthSession _authSession =
      widget._injectedAuthSession ?? AuthSession();
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _inviteLinkSubscription;

  @override
  void initState() {
    super.initState();
    _authSession.restore();
    _listenForInviteLinks();
  }

  /// Convite por link/QR (`clubedosalao://convite/{codigo}`): quando o app
  /// abre por um desses links e ninguem esta logado, pula direto para a
  /// tela de confirmacao do convite, sem o cliente precisar digitar nada.
  void _listenForInviteLinks() {
    // `app_links` usa platform channels, indisponiveis em testes de widget;
    // ver `_injectedAuthSession` para o mesmo tipo de escape usado em testes.
    if (widget._injectedAuthSession != null) return;

    final appLinks = AppLinks();
    _inviteLinkSubscription = appLinks.uriLinkStream.listen(
      _handleInviteLink,
      onError: (_) {},
    );
    appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleInviteLink(uri);
    });
  }

  void _handleInviteLink(Uri uri) {
    if (uri.scheme != 'clubedosalao') return;
    if (_authSession.status != AuthStatus.unauthenticated) return;

    final code = uri.host == 'convite' && uri.pathSegments.isNotEmpty
        ? uri.pathSegments.first
        : (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'convite'
              ? uri.pathSegments[1]
              : null);

    if (code == null || code.isEmpty) return;

    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ClientInviteEntryPage(
          authSession: _authSession,
          onboardingRepository: OnboardingRepository(_authSession.apiClient),
          initialCode: code,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inviteLinkSubscription?.cancel();
    _authSession.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF176B5B),
      brightness: Brightness.light,
    );

    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Clube do Salão',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFEFF7F1),
        useMaterial3: true,
        fontFamily: 'Manrope',
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      home: ListenableBuilder(
        listenable: _authSession,
        builder: (context, _) {
          return switch (_authSession.status) {
            AuthStatus.unknown => const _SplashPage(),
            AuthStatus.authenticated when _authSession.justRegisteredAsCustomer =>
              ClientWelcomeCarouselPage(onDone: _authSession.acknowledgeWelcome),
            AuthStatus.authenticated => DashboardShell(
              authSession: _authSession,
            ),
            AuthStatus.authenticating ||
            AuthStatus.unauthenticated => LoginPage(authSession: _authSession),
          };
        },
      ),
    );
  }
}

/// Tela exibida enquanto a sessao salva e restaurada. Usa o mesmo fundo em
/// degrade e a mesma logo da tela de login para manter a identidade visual
/// entre a abertura do app e o login.
class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Image.asset(_logoMarkAsset, width: 48, height: 48),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.authSession});

  final AuthSession authSession;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await widget.authSession.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  Future<void> _loginAsDemo(String email) async {
    _emailController.text = email;
    _passwordController.text = _demoPassword;
    await widget.authSession.login(email, _demoPassword);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSubmitting = widget.authSession.status == AuthStatus.authenticating;

    return AppScaffold(
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _DecorativeBlob(
              size: 240,
              color: colorScheme.primary.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -90,
            child: _DecorativeBlob(
              size: 260,
              color: colorScheme.tertiary.withValues(alpha: 0.14),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Card(
                  elevation: 10,
                  shadowColor: colorScheme.primary.withValues(alpha: 0.25),
                  color: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(
                                _logoMarkAsset,
                                width: 40,
                                height: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Clube do Salão',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Assinaturas, agenda e clientes em um único app.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.3,
                                ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              isDense: true,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'Informe o e-mail'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Senha',
                              isDense: true,
                            ),
                            obscureText: true,
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'Informe a senha'
                                : null,
                          ),
                          if (widget.authSession.errorMessage != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              widget.authSession.errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ],
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: isSubmitting ? null : _submit,
                            icon: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.arrow_forward),
                            label: const Text('Entrar'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Acesso rápido (demonstração)',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _DemoLoginButton(
                                  label: 'Gestor',
                                  enabled: !isSubmitting,
                                  onPressed: () =>
                                      _loginAsDemo('owner@clubedosalao.com'),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _DemoLoginButton(
                                  label: 'Profissional',
                                  enabled: !isSubmitting,
                                  onPressed: () => _loginAsDemo(
                                    'ana.souza@clubedosalao.com',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _DemoLoginButton(
                                  label: 'Cliente',
                                  enabled: !isSubmitting,
                                  onPressed: () => _loginAsDemo(
                                    'carlos.mendes@clubedosalao.com',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ChooseAccountTypePage(
                                        authSession: widget.authSession,
                                        onboardingRepository:
                                            OnboardingRepository(
                                              widget.authSession.apiClient,
                                            ),
                                      ),
                                    ),
                                  ),
                            child: const Text('Criar conta'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botao compacto de acesso rapido as contas de demonstracao, dimensionado
/// para os tres caberem lado a lado sem quebrar linha nem exigir rolagem.
class _DemoLoginButton extends StatelessWidget {
  const _DemoLoginButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Forma decorativa suave usada no fundo da tela de login.
class _DecorativeBlob extends StatelessWidget {
  const _DecorativeBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key, required this.authSession});

  final AuthSession authSession;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = widget.authSession.user!;
    final role = UserRole.fromApiValue(user.role);
    final pages = _pagesFor(role);

    if (currentIndex >= pages.length) {
      currentIndex = 0;
    }

    return AppScaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(_logoMarkAsset, width: 22, height: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                role.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: widget.authSession.logout,
            icon: const Icon(Icons.logout),
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
    final apiClient = widget.authSession.apiClient;

    return switch (role) {
      UserRole.owner => [
        _ShellPage(
          'Inicio',
          Icons.dashboard,
          OwnerHomePage(
            clientsRepository: ClientsRepository(apiClient),
            appointmentsRepository: AppointmentsRepository(apiClient),
            paymentsRepository: PaymentsRepository(apiClient),
            plansRepository: SubscriptionPlansRepository(apiClient),
            servicesRepository: ServicesRepository(apiClient),
            professionalsRepository: ProfessionalsRepository(apiClient),
            tenantRepository: TenantRepository(apiClient),
            saasSubscriptionRepository: SaasSubscriptionRepository(apiClient),
            checklistStorage: widget.authSession.checklistStorage,
          ),
        ),
        _ShellPage(
          'Agenda',
          Icons.calendar_month,
          AgendaPage(
            appointmentsRepository: AppointmentsRepository(apiClient),
            waitlistRepository: WaitlistRepository(apiClient),
            professionalsRepository: ProfessionalsRepository(apiClient),
          ),
        ),
        _ShellPage(
          'Catalogo',
          Icons.storefront,
          CatalogPage(
            servicesRepository: ServicesRepository(apiClient),
            professionalsRepository: ProfessionalsRepository(apiClient),
          ),
        ),
        _ShellPage(
          'Planos',
          Icons.workspace_premium,
          PlansPage(
            plansRepository: SubscriptionPlansRepository(apiClient),
            servicesRepository: ServicesRepository(apiClient),
          ),
        ),
        _ShellPage(
          'Clientes',
          Icons.groups,
          ClientsPage(clientsRepository: ClientsRepository(apiClient)),
        ),
      ],
      UserRole.professional => [
        _ShellPage(
          'Hoje',
          Icons.today,
          ProfessionalHomePage(
            appointmentsRepository: AppointmentsRepository(apiClient),
          ),
        ),
        _ShellPage(
          'Agenda',
          Icons.calendar_month,
          AgendaPage(
            appointmentsRepository: AppointmentsRepository(apiClient),
            waitlistRepository: WaitlistRepository(apiClient),
            professionalsRepository: ProfessionalsRepository(apiClient),
          ),
        ),
        _ShellPage(
          'Perfil',
          Icons.badge,
          ProfessionalProfilePage(
            professionalsRepository: ProfessionalsRepository(apiClient),
            appointmentsRepository: AppointmentsRepository(apiClient),
          ),
        ),
      ],
      UserRole.customer => [
        _ShellPage(
          'Clube',
          Icons.workspace_premium,
          CustomerHomePage(
            clientsRepository: ClientsRepository(apiClient),
            plansRepository: SubscriptionPlansRepository(apiClient),
            clientSubscriptionsRepository: ClientSubscriptionsRepository(
              apiClient,
            ),
          ),
        ),
        _ShellPage(
          'Agendar',
          Icons.add_task,
          BookingPage(
            clientsRepository: ClientsRepository(apiClient),
            servicesRepository: ServicesRepository(apiClient),
            professionalsRepository: ProfessionalsRepository(apiClient),
            appointmentsRepository: AppointmentsRepository(apiClient),
            waitlistRepository: WaitlistRepository(apiClient),
          ),
        ),
        _ShellPage(
          'Pagamentos',
          Icons.receipt_long,
          CustomerPaymentsPage(
            paymentsRepository: PaymentsRepository(apiClient),
          ),
        ),
        _ShellPage(
          'Perfil',
          Icons.person,
          CustomerProfilePage(clientsRepository: ClientsRepository(apiClient)),
        ),
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
