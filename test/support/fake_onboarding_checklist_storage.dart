import 'package:clube_do_salao/services/onboarding_checklist_storage.dart';

/// Checklist em memoria, usado no lugar do `flutter_secure_storage` (que
/// depende de platform channels) nos testes.
///
/// Por padrao comeca dispensado: a maioria dos testes de fluxo/golden nao
/// tem relacao com o checklist de onboarding e presume um dono ja
/// estabelecido (sem o card extra empurrando o resto da tela). Os testes
/// dedicados ao checklist usam `FakeOnboardingChecklistStorage(dismissed: false)`.
class FakeOnboardingChecklistStorage implements OnboardingChecklistStorage {
  FakeOnboardingChecklistStorage({
    bool sharedInvite = false,
    bool dismissed = true,
  }) : _sharedInvite = sharedInvite,
       _dismissed = dismissed;

  bool _sharedInvite;
  bool _dismissed;

  @override
  Future<bool> hasSharedInvite(int tenantId) async => _sharedInvite;

  @override
  Future<void> markInviteShared(int tenantId) async => _sharedInvite = true;

  @override
  Future<bool> isDismissed(int tenantId) async => _dismissed;

  @override
  Future<void> dismiss(int tenantId) async => _dismissed = true;
}
