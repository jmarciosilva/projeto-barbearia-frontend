import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  testWidgets('proprietario cadastra cliente pela API', (tester) async {
    await pumpMobileApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Gestor'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cadastrar cliente'));
    await tester.pumpAndSettle();

    expect(find.text('Cadastrar cliente'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Souza');
    await tester.enterText(find.byType(TextFormField).at(1), '11999990000');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Cliente Ana Souza cadastrado.'), findsOneWidget);
    expect(find.text('Proximas acoes'), findsOneWidget);
  });

  testWidgets('proprietario confirma um pagamento pendente pela API', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Gestor'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirmar pagamento manual'));
    await tester.pumpAndSettle();

    expect(find.text('Joao Ribeiro'), findsOneWidget);

    await tester.tap(find.text('Joao Ribeiro'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar pagamento'));
    await tester.pumpAndSettle();

    expect(find.text('Pagamento confirmado'), findsOneWidget);

    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum pagamento pendente.'), findsOneWidget);
  });

  testWidgets('profissional conclui atendimento a partir da agenda (mock)', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Profissional'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Corte masculino'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhe do atendimento'), findsOneWidget);

    await tester.tap(find.text('Concluir atendimento'));
    await tester.pumpAndSettle();

    expect(find.text('Atendimento concluido'), findsOneWidget);

    await tester.tap(find.text('Voltar para a agenda'));
    await tester.pumpAndSettle();

    expect(find.text('Atendimentos de hoje'), findsOneWidget);
  });

  testWidgets('cliente percorre o fluxo completo de agendamento (mock)', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cliente'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agendar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Iniciar agendamento'));
    await tester.pumpAndSettle();
    expect(find.text('Escolher servico'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Escolher profissional'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar horario'), findsOneWidget);

    await tester.tap(find.text('Confirmar agendamento'));
    await tester.pumpAndSettle();

    expect(find.text('Agendamento confirmado'), findsWidgets);

    await tester.tap(find.text('Voltar ao inicio'));
    await tester.pumpAndSettle();

    expect(find.text('Novo agendamento'), findsOneWidget);
  });
}
