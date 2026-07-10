import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:clube_do_salao/core/error_reporter.dart';
import 'package:clube_do_salao/pages/admin_pages.dart';
import 'package:clube_do_salao/pages/client_onboarding_pages.dart';
import 'package:clube_do_salao/pages/customer_pages.dart';
import 'package:clube_do_salao/pages/help_center_page.dart';
import 'package:clube_do_salao/pages/owner_pages.dart';
import 'package:clube_do_salao/pages/pending_sync_page.dart';
import 'package:clube_do_salao/pages/professional_pages.dart';
import 'package:clube_do_salao/services/admin_repository.dart';
import 'package:clube_do_salao/services/appointments_repository.dart';
import 'package:clube_do_salao/services/auth_session.dart';
import 'package:clube_do_salao/services/client_subscriptions_repository.dart';
import 'package:clube_do_salao/services/clients_repository.dart';
import 'package:clube_do_salao/services/dashboard_repository.dart';
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
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    AppErrorReporter.configure();

    runApp(const ClubeDoSalaoApp());
  }, AppErrorReporter.reportZoneError);
}

const _logoMarkAsset = 'assets/icon/icon_foreground.png';

enum UserRole {
  owner('Proprietário', Icons.storefront),
  professional('Profissional', Icons.content_cut),
  customer('Cliente', Icons.person),
  admin('Administrador', Icons.admin_panel_settings);

  const UserRole(this.label, this.icon);

  final String label;
  final IconData icon;

  factory UserRole.fromApiValue(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.customer,
    );
  }

  HelpAudience get helpAudience => switch (this) {
    UserRole.owner => HelpAudience.owner,
    UserRole.professional => HelpAudience.professional,
    UserRole.customer => HelpAudience.customer,
    // Administrador da plataforma nao tem roteiro proprio (publico de 2
    // pessoas nao justifica conteudo novo) — reaproveita o do dono.
    UserRole.admin => HelpAudience.owner,
  };
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
    // Paleta extraida da nova logo (mais vida/cor, pedido explicito de donos
    // de salao que acharam a versao anterior "muito verde" numa demo): teal
    // como base (Material deriva toda a tonalidade a partir dela), rosa e
    // laranja vibrantes como acentos pontuais (secondary/tertiary). O
    // degrade completo da logo fica só como imagem estatica (icone, tela de
    // login) — reproduzi-lo inteiro em cada botao/card brigaria com o
    // Material Design e poluiria telas de lista ja carregadas de informacao.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00A8A8),
      brightness: Brightness.light,
    ).copyWith(
      secondary: const Color(0xFFFC3C6C),
      tertiary: const Color(0xFFFC9C30),
    );

    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Clube do Salão',
      // Sem isso, widgets nativos do Material que dependem de localizacao
      // (ex: CalendarDatePicker da Agenda) caem no ingles por padrao.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        fontFamily: 'Manrope',
        // Barra escura solida em vez de branca/transparente, em todo AppBar
        // do app (nenhuma das ~40 telas que usam `AppBar(title: ...)` define
        // cor propria, entao esse unico ponto resolve todas de uma vez) —
        // direcao aprovada pelo usuario num mockup comparando "hoje" vs
        // "proposta" antes de codar.
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF180F2B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        // Mesmo navy da AppBar em todo botao de acao preenchido e em todo
        // FAB do app (hoje ~15 telas, de "Cadastrar cliente" a "Entrar" no
        // login) — antes cada um caia no teal padrao do Material por
        // ausencia de tema proprio, o que destoava da nova reformulacao
        // (feedback do usuario apos ver o app: "o verde ficou fora do tom").
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF180F2B),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF180F2B),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          // Neutro claro (nao mais o creme/bege antigo, que destoava do resto
          // do app — navy no topo, branco no fundo, acentos vibrantes nos
          // cards de acao) em vez de espalhar cor em todo card igual antes;
          // cor fica reservada pros cards de destaque
          // (`AppHeroMetric`/`AppAlertMetric`) ou acentuados
          // (`AppActionTile`/`_MetricCard` com `accentColor`).
          // `surfaceTintColor: transparent` evita o Material 3 tingir esse
          // neutro com a cor primaria em elevacoes maiores.
          elevation: 2,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          margin: EdgeInsets.zero,
          color: const Color(0xFFF7F6F9),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        // Mesma cor escura solida da AppBar (nao a clara padrao do Material),
        // senao a barra de navegacao vira um "segundo app" visualmente
        // desconectado da barra de cima — feedback real do usuario vendo o
        // app no aparelho.
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF180F2B),
          indicatorColor: Colors.white.withValues(alpha: 0.16),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.7),
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.7),
            ),
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
            const SizedBox(height: 16),
            Text(
              'Clube do Salão',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
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
  bool _obscurePassword = true;

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
              color: const Color(0xFF180F2B).withValues(alpha: 0.08),
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
                  shadowColor: const Color(
                    0xFF180F2B,
                  ).withValues(alpha: 0.20),
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
                                color: const Color(
                                  0xFF180F2B,
                                ).withValues(alpha: 0.08),
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
                            style: Theme.of(context).textTheme.bodyLarge
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
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              isDense: true,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            obscureText: _obscurePassword,
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

/// Primeiro nome do usuario logado, para personalizar a AppBar ao lado do
/// papel (ex: "Cliente • Carlos").
String _firstName(String fullName) =>
    fullName.trim().split(RegExp(r'\s+')).first;

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
            Expanded(
              child: user.tenantName == null
                  // Administrador da plataforma nao pertence a nenhum
                  // salao — mantem a linha unica de antes.
                  ? Text(
                      '${role.label} • ${_firstName(user.name)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.tenantName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${role.label} • ${_firstName(user.name)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
        actions: [
          ListenableBuilder(
            listenable: widget.authSession.mutationQueue,
            builder: (context, _) {
              final queue = widget.authSession.mutationQueue;
              final icon = queue.isOnline
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined;

              return IconButton(
                tooltip: 'Sincronização',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PendingSyncPage(mutationQueue: queue),
                  ),
                ),
                icon: queue.pendingCount > 0
                    ? Badge(
                        label: Text('${queue.pendingCount}'),
                        child: Icon(icon),
                      )
                    : Icon(icon),
              );
            },
          ),
          IconButton(
            tooltip: 'Ajuda',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HelpCenterPage(audience: role.helpAudience),
              ),
            ),
            icon: const Icon(Icons.help_outline),
          ),
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
            authSession: widget.authSession,
            dashboardRepository: DashboardRepository(apiClient),
            waitlistRepository: WaitlistRepository(apiClient),
          ),
        ),
        _ShellPage(
          'Agenda',
          Icons.calendar_month,
          AgendaPage(
            appointmentsRepository: AppointmentsRepository(apiClient),
            paymentsRepository: PaymentsRepository(apiClient),
            waitlistRepository: WaitlistRepository(apiClient),
            professionalsRepository: ProfessionalsRepository(apiClient),
            clientsRepository: ClientsRepository(apiClient),
            servicesRepository: ServicesRepository(apiClient),
            tenantRepository: TenantRepository(apiClient),
          ),
        ),
        _ShellPage(
          'Catalogo',
          Icons.storefront,
          CatalogPage(
            servicesRepository: ServicesRepository(apiClient),
            professionalsRepository: ProfessionalsRepository(apiClient),
            authSession: widget.authSession,
          ),
        ),
        _ShellPage(
          'Planos',
          Icons.workspace_premium,
          PlansPage(
            plansRepository: SubscriptionPlansRepository(apiClient),
            servicesRepository: ServicesRepository(apiClient),
            professionalsRepository: ProfessionalsRepository(apiClient),
          ),
        ),
        _ShellPage(
          'Clientes',
          Icons.groups,
          ClientsPage(
            clientsRepository: ClientsRepository(apiClient),
            paymentsRepository: PaymentsRepository(apiClient),
            tenantRepository: TenantRepository(apiClient),
            checklistStorage: widget.authSession.checklistStorage,
          ),
        ),
      ],
      UserRole.professional => [
        _ShellPage(
          'Hoje',
          Icons.today,
          ProfessionalHomePage(
            appointmentsRepository: AppointmentsRepository(apiClient),
            professionalsRepository: ProfessionalsRepository(apiClient),
            paymentsRepository: PaymentsRepository(apiClient),
          ),
        ),
        _ShellPage(
          'Agenda',
          Icons.calendar_month,
          AgendaPage(
            appointmentsRepository: AppointmentsRepository(apiClient),
            paymentsRepository: PaymentsRepository(apiClient),
            waitlistRepository: WaitlistRepository(apiClient),
            professionalsRepository: ProfessionalsRepository(apiClient),
            clientsRepository: ClientsRepository(apiClient),
            servicesRepository: ServicesRepository(apiClient),
            tenantRepository: TenantRepository(apiClient),
          ),
        ),
        _ShellPage(
          'Perfil',
          Icons.badge,
          ProfessionalProfilePage(
            professionalsRepository: ProfessionalsRepository(apiClient),
            appointmentsRepository: AppointmentsRepository(apiClient),
            authSession: widget.authSession,
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
            paymentsRepository: PaymentsRepository(apiClient),
            waitlistRepository: WaitlistRepository(apiClient),
            tenantRepository: TenantRepository(apiClient),
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
          CustomerProfilePage(
            clientsRepository: ClientsRepository(apiClient),
            authSession: widget.authSession,
          ),
        ),
      ],
      UserRole.admin => [
        _ShellPage(
          'Inicio',
          Icons.dashboard,
          AdminHomePage(adminRepository: AdminRepository(apiClient)),
        ),
        _ShellPage(
          'Saloes',
          Icons.storefront,
          AdminTenantsPage(adminRepository: AdminRepository(apiClient)),
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
