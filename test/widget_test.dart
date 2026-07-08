import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  testWidgets('mostra o login e entra no dashboard do proprietario', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    expect(find.text('Clube do Salão'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);

    await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

    expect(find.text('Proprietário'), findsOneWidget);
    expect(find.text('Recorrente do mês'), findsOneWidget);
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

    await loginAs(tester, email: 'ana.souza@clubedosalao.com', password: 'demo12345');

    expect(find.text('Profissional'), findsWidgets);
    expect(find.text('Este mês'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('R\$ 360,00'), findsOneWidget);
    expect(find.text('Atendimentos de hoje'), findsOneWidget);
    expect(find.text('Corte masculino'), findsOneWidget);
  });

  testWidgets('entra como cliente e ve a propria assinatura real', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'carlos.mendes@clubedosalao.com', password: 'demo12345');

    expect(find.text('Cliente'), findsWidgets);
    expect(find.text('Plano Bronze'), findsOneWidget);
  });
}
