import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  testWidgets(
    'administrador faz login e ve o dashboard da plataforma, sem abas de salao',
    (tester) async {
      await pumpMobileApp(tester);

      await loginAs(
        tester,
        email: 'admin@clubedosalao.com',
        password: 'demo12345',
      );

      expect(find.text('Administrador • Jose'), findsOneWidget);
      expect(find.text('Agenda'), findsNothing);
      expect(find.text('Clientes'), findsNothing);

      expect(find.text('Saloes'), findsWidgets);
      expect(find.text('Fundadores'), findsOneWidget);
      expect(find.text('Numeros'), findsOneWidget);
      expect(find.text('Usuarios cadastrados'), findsOneWidget);
    },
  );

  testWidgets(
    'administrador lista saloes, alterna selo de fundador e concede assinatura gratuita',
    (tester) async {
      await pumpMobileApp(tester);

      await loginAs(
        tester,
        email: 'admin@clubedosalao.com',
        password: 'demo12345',
      );

      await tester.tap(find.widgetWithText(NavigationDestination, 'Saloes'));
      await tester.pumpAndSettle();

      expect(find.text('Clube do Salao Demo'), findsOneWidget);
      expect(find.text('Barbearia do Ze'), findsOneWidget);
      expect(find.text('Em trial - Trial - Fundador'), findsOneWidget);

      await tester.tap(find.text('Barbearia do Ze'));
      await tester.pumpAndSettle();

      final founderSwitch = find.byType(SwitchListTile);
      expect(tester.widget<SwitchListTile>(founderSwitch).value, isTrue);

      await tester.tap(founderSwitch);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(founderSwitch).value, isFalse);

      await tester.tap(
        find.widgetWithText(FilledButton, 'Conceder gratuitamente'),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Assinatura estendida ate 09/07/2027.'),
        findsOneWidget,
      );
      expect(find.text('R\$ 0,00'), findsWidgets);
    },
  );

  testWidgets('dono de salao fundador ve o selo e nao ve o aviso de trial', (
    tester,
  ) async {
    await pumpMobileApp(tester, founderTenant: true, trialTenant: true);

    await loginAs(
      tester,
      email: 'owner@clubedosalao.com',
      password: 'demo12345',
    );

    expect(find.text('Salão Fundador do Clube do Salão'), findsOneWidget);
    expect(find.textContaining('Faltam'), findsNothing);
  });

  testWidgets(
    'dono de salao nao fundador continua vendo o aviso de trial',
    (tester) async {
      await pumpMobileApp(tester, trialTenant: true);

      await loginAs(
        tester,
        email: 'owner@clubedosalao.com',
        password: 'demo12345',
      );

      expect(find.text('Salão Fundador do Clube do Salão'), findsNothing);
      expect(find.textContaining('Faltam'), findsOneWidget);
    },
  );
}
