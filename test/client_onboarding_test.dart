import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_onboarding_checklist_storage.dart';
import 'support/pump_app.dart';

void main() {
  testWidgets('cliente se autocadastra por codigo de convite valido', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sou cliente'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'AB3XQ9');
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Clube do Salao Demo'), findsOneWidget);

    await tester.tap(find.text('E isso mesmo, continuar cadastro'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Maria Cliente');
    await tester.enterText(find.byType(TextFormField).at(1), '11955554444');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'maria@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(3), 'senhaforte1');

    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pumpAndSettle();

    // Carrossel de boas-vindas aparece uma unica vez apos o autocadastro.
    expect(find.text('Agende seu horario'), findsOneWidget);
    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();

    expect(find.text('Cliente'), findsOneWidget);
  });

  testWidgets('codigo de convite invalido mostra erro sem travar a tela', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sou cliente'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ZZZZZZ');
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Codigo de convite invalido'),
      findsOneWidget,
    );
  });

  testWidgets('cliente sem convite escolhe o salao no diretorio publico', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sou cliente'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nao tenho codigo, quero escolher um salao'));
    await tester.pumpAndSettle();

    expect(find.text('Barbearia do Ze'), findsOneWidget);

    await tester.tap(find.text('Clube do Salao Demo'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Joao Avulso');
    await tester.enterText(find.byType(TextFormField).at(1), '11933332222');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'joao@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(3), 'senhaforte1');

    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('Agende seu horario'), findsOneWidget);
  });

  testWidgets(
    'checklist de configuracao aparece para o dono e some ao dispensar',
    (tester) async {
      final checklistStorage = FakeOnboardingChecklistStorage(
        dismissed: false,
      );
      final session = buildTestAuthSession(checklistStorage: checklistStorage);
      await pumpMobileApp(tester, authSession: session);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Gestor'));
      await tester.pumpAndSettle();

      expect(find.text('Vamos configurar seu salao'), findsOneWidget);
      expect(
        find.text('Compartilhe o convite com seus clientes'),
        findsOneWidget,
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Vamos configurar seu salao'), findsNothing);
      expect(await checklistStorage.isDismissed(), isTrue);
    },
  );

  testWidgets('dono ve o codigo de convite e consegue regenerar', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Gestor'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Convidar clientes'));
    await tester.pumpAndSettle();

    expect(find.text('Codigo: AB3XQ9'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Gerar novo codigo'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Gerar novo codigo'));
    await tester.pumpAndSettle();

    expect(find.text('Codigo: ZZ9YY8'), findsOneWidget);
  });
}
