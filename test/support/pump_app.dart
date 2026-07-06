import 'package:clube_do_salao/main.dart';
import 'package:clube_do_salao/services/api_client.dart';
import 'package:clube_do_salao/services/auth_session.dart';
import 'package:clube_do_salao/services/onboarding_checklist_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';
import 'fake_onboarding_checklist_storage.dart';
import 'fake_token_storage.dart';

const mobileSize = Size(390, 844);

/// Cria uma sessao de autenticacao apontando para o backend falso, pronta
/// para os testes de widget (sem rede real nem platform channels).
AuthSession buildTestAuthSession({OnboardingChecklistStorage? checklistStorage}) {
  return AuthSession(
    apiClient: ApiClient(httpClient: buildFakeBackend()),
    storage: FakeTokenStorage(),
    checklistStorage: checklistStorage ?? FakeOnboardingChecklistStorage(),
  );
}

/// Sobe o app em viewport mobile, usando o backend falso por padrao.
Future<AuthSession> pumpMobileApp(
  WidgetTester tester, {
  AuthSession? authSession,
}) async {
  tester.view.physicalSize = mobileSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final session = authSession ?? buildTestAuthSession();
  await tester.pumpWidget(ClubeDoSalaoApp(authSession: session));
  await tester.pumpAndSettle();

  return session;
}

/// Preenche o formulario de login e envia, aguardando a navegacao.
Future<void> loginAs(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), password);
  await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
  await tester.pumpAndSettle();
}

/// Rola a `ListView` principal ate um texto ficar visivel e clicavel.
///
/// `ListView(children: ...)` monta os itens sob demanda conforme a posicao
/// de rolagem, entao um item bem abaixo na tela pode nem existir ainda como
/// elemento -- por isso um scroll de distancia fixa (`tester.drag`) quebra
/// sempre que a lista ganha ou perde itens acima do alvo. Rola aos poucos
/// ate o finder aparecer e depois rola um pouco mais, porque o item pode
/// montar bem na borda da tela, ainda coberto pela barra de navegacao fixa
/// no rodape (fisicamente presente por cima do fim do `ListView`).
Future<void> scrollToText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  final scrollable = find
      .descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      )
      .first;

  var attempts = 0;
  while (finder.evaluate().isEmpty && attempts < 20) {
    await tester.drag(scrollable, const Offset(0, -200));
    await tester.pump();
    attempts++;
  }
  await tester.drag(scrollable, const Offset(0, -150));
  await tester.pump();
  await tester.pumpAndSettle();
}

/// Volta o scroll de uma `ListView` para o topo. Util depois de
/// `scrollToText` quando o teste ainda precisa localizar algo perto do
/// inicio da lista (fora do cache do Sliver na posicao rolada).
Future<void> scrollToTop(WidgetTester tester) async {
  final scrollable = find
      .descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      )
      .first;

  for (var i = 0; i < 20; i++) {
    await tester.drag(scrollable, const Offset(0, 400));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}
