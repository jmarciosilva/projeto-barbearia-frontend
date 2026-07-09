import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_backend.dart';
import '../support/pump_app.dart';

void main() {
  testWidgets(
    'proprietario cadastra cliente offline: fica na fila em vez de dar erro',
    (tester) async {
      final offlineToggle = FakeConnectivityToggle();
      final session = await pumpMobileApp(tester, offlineToggle: offlineToggle);

      await loginAs(
        tester,
        email: 'owner@clubedosalao.com',
        password: 'demo12345',
      );

      await tester.tap(find.text('Clientes'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Adicionar cliente'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cadastrar cliente'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Nova Cliente');
      await tester.enterText(find.byType(TextFormField).at(1), '11999990000');

      // Cai offline logo antes de enviar — o resto do fluxo (login, listar
      // clientes, abrir o formulario) ja aconteceu online normalmente.
      offlineToggle.offline = true;

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sem conexão agora'), findsOneWidget);
      expect(session.mutationQueue.pendingCount, 1);
    },
  );
}
