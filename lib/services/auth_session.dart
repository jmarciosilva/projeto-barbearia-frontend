import 'package:clube_do_salao/core/app_exception.dart';
import 'package:clube_do_salao/models/app_user.dart';
import 'package:clube_do_salao/services/api_client.dart';
import 'package:clube_do_salao/services/onboarding_checklist_storage.dart';
import 'package:clube_do_salao/services/token_storage.dart';
import 'package:flutter/foundation.dart';

enum AuthStatus { unknown, authenticating, authenticated, unauthenticated }

/// Sessao de autenticacao da aplicacao: token, usuario logado e estado da
/// tela de login. Um unico `AuthSession` vive no topo da arvore de widgets
/// (ver `main.dart`) e notifica quem estiver ouvindo quando o estado muda.
class AuthSession extends ChangeNotifier {
  AuthSession({
    ApiClient? apiClient,
    TokenStorage? storage,
    OnboardingChecklistStorage? checklistStorage,
  }) : apiClient = apiClient ?? ApiClient(),
       _storage = storage ?? const SecureTokenStorage(),
       checklistStorage =
           checklistStorage ?? const SecureOnboardingChecklistStorage();

  final ApiClient apiClient;
  final TokenStorage _storage;

  /// Injetavel pelo mesmo motivo do `TokenStorage`: `flutter_secure_storage`
  /// usa platform channels indisponiveis em testes de widget.
  final OnboardingChecklistStorage checklistStorage;

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;
  String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  /// Tenta restaurar a sessao a partir do token salvo. Chamado uma vez na
  /// abertura do app, antes de decidir entre tela de login ou dashboard.
  Future<void> restore() async {
    final token = await _storage.read();

    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    apiClient.updateToken(token);

    try {
      final response = await apiClient.get('/me') as Map<String, dynamic>;
      user = AppUser.fromJson(response);
      status = AuthStatus.authenticated;
    } catch (_) {
      // Token salvo mas invalido/expirado: descarta e volta para o login.
      await _storage.delete();
      apiClient.updateToken(null);
      status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    // Protege contra chamadas concorrentes (ex: duplo toque muito rapido
    // no botao, antes do rebuild que o desabilita chegar a tempo).
    if (status == AuthStatus.authenticating) return;

    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();

    try {
      final response =
          await apiClient.post(
                '/auth/login',
                body: {'email': email, 'password': password},
              )
              as Map<String, dynamic>;

      await _applyAuthResponse(response);
    } on AppException catch (error) {
      status = AuthStatus.unauthenticated;
      errorMessage = error.userMessage;
    } finally {
      notifyListeners();
    }
  }

  /// Cria estabelecimento + proprietario (`POST /auth/register-owner`) e ja
  /// autentica com o token retornado, mesmo padrao de sessao do login.
  Future<void> registerOwner({
    required String tenantName,
    required String businessType,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
    String? tenantPhone,
  }) async {
    if (status == AuthStatus.authenticating) return;

    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();

    try {
      final response =
          await apiClient.post(
                '/auth/register-owner',
                body: {
                  'tenant': {
                    'name': tenantName,
                    'business_type': businessType,
                    'phone': ?tenantPhone,
                  },
                  'owner': {
                    'name': ownerName,
                    'email': ownerEmail,
                    'password': ownerPassword,
                  },
                },
              )
              as Map<String, dynamic>;

      await _applyAuthResponse(response);
    } on AppException catch (error) {
      status = AuthStatus.unauthenticated;
      errorMessage = error.userMessage;
    } finally {
      notifyListeners();
    }
  }

  /// Autocadastro do cliente (`POST /auth/register-client`), vinculado a um
  /// tenant por `inviteCode` (convite do dono) OU `tenantId` (escolhido no
  /// diretorio publico) — informe exatamente um dos dois. Ja autentica com
  /// o token retornado, mesmo padrao de `registerOwner`.
  Future<void> registerClient({
    String? inviteCode,
    int? tenantId,
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    assert(
      (inviteCode != null) ^ (tenantId != null),
      'Informe inviteCode OU tenantId, nunca os dois nem nenhum.',
    );

    if (status == AuthStatus.authenticating) return;

    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();

    try {
      final response =
          await apiClient.post(
                '/auth/register-client',
                body: {
                  'invite_code': ?inviteCode,
                  'tenant_id': ?tenantId,
                  'client': {
                    'name': name,
                    'email': email,
                    'phone': phone,
                    'password': password,
                  },
                },
              )
              as Map<String, dynamic>;

      await _applyAuthResponse(response);
      justRegisteredAsCustomer = true;
    } on AppException catch (error) {
      status = AuthStatus.unauthenticated;
      errorMessage = error.userMessage;
    } finally {
      notifyListeners();
    }
  }

  /// Liga por uma unica sessao logo apos `registerClient`, para a tela
  /// inicial decidir se mostra o carrossel de boas-vindas do cliente antes
  /// do dashboard normal. Nao e persistido: some ao deslogar ou reabrir o app.
  bool justRegisteredAsCustomer = false;

  void acknowledgeWelcome() {
    justRegisteredAsCustomer = false;
    notifyListeners();
  }

  /// Troca o proprio e-mail e/ou senha (`PATCH /me/credentials`), exigindo a
  /// senha atual. Ao contrario de `login`/`registerOwner`/`registerClient`,
  /// nao mexe em `status`: e uma edicao dentro do app ja autenticado, nao uma
  /// transicao de autenticacao — o switch de login/dashboard em `main.dart`
  /// nao deve reagir a esta chamada. Por isso tambem nao engole erro: quem
  /// chama trata o `AppException` localmente (mesmo padrao das telas de
  /// cadastro de recurso, tipo `NewClientPage`).
  Future<void> updateCredentials({
    required String currentPassword,
    String? email,
    String? password,
    String? passwordConfirmation,
  }) async {
    final response =
        await apiClient.patch(
              '/me/credentials',
              body: {
                'current_password': currentPassword,
                'email': ?email,
                'password': ?password,
                'password_confirmation': ?passwordConfirmation,
              },
            )
            as Map<String, dynamic>;

    user = AppUser.fromJson(response);
    notifyListeners();
  }

  Future<void> _applyAuthResponse(Map<String, dynamic> response) async {
    final token = response['token'] as String;
    apiClient.updateToken(token);
    await _storage.write(token);

    user = AppUser.fromJson(response['user'] as Map<String, dynamic>);
    status = AuthStatus.authenticated;
  }

  bool _isLoggingOut = false;

  Future<void> logout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    try {
      await apiClient.post('/auth/logout');
    } catch (_) {
      // Mesmo se a chamada de logout falhar (ex: sem rede), a sessao local
      // e limpa do mesmo jeito para nao deixar o usuario preso.
    } finally {
      _isLoggingOut = false;
    }

    await _storage.delete();
    apiClient.updateToken(null);
    user = null;
    justRegisteredAsCustomer = false;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
