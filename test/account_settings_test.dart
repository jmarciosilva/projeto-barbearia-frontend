import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  testWidgets('dono altera o proprio e-mail informando a senha atual', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Gestor'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meus dados de acesso'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'demo12345');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'novo-email@example.com',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
    await tester.pumpAndSettle();

    expect(find.text('Dados de acesso atualizados.'), findsOneWidget);
  });

  testWidgets('mostra erro quando a senha atual esta errada', (tester) async {
    await pumpMobileApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Gestor'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meus dados de acesso'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'senhaErrada');

    await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
    await tester.pumpAndSettle();

    expect(find.text('Senha atual incorreta.'), findsOneWidget);
  });

  testWidgets('nova senha e confirmacao precisam coincidir', (tester) async {
    await pumpMobileApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Gestor'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meus dados de acesso'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'demo12345');
    await tester.enterText(find.byType(TextFormField).at(2), 'novaSenhaForte1');
    await tester.enterText(find.byType(TextFormField).at(3), 'outraSenha');

    await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
    await tester.pumpAndSettle();

    expect(find.text('As senhas não coincidem'), findsOneWidget);
  });
}
