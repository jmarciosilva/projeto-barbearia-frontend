import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda, so neste aparelho, o progresso do checklist de configuracao
/// inicial do dono que nao tem como ser calculado a partir da API (ex:
/// "compartilhou o convite" e uma acao, nao um registro no banco) e se o
/// dono ja dispensou o checklist inteiro.
abstract class OnboardingChecklistStorage {
  Future<bool> hasSharedInvite();
  Future<void> markInviteShared();
  Future<bool> isDismissed();
  Future<void> dismiss();
}

class SecureOnboardingChecklistStorage implements OnboardingChecklistStorage {
  const SecureOnboardingChecklistStorage([
    this._storage = const FlutterSecureStorage(),
  ]);

  static const _sharedInviteKey = 'onboarding_checklist_shared_invite';
  static const _dismissedKey = 'onboarding_checklist_dismissed';

  final FlutterSecureStorage _storage;

  @override
  Future<bool> hasSharedInvite() async =>
      (await _storage.read(key: _sharedInviteKey)) == 'true';

  @override
  Future<void> markInviteShared() =>
      _storage.write(key: _sharedInviteKey, value: 'true');

  @override
  Future<bool> isDismissed() async =>
      (await _storage.read(key: _dismissedKey)) == 'true';

  @override
  Future<void> dismiss() => _storage.write(key: _dismissedKey, value: 'true');
}
