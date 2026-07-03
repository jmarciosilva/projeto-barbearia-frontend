import 'package:clube_do_salao/main.dart';
import 'package:clube_do_salao/services/api_client.dart';
import 'package:clube_do_salao/services/auth_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';
import 'fake_token_storage.dart';

const mobileSize = Size(390, 844);

/// Cria uma sessao de autenticacao apontando para o backend falso, pronta
/// para os testes de widget (sem rede real nem platform channels).
AuthSession buildTestAuthSession() {
  return AuthSession(
    apiClient: ApiClient(httpClient: buildFakeBackend()),
    storage: FakeTokenStorage(),
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
