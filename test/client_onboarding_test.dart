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

    await tester.tap(find.text('É isso mesmo, continuar cadastro'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Maria Cliente');
    await tester.enterText(find.byType(TextFormField).at(1), '11955554444');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'maria@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(3), 'senhaforte1');
    await tester.enterText(find.byType(TextFormField).at(4), 'senhaforte1');

    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pumpAndSettle();

    // Carrossel de boas-vindas aparece uma unica vez apos o autocadastro.
    expect(find.text('Agende seu horário'), findsOneWidget);
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
      find.textContaining('Código de convite inválido'),
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

    await tester.tap(find.text('Não tenho código, quero escolher um salão'));
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
    await tester.enterText(find.byType(TextFormField).at(4), 'senhaforte1');

    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('Agende seu horário'), findsOneWidget);
  });

  testWidgets(
    'checklist de configuracao aparece para o dono e some ao dispensar',
    (tester) async {
      final checklistStorage = FakeOnboardingChecklistStorage(
        dismissed: false,
      );
      final session = buildTestAuthSession(checklistStorage: checklistStorage);
      await pumpMobileApp(tester, authSession: session);

      await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

      expect(find.text('Vamos configurar seu salão'), findsOneWidget);
      expect(
        find.text('Compartilhe o convite com seus clientes'),
        findsOneWidget,
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Vamos configurar seu salão'), findsNothing);
      expect(await checklistStorage.isDismissed(1), isTrue);
    },
  );

  testWidgets(
    'checklist do dono inclui criar plano de assinatura',
    (tester) async {
      final checklistStorage = FakeOnboardingChecklistStorage(
        dismissed: false,
      );
      final session = buildTestAuthSession(checklistStorage: checklistStorage);
      await pumpMobileApp(tester, authSession: session);

      await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

      expect(
        find.text(
          'Crie um plano de assinatura com os serviços e profissionais',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('dono abre a central de ajuda pelo icone da barra superior', (
    tester,
  ) async {
    final session = buildTestAuthSession();
    await pumpMobileApp(tester, authSession: session);

    await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

    await tester.tap(find.byTooltip('Ajuda'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Central de ajuda'), findsOneWidget);
    expect(
      find.text(
        'Crie um plano de assinatura em "Criar plano de assinatura", escolhendo os serviços e profissionais liberados para quem assinar.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('dono ve o codigo de convite e consegue regenerar', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

    await scrollToText(tester, 'Convidar clientes');
    await tester.tap(find.text('Convidar clientes'));
    await tester.pumpAndSettle();

    expect(find.text('Código: AB3XQ9'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Gerar novo código'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Gerar novo código'));
    await tester.pumpAndSettle();

    expect(find.text('Código: ZZ9YY8'), findsOneWidget);
  });
}
