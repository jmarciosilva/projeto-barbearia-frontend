import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda, so neste aparelho, o progresso do checklist de configuracao
/// inicial do dono que nao tem como ser calculado a partir da API (ex:
/// "compartilhou o convite" e uma acao, nao um registro no banco) e se o
/// dono ja dispensou o checklist inteiro.
///
/// Escopado por [tenantId]: o mesmo aparelho pode logar em mais de um
/// estabelecimento (ex: dono cria uma segunda conta para testar), e sem o
/// escopo o progresso de um tenant "vazava" para os outros — um tenant novo
/// nascia com o checklist ja dispensado so porque um tenant anterior no
/// mesmo aparelho tinha dispensado o dele.
abstract class OnboardingChecklistStorage {
  Future<bool> hasSharedInvite(int tenantId);
  Future<void> markInviteShared(int tenantId);
  Future<bool> isDismissed(int tenantId);
  Future<void> dismiss(int tenantId);
}

class SecureOnboardingChecklistStorage implements OnboardingChecklistStorage {
  const SecureOnboardingChecklistStorage([
    this._storage = const FlutterSecureStorage(),
  ]);

  static const _sharedInviteKey = 'onboarding_checklist_shared_invite';
  static const _dismissedKey = 'onboarding_checklist_dismissed';

  final FlutterSecureStorage _storage;

  @override
  Future<bool> hasSharedInvite(int tenantId) async =>
      (await _storage.read(key: '${_sharedInviteKey}_$tenantId')) == 'true';

  @override
  Future<void> markInviteShared(int tenantId) => _storage.write(
    key: '${_sharedInviteKey}_$tenantId',
    value: 'true',
  );

  @override
  Future<bool> isDismissed(int tenantId) async =>
      (await _storage.read(key: '${_dismissedKey}_$tenantId')) == 'true';

  @override
  Future<void> dismiss(int tenantId) =>
      _storage.write(key: '${_dismissedKey}_$tenantId', value: 'true');
}
