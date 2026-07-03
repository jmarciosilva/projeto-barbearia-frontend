import 'package:clube_do_salao/core/app_exception.dart';
import 'package:clube_do_salao/models/app_user.dart';
import 'package:clube_do_salao/services/api_client.dart';
import 'package:clube_do_salao/services/token_storage.dart';
import 'package:flutter/foundation.dart';

enum AuthStatus { unknown, authenticating, authenticated, unauthenticated }

/// Sessao de autenticacao da aplicacao: token, usuario logado e estado da
/// tela de login. Um unico `AuthSession` vive no topo da arvore de widgets
/// (ver `main.dart`) e notifica quem estiver ouvindo quando o estado muda.
class AuthSession extends ChangeNotifier {
  AuthSession({ApiClient? apiClient, TokenStorage? storage})
    : apiClient = apiClient ?? ApiClient(),
      _storage = storage ?? const SecureTokenStorage();

  final ApiClient apiClient;
  final TokenStorage _storage;

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

      final token = response['token'] as String;
      apiClient.updateToken(token);
      await _storage.write(token);

      user = AppUser.fromJson(response['user'] as Map<String, dynamic>);
      status = AuthStatus.authenticated;
    } on AppException catch (error) {
      status = AuthStatus.unauthenticated;
      errorMessage = error.userMessage;
    } finally {
      notifyListeners();
    }
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
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
