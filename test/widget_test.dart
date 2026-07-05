import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  testWidgets('mostra o login e entra no dashboard do proprietario', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    expect(find.text('Clube do Salão'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Gestor'));
    await tester.pumpAndSettle();

    expect(find.text('Proprietário'), findsOneWidget);
    expect(find.text('MRR previsto'), findsOneWidget);
  });

  testWidgets('mostra erro quando as credenciais sao invalidas', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await loginAs(
      tester,
      email: 'nao-existe@example.com',
      password: 'senhaerrada',
    );

    expect(find.text('Credenciais invalidas.'), findsOneWidget);
    expect(find.text('Clube do Salão'), findsOneWidget);
  });

  testWidgets('entra como profissional e ve a propria agenda real', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Profissional'));
    await tester.pumpAndSettle();

    expect(find.text('Profissional'), findsWidgets);
    expect(find.text('Atendimentos de hoje'), findsOneWidget);
    expect(find.text('Corte masculino'), findsOneWidget);
  });

  testWidgets('entra como cliente e ve a propria assinatura real', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cliente'));
    await tester.pumpAndSettle();

    expect(find.text('Cliente'), findsWidgets);
    expect(find.text('Plano Bronze'), findsOneWidget);
  });
}
